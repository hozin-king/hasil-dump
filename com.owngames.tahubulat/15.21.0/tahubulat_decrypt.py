#!/usr/bin/env python3
"""
Tahu Bulat save data decryptor/encryptor.
Mekanisme: DES/ECB/PKCS5Padding (javax.crypto) via class
           com.owngames.ownengine.io.OwnSaveData

  Constructor: OwnSaveData(activity, fileName, key)
  - keyString.getBytes("UTF-8") -> DESKeySpec -> SecretKey
  - Cipher.getInstance("DES/ECB/PKCS5Padding")

Key v2.3.0 (dari JavaHelper.<clinit>):
  pasangan (filename, key):
"""
import sys

KEYS_V230 = {
    'kgvrjevfw.own':   'acscvees',
    'walaidwjss2.own': 'aiiafkaksff',  # 15.21.0, native (GameData ctor) — untuk file .owndata walaidwjss2
    'plasmesllasf.own': 'odmvmmsllas',
    'oamwlfalsduu.own': 'skmettlsffs',
    'if29ciw3fcke.own': 'l3mfej3das',
    'kvskdnwem2kc.own': '93flmedwcn',
    'kcsk29kcseks.own': '8f4n2adkms',
    'okwocmsd024v.own': '03kp3cm3xw',
    'kajsck302ecs.own': 'p2l3mexs4h',
    'fjakcn3mkacs.own': 'rnfk3cexfs',
    'aknvke329r8s.own': 'kanfem12r3',
    'lkcoekr23iko.own': 'mklf2f2kds',
    'iwpld29asscs.own': 'laskf21csa',
    'afnjenjgnvsf.own': 'afk2nk34fe',
    'bfejnfkmlcas.own': 'cmlecelssc',
    'dubgemcksaas.own': 'ejnkcdmlsa',
    'makjfmeoasce.own': 'maskmfkemfl',
}

def des_key(key_str: str) -> bytes:
    kb = key_str.encode('utf-8')[:8]
    return kb.ljust(8, b'\0')

def decrypt_file(path: str, key_str: str) -> bytes:
    from Crypto.Cipher import DES
    data = open(path, 'rb').read()
    pt = DES.new(des_key(key_str), DES.MODE_ECB).decrypt(data)
    pad = pt[-1]
    if 1 <= pad <= 8 and pt[-pad:] == bytes([pad]) * pad:
        pt = pt[:-pad]  # buang PKCS5 padding
    return pt

def encrypt_file(plain: bytes, key_str: str) -> bytes:
    from Crypto.Cipher import DES
    pad = 8 - (len(plain) % 8)
    plain += bytes([pad]) * pad
    return DES.new(des_key(key_str), DES.MODE_ECB).encrypt(plain)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f'pakai: {sys.argv[0]} <file.owndata> <key> [output]')
        print('key v2.3.0 ada di KEYS_V230 di dalam script ini')
        sys.exit(1)
    out = decrypt_file(sys.argv[1], sys.argv[2])
    if len(sys.argv) > 3:
        open(sys.argv[3], 'wb').write(out)
        print(f'decrypt OK -> {sys.argv[3]} ({len(out)} bytes)')
    else:
        sys.stdout.buffer.write(out)
