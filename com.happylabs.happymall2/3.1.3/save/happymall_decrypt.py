#!/usr/bin/env python3
"""Decrypt / re-encrypt Happy Mall Story (com.happylabs.happymall2) save files.

Format (proven by static REA of libhappymall.so 3.1.3 + byte-identical
round-trip on the user's real save_0.dat):
  File (version 3):
    [0x00] int32 LE version (2 or 3; this tool writes 3)
    [0x04] uint32 LE XOR key, stored PLAINTEXT (per-save random-looking
           32-bit word; 0x55BAB0C7 in the user's file)
    [0x08..0x98) header fields, XORed per 32-bit word with the key
    [0x98..] zlib-compressed payload (level 1), XORed per 32-bit word
           with the key (aligned to payload start)
  Header (after XOR, v3):
    [0x08] int32 ? = 491 in the user's file (meaning not yet traced)
    [0x0C..0x17] int32 zeros (reserved?)
    [0x18..0x37] SHA-256 of the DECOMPRESSED data (32 bytes, XORed)
    [0x38..0x77] 8x int64: cumulative section end offsets in
           (header+payload) coordinates, last-but-one 3692, then
           [0x70] = decompressed size (3556 in the user's file)
    [0x78..0x97] 32 zero bytes (reserved?)
  Decompressed payload: 7 sections (CPlayerData 224 B first, then 6 more),
  each starting with an int32 version. Section boundaries are the header
  int64 table (buffer coords) minus the 152-byte header size.

  Version 2 files use a 120-byte header instead (size at [0x54],
  SHA-256 at [0x14], payload at [0x78]); this tool READS v2 as well
  (ProcessSaveFile migrates v2 -> v3 on load) but always WRITES v3.

Crypto notes:
  - The XOR key is stored IN the file: obfuscation, not real encryption.
  - SHA-256 is a plain (unkeyed) integrity hash; recomputed on write.
  - zlib level is 1 (verified byte-identical re-compression).

Usage:
  python3 happymall_decrypt.py save_0.dat [-o out.bin]
  python3 happymall_decrypt.py save_0.dat --encrypt-back out.dat
      (re-encrypt a decompressed .bin back to a .dat; header rebuilt,
       key reused from the original file, SHA-256 recomputed)
  python3 happymall_decrypt.py save_0.dat --json out.json
      (decrypt + parse the CPlayerData section into JSON)

LOCAL ONLY: never put a real user save (or its decrypted form) in a
public repo. The decryption key here is read from the file itself.
"""
import argparse
import hashlib
import json
import struct
import sys
import zlib

HEADER_V3 = 0x98
HEADER_V2 = 0x78


def xor_words(buf, key, start=0):
    """XOR bytes from `start` with the 4-byte key repeating (aligned so
    that buf[start] pairs with key[0]). Handles a non-multiple-of-4 tail."""
    kb = struct.pack('<I', key)
    out = bytearray(buf)
    for i in range(start, len(out)):
        out[i] ^= kb[(i - start) % 4]
    return bytes(out)


def parse_header(raw):
    """Return (version, key, size_off, hash_off, header_len, decomp_size, table)."""
    version, = struct.unpack_from('<I', raw, 0)
    key, = struct.unpack_from('<I', raw, 4)
    if version == 3:
        header_len = HEADER_V3
        size_off, hash_off = 0x70, 0x18
    elif version == 2:
        header_len = HEADER_V2
        size_off, hash_off = 0x54, 0x14
    else:
        raise ValueError(f'unsupported save version {version}')
    # XOR the header (from offset 8) to read fields
    hdrx = xor_words(raw[:header_len], key, start=8)
    decomp_size, = struct.unpack_from('<I', hdrx, size_off)
    table = list(struct.unpack_from('<8q', hdrx, 0x38)) if version == 3 else []
    sha = hdrx[hash_off:hash_off + 32]
    return version, key, header_len, decomp_size, table, sha


def decrypt(raw):
    version, key, header_len, decomp_size, table, sha = parse_header(raw)
    payload = xor_words(raw[header_len:], key)
    plain = zlib.decompress(payload)
    if len(plain) != decomp_size:
        raise ValueError(
            f'decompressed size {len(plain)} != header size {decomp_size}')
    if hashlib.sha256(plain).digest() != sha:
        raise ValueError('SHA-256 mismatch: wrong key or corrupt file')
    return {
        'version': version, 'key': key, 'header_len': header_len,
        'decomp_size': decomp_size, 'table': table,
        'plain': plain, 'compressed_len': len(raw) - header_len,
    }


def encrypt(plain, key, table=None, version=3):
    """Rebuild a v3 file from decompressed data, reusing the given key.
    `table` is the 8-entry section table from the original file; the game
    uses it to locate sections, so pass the original table when editing
    a real save (table[7] is refreshed to len(plain) here)."""
    if version != 3:
        raise ValueError('this tool only writes version 3')
    header_len = HEADER_V3
    comp = zlib.compress(plain, 1)
    sha = hashlib.sha256(plain).digest()
    hdr = bytearray(header_len)
    struct.pack_into('<I', hdr, 0, 3)
    struct.pack_into('<I', hdr, 4, key)
    if table:
        struct.pack_into('<8q', hdr, 0x38, *table[:7], len(plain))
    else:
        struct.pack_into('<I', hdr, 0x70, len(plain))
    hdr[0x18:0x38] = sha
    # XOR header fields from offset 8, then payload, with the key
    hdrx = xor_words(bytes(hdr), key, start=8)
    payx = xor_words(comp, key)
    return hdrx + payx


