#!/usr/bin/env python3
"""Decrypt Sniper 3D (com.fungames.sniper3d) savegame files (.bin, magic FSD1).

Format (from static REA of Sniper 3D 7.17.1, Unity 6 / IL2CPP):
  [0..3]   magic "FSD1" (TFG.Core.SaveDocument.BinaryTag)
  [4..7]   uint32 LE = CRC32(payload) XOR keyInt
           keyInt = BitConverter.ToUInt32(key, 0) (0 when no key)
  [8]      version byte: 1 = RC4-encrypted payload, 0 = plaintext
  [9..]     payload = SaveDocument binary serialization, optionally RC4-encrypted
           (standard RC4, key = 16-byte save key; CRC32 is the zlib variant,
           computed over the ENCRYPTED payload bytes)

SaveDocument payload:
  int32 Version, then root SaveObject:
    int32 count, then per entry:
      BinaryReader.ReadString key (7-bit length-prefixed UTF-8)
      byte SaveValueType (0 Invalid, 1 Object, 2 Array, 3 String, 4 Number, 5 Bool)
      value: Object -> recursive SaveObject
             Array  -> int32 count, then per element (byte type + value)
             String -> ReadString
             Number -> double (8 bytes LE)
             Bool   -> 1 byte (0/1)

Key derivation (TFG.Core.App):
  key = Guid(userId).ToByteArray() XOR DefaultSaveGameKey (16-byte mask),
  byte by byte; when userId is empty the key is the mask itself.
  The mask is a hardcoded constant in the APK (App.DefaultSaveGameKey) and is
  deliberately NOT embedded in this public script: pass it with --mask, or pass
  the already-derived 16-byte key with --key.

Usage:
  python3 sniper3d_decrypt.py savegame.bin --userid 11111111-2222-3333-4444-555555555555 --mask <32 hex>
  python3 sniper3d_decrypt.py savegame.bin --key <32 hex>
  python3 sniper3d_decrypt.py savegame.bin --key <32 hex> -o out.json
  python3 sniper3d_decrypt.py savegame.bin --key <32 hex> --encrypt-back out.bin
      (re-encrypt a parsed JSON back to a .bin with the same key; the header
       CRC is recomputed)
"""
import argparse
import binascii
import json
import struct
import sys
import uuid


# ---------------------------------------------------------------- RC4 (standard)
def rc4(key, data):
    S = list(range(256))
    j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) & 0xFF
        S[i], S[j] = S[j], S[i]
    out = bytearray()
    i = j = 0
    for b in data:
        i = (i + 1) & 0xFF
        j = (j + S[i]) & 0xFF
        S[i], S[j] = S[j], S[i]
        out.append(b ^ S[(S[i] + S[j]) & 0xFF])
    return bytes(out)


def derive_key(userid, mask):
    """key[i] = guid[i] XOR mask[min(i, len(mask)-1)] (SaveGameKeyFromUserId)."""
    guid = uuid.UUID(userid).bytes  # Guid.ToByteArray(): 16 bytes
    return bytes(guid[i] ^ mask[min(i, len(mask) - 1)] for i in range(16))


