#!/usr/bin/env python3
"""Decrypt Pocong Outbreak main save files (OwnGames OwnSaveData scheme).

Game: com.owngames.pocongoutbreak 1.6.3.6 (code 43)
Files (app internal files dir, root access needed to pull):
    save_data_beta.owndata
    save_data_rilis.owndata
Crypto: DES/ECB/PKCS5Padding, key = first 8 bytes of UTF-8 "ufajdm2d3"
        -> effective DES key "ufajdm2d" (hex 7566616a646d3264).
Plaintext: JSON (UTF-8) with obfuscated field names, e.g.
    hansufesoas, ajlfilefd, yhuefadefe, ukesfhidas, akufhaeyfa,
    uafyfeas, auhgenyfas, akufnede, uabfeyafh2..6, whfaufefe,
    akfbnefes, sejfsejsd, luhfnseifo, aifnefnis, aufhneuas,
    iahfnyefgs, afnueafhis, auhfneusfs, sefsuhsse, aufhysefasce(2),
    afhnesade, afnrusde, allfeufs, uafhafefasd, ayfgesufjfs,
    fufaiioefes, iefiodakasd, nbltaspiba
    (plus a readable key "weapon").
Proven from: Java com.owngames.ownengine.io.OwnSaveData (DES/ECB/PKCS5Padding,
DESKeySpec, file = fileName + "data") + native GameData::GameData
(libnative-lib.so) constructing OwnSaveData("save_data_beta.own","ufajdm2d3")
and OwnSaveData("save_data_rilis.own","ufajdm2d3").

Usage:
    python3 pocong_save_decrypt.py <save_data_rilis.owndata>
    python3 pocong_save_decrypt.py <file> --encrypt <plain.json>  (re-encrypt)
Requires pycryptodome (falls back to `openssl enc -des-ecb`).
"""
import sys, subprocess

KEY = b"ufajdm2d"  # first 8 bytes of "ufajdm2d3"

def _des_decrypt(data: bytes) -> bytes:
    try:
        from Crypto.Cipher import DES
        return DES.new(KEY, DES.MODE_ECB).decrypt(data)
    except ImportError:
        p = subprocess.run(["openssl", "enc", "-des-ecb", "-d",
                            "-K", KEY.hex(), "-nopad"],
                           input=data, capture_output=True)
        if p.returncode != 0:
            raise RuntimeError("openssl failed: " + p.stderr.decode())
        return p.stdout

def _des_encrypt(data: bytes) -> bytes:
    try:
        from Crypto.Cipher import DES
        return DES.new(KEY, DES.MODE_ECB).encrypt(data)
    except ImportError:
        p = subprocess.run(["openssl", "enc", "-des-ecb",
                            "-K", KEY.hex(), "-nopad"],
                           input=data, capture_output=True)
        if p.returncode != 0:
            raise RuntimeError("openssl failed: " + p.stderr.decode())
        return p.stdout

def unpad(b: bytes) -> bytes:
    n = b[-1]
    if 1 <= n <= 8 and b[-n:] == bytes([n]) * n:
        return b[:-n]
    return b

def pad(b: bytes) -> bytes:
    n = 8 - (len(b) % 8)
    return b + bytes([n]) * n

def decrypt_file(path: str) -> str:
    raw = open(path, "rb").read()
    return unpad(_des_decrypt(raw)).decode("utf-8")

def encrypt_text(text: str) -> bytes:
    return _des_encrypt(pad(text.encode("utf-8")))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    if len(sys.argv) >= 4 and sys.argv[2] == "--encrypt":
        out = encrypt_text(open(sys.argv[3], encoding="utf-8").read())
        open(sys.argv[1], "wb").write(out)
        print("encrypted ->", sys.argv[1], len(out), "bytes")
    else:
        print(decrypt_file(sys.argv[1]))
