#!/usr/bin/env python3
"""Decrypt Citampi Stories (.sav) save files.

Format (reverse-engineered from libil2cpp.so, Ikaan.Utility.IkaanDataFormat):
  byte[0]      = dictSeed (0xff, constant in saveHelper's Encode call)
  bytes[1..48] = AES IV (16 bytes) + AES key (32 bytes), interleaved by a
                 seed-dependent permutation (_getIndiciesMap: 16 distinct
                 ints in 1..47 from System.Random(seed), sorted ascending;
                 positions in the map hold IV bytes, the rest hold key bytes)
  bytes[49..]  = AES-256-CBC ciphertext (PKCS7) of the UTF-8 JSON save data

The AES key/IV are random per file and stored in the file itself (permuted);
there is NO hardcoded key. Decryption is a pure re-implementation of the
game's own Decode routine.
"""
import json
import struct
import sys

from Crypto.Cipher import AES


class DotNetRandom:
    """Legacy .NET Framework / Mono System.Random (subtractive generator)."""

    MBIG = 2147483647
    MSEED = 161803398

    def __init__(self, seed):
        # Seed() — VERIFIED against the game's own System.Random ctor
        # (libil2cpp.so RVA 0x4442358) and against .NET 8 reference output:
        # SeedArray[55] = MSEED - |seed| (NOT SeedArray[0]); the shuffle
        # loop runs 54 iterations (i=1..54), so SeedArray[0] stays 0.
        # The classic .NET Framework variant (SeedArray[0], 55 iterations)
        # produces WRONG values from the 3rd sample on.
        num = 2147483647 if seed == -2147483648 else abs(seed)
        num2 = self.MSEED - num
        self.seed_array = [0] * 56
        self.seed_array[55] = num2
        num3 = 1
        for i in range(1, 55):
            num4 = (21 * i) % 55
            self.seed_array[num4] = num3
            num3 = num2 - num3
            if num3 < 0:
                num3 += self.MBIG
            num2 = self.seed_array[num4]
        for _ in range(1, 5):
            for k in range(1, 56):
                self.seed_array[k] -= self.seed_array[1 + (k + 30) % 55]
                if self.seed_array[k] < 0:
                    self.seed_array[k] += self.MBIG
        self.inext = 0
        self.inextp = 21

    def sample(self):
        inext = self.inext + 1
        if inext >= 56:
            inext = 1
        inextp = self.inextp + 1
        if inextp >= 56:
            inextp = 1
        num = self.seed_array[inext] - self.seed_array[inextp]
        if num == self.MBIG:
            num -= 1
        if num < 0:
            num += self.MBIG
        self.seed_array[inext] = num
        self.inext = inext
        self.inextp = inextp
        return num * (1.0 / self.MBIG)

    def next_double(self):
        return self.sample()


def get_indicies_map(dict_seed):
    """Replicates IkaanDataFormat._getIndiciesMap: 16 distinct ints in 1..47."""
    rand = DotNetRandom(dict_seed)
    out = []
    while len(out) < 16:
        v = int(rand.next_double() * 48.0)
        if v == 0 or v in out:
            continue
        out.append(v)
    return out


def decode(data):
    """Replicates IkaanDataFormat.Decode(byte[]) -> plaintext bytes."""
    if data is None or len(data) <= 0x30:
        return None
    header = data[:0x31]
    seed = header[0]
    indicies = sorted(get_indicies_map(seed & 0xFF))
    iv = bytearray(16)
    key = bytearray(32)
    j = k = 0
    for i in range(0x30):
        p = i + 1
        if j <= 15 and indicies[j] == p:
            iv[j] = header[1 + i]
            j += 1
        else:
            key[k] = header[1 + i]
            k += 1
    cipher = AES.new(bytes(key), AES.MODE_CBC, bytes(iv))
    pt = cipher.decrypt(data[0x31:])
    # PKCS7 unpad
    pad = pt[-1]
    if 1 <= pad <= 16 and pt[-pad:] == bytes([pad]) * pad:
        pt = pt[:-pad]
    return pt, bytes(key), bytes(iv), seed, indicies


def decrypt_file(path):
    with open(path, 'rb') as f:
        data = f.read()
    pt, key, iv, seed, indicies = decode(data)
    return pt


if __name__ == '__main__':
    for path in sys.argv[1:]:
        pt = decrypt_file(path)
        out = path + '.decrypted.json'
        with open(out, 'wb') as f:
            f.write(pt)
        obj = json.loads(pt.decode('utf-8'))
        print(f'{path}: {len(pt)} bytes plaintext, JSON top-level type '
              f'{type(obj).__name__}, keys={len(obj) if isinstance(obj, dict) else len(obj)}'
              f' -> {out}')