# ------------------------------------------------------- BinaryReader helpers
class Reader:
    def __init__(self, data):
        self.d = data
        self.p = 0

    def byte(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def i32(self):
        v, = struct.unpack_from('<i', self.d, self.p)
        self.p += 4
        return v

    def f64(self):
        v, = struct.unpack_from('<d', self.d, self.p)
        self.p += 8
        return v

    def string(self):
        # .NET BinaryReader.ReadString: 7-bit encoded length + UTF-8 bytes
        n = 0
        shift = 0
        while True:
            b = self.byte()
            n |= (b & 0x7F) << shift
            if not (b & 0x80):
                break
            shift += 7
        s = self.d[self.p:self.p + n]
        self.p += n
        return s.decode('utf-8', 'replace')


class Writer:
    def __init__(self):
        self.b = bytearray()

    def byte(self, v):
        self.b.append(v & 0xFF)

    def i32(self, v):
        self.b += struct.pack('<i', v)

    def f64(self, v):
        self.b += struct.pack('<d', v)

    def string(self, s):
        raw = s.encode('utf-8')
        n = len(raw)
        while True:
            b = n & 0x7F
            n >>= 7
            if n:
                self.b.append(b | 0x80)
            else:
                self.b.append(b)
                break
        self.b += raw


# SaveValueType: 0 Invalid, 1 Object, 2 Array, 3 String, 4 Number, 5 Bool
def parse_value(r):
    t = r.byte()
    if t == 1:      # Object
        return {'$type': 'Object', 'value': parse_object(r)}
    if t == 2:      # Array
        n = r.i32()
        return {'$type': 'Array', 'value': [parse_value(r) for _ in range(n)]}
    if t == 3:      # String
        return {'$type': 'String', 'value': r.string()}
    if t == 4:      # Number (double)
        return {'$type': 'Number', 'value': r.f64()}
    if t == 5:      # Bool
        return {'$type': 'Bool', 'value': bool(r.byte() & 1)}
    raise ValueError(f'unknown SaveValueType {t} at offset {r.p - 1}')


def parse_object(r):
    n = r.i32()
    obj = {}
    for _ in range(n):
        k = r.string()
        obj[k] = parse_value(r)
    return obj


def parse_document(payload):
    r = Reader(payload)
    version = r.i32()
    root = parse_object(r)
    if r.p != len(payload):
        raise ValueError(f'trailing {len(payload) - r.p} bytes after root object')
    return {'Version': version, 'root': root}


def write_value(w, v):
    t = v['$type']
    if t == 'Object':
        w.byte(1)
        write_object(w, v['value'])
    elif t == 'Array':
        w.byte(2)
        w.i32(len(v['value']))
        for e in v['value']:
            write_value(w, e)
    elif t == 'String':
        w.byte(3)
        w.string(v['value'])
    elif t == 'Number':
        w.byte(4)
        w.f64(float(v['value']))
    elif t == 'Bool':
        w.byte(5)
        w.byte(1 if v['value'] else 0)
    else:
        raise ValueError(f'unknown $type {t}')


def write_object(w, obj):
    w.i32(len(obj))
    for k, v in obj.items():
        w.string(k)
        write_value(w, v)


def build_document(doc):
    w = Writer()
    w.i32(int(doc['Version']))
    write_object(w, doc['root'])
    return bytes(w.b)


def decrypt_file(raw, key):
    if raw[0:4] != b'FSD1':
        raise ValueError('bad magic (not FSD1)')
    stored, = struct.unpack_from('<I', raw, 4)
    version = raw[8]
    payload = raw[9:]
    key_int = struct.unpack_from('<I', key, 0)[0] if key else 0
    crc = binascii.crc32(payload) & 0xFFFFFFFF
    if (stored ^ key_int) != crc:
        raise ValueError(
            f'CRC check failed: stored={stored:#010x} keyInt={key_int:#010x} '
            f'crc32(payload)={crc:#010x} -> stored^keyInt={stored ^ key_int:#010x}; '
            'wrong key (this file most likely uses a per-user key)')
    if version == 1:
        if not key:
            raise ValueError('version 1 (encrypted) but no key supplied')
        payload = rc4(key, payload)
    elif version != 0:
        raise ValueError(f'unsupported version byte {version}')
    return parse_document(payload), version


def encrypt_file(doc, key, version=1):
    payload = build_document(doc)
    if version == 1:
        payload = rc4(key, payload)
    key_int = struct.unpack_from('<I', key, 0)[0] if key else 0
    stored = (binascii.crc32(payload) & 0xFFFFFFFF) ^ key_int
    return b'FSD1' + struct.pack('<I', stored) + bytes([version]) + payload


def main():
    ap = argparse.ArgumentParser(description='Decrypt Sniper 3D savegame (.bin, FSD1)')
    ap.add_argument('input', help='savegame .bin file')
    ap.add_argument('--key', help='16-byte save key as 32 hex chars')
    ap.add_argument('--userid', help='player userId Guid, e.g. 11111111-2222-3333-4444-555555555555')
    ap.add_argument('--mask', help='16-byte DefaultSaveGameKey mask as 32 hex chars (needed with --userid)')
    ap.add_argument('-o', '--output', help='write decrypted JSON here (default: stdout)')
    ap.add_argument('--encrypt-back', metavar='OUT', help='re-encrypt parsed JSON back to a .bin (round-trip check)')
    args = ap.parse_args()

    key = None
    if args.key:
        key = bytes.fromhex(args.key)
        if len(key) != 16:
            ap.error('--key must be 16 bytes (32 hex chars)')
    elif args.userid:
        if not args.mask:
            ap.error('--userid needs --mask (the 16-byte DefaultSaveGameKey mask)')
        mask = bytes.fromhex(args.mask)
        if len(mask) != 16:
            ap.error('--mask must be 16 bytes (32 hex chars)')
        key = derive_key(args.userid, mask)

    raw = open(args.input, 'rb').read()
    doc, version = decrypt_file(raw, key)
    out = json.dumps(doc, indent=2, ensure_ascii=False)
    if args.output:
        open(args.output, 'w').write(out + '\n')
        print(f'decrypted (version byte {version}) -> {args.output}')
    else:
        print(out)
    if args.encrypt_back:
        if not key:
            ap.error('--encrypt-back needs a key')
        open(args.encrypt_back, 'wb').write(encrypt_file(doc, key, version))
        print(f're-encrypted -> {args.encrypt_back}')


if __name__ == '__main__':
    main()