def encrypt_like_original(plain, orig_raw):
    """Re-encrypt using the original file's header as template (exact
    round-trip): same key, same table values, only size/hash refreshed."""
    version, key, header_len, _, table, _ = parse_header(orig_raw)
    if version != 3:
        raise ValueError('round-trip template must be a v3 file')
    comp = zlib.compress(plain, 1)
    sha = hashlib.sha256(plain).digest()
    hdr = bytearray(orig_raw[:header_len])
    # de-XOR the template header, refresh size + hash, re-XOR
    hdrx = bytearray(xor_words(bytes(hdr), key, start=8))
    struct.pack_into('<I', hdrx, 0x70, len(plain))
    hdrx[0x18:0x38] = sha
    hdrx = bytearray(xor_words(bytes(hdrx), key, start=8))
    # restore raw version + key bytes (xor_words leaves [0..8) alone)
    hdrx[0:4] = orig_raw[0:4]
    hdrx[4:8] = orig_raw[4:8]
    return bytes(hdrx) + xor_words(comp, key)


# ------------------------------------------------------- CPlayerData parse
# Proven by code trace (getters/setters in libhappymall.so 3.1.3 arm64):
#   coins     = [0x04] XOR [0x70] ; diamonds = [0x08] XOR [0x74]
#   (mask words at +0x70/+0x74 are re-randomised on every AdjCoin/AdjDiamond)
#   name      = char[64] at +0x1C (GetName returns struct+0x1C)
#   fraud flag byte at +0x68 (IsFraudulent); if set, GetCoins/GetDiamonds
#   return 0.
def parse_player(blob):
    if len(blob) < 0xE0:
        raise ValueError('blob too short for CPlayerData (need 224 bytes)')
    p = blob[:0xE0]
    u32 = lambda o: struct.unpack_from('<I', p, o)[0]
    u8 = lambda o: p[o]
    coins = u32(0x04) ^ u32(0x70)
    diamonds = u32(0x08) ^ u32(0x74)
    name = p[0x1C:0x1C + 64].split(b'\x00')[0].decode('utf-8', 'replace')
    return {
        'version': u32(0x00),
        'coins': coins,
        'diamonds': diamonds,
        'coins_mask': u32(0x70),
        'diamonds_mask': u32(0x74),
        'bgm_enabled': bool(u8(0x0C)),
        'se_enabled': bool(u8(0x0D)),
        'advertisements_removed': bool(u8(0x0E)),
        'language': u32(0x10),
        'max_workers': u32(0x18),
        'name': name,
        'avatar_id': u32(0x5C),
        'donated_coins': u32(0x60),
        'tutorial_step': u32(0x64),
        'fraudulent': bool(u8(0x68)),
        'notifications_enabled': bool(u8(0x69)),
        'tourist_clicking_enabled': bool(u8(0x6A)),
        'play_time_seconds': u32(0x6C),
        'large_status_bar': bool(u8(0x78)),
        'multi_story_visit_disabled': bool(u8(0x79)),
        'subscription_active': bool(u8(0x7A)),
        'house_ad_fetch_time': u32(0x7C),
    }


def main():
    ap = argparse.ArgumentParser(description='Decrypt Happy Mall Story saves')
    ap.add_argument('input', help='save .dat file')
    ap.add_argument('-o', '--output', help='write decompressed blob here')
    ap.add_argument('--json', help='write parsed CPlayerData JSON here')
    ap.add_argument('--encrypt-back', metavar='OUT',
                    help='re-encrypt decompressed input back to .dat')
    args = ap.parse_args()

    raw = open(args.input, 'rb').read()
    if args.encrypt_back:
        # input is a decompressed blob; need an original template: use the
        # file given with --template? No: encrypt-back expects the input
        # to be a .dat and re-encrypts its own plaintext (round-trip check).
        info = decrypt(raw)
        out = encrypt_like_original(info['plain'], raw)
        open(args.encrypt_back, 'wb').write(out)
        print(f'round-trip re-encrypted ({len(out)} bytes) -> {args.encrypt_back}')
        print('byte-identical to original:', out == raw)
        return

    info = decrypt(raw)
    print(f"version={info['version']} key=0x{info['key']:08x} "
          f"decompressed={info['decomp_size']} bytes "
          f"compressed={info['compressed_len']} bytes")
    print(f"header table (int64): {info['table']}")
    if args.output:
        open(args.output, 'wb').write(info['plain'])
        print(f'decompressed -> {args.output}')
    if args.json:
        doc = {'player': parse_player(info['plain'])}
        open(args.json, 'w').write(json.dumps(doc, indent=2) + '\n')
        print(f"parsed JSON -> {args.json}")
        print(json.dumps(doc, indent=2))
    else:
        print(json.dumps({'player': parse_player(info['plain'])}, indent=2))


if __name__ == '__main__':
    main()
