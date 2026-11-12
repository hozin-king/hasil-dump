#!/usr/bin/env python3
"""Parser global-metadata.dat v31 (layout tervalidasi dari FF Max).
Usage: parse_v31.py <metadata.dat> [keyword]"""
import struct, sys

data = open(sys.argv[1], 'rb').read()
magic, ver = struct.unpack('<II', data[:8])
assert magic == 0xFAB11BAF and ver == 31, (hex(magic), ver)

def u32(off): return struct.unpack('<I', data[off:off+4])[0]
def u16(off): return struct.unpack('<H', data[off:off+2])[0]

# header (v31) — offset dari Il2CppDumper
stringOffset, stringSize = u32(0x18), u32(0x1C)
methodsOffset, methodsSize = u32(0x30), u32(0x34)
fieldsOffset, fieldsSize = u32(0x60), u32(0x64)
typeDefsOffset, typeDefsSize = u32(0xA0), u32(0xA4)

# layout tervalidasi (FF Max v31)
TD_SZ, TD_NAME, TD_NS = 88, 0, 4
TD_FIELD_START, TD_METHOD_START = 32, 36
TD_METHOD_COUNT, TD_FIELD_COUNT = 64, 68
MET_SZ, MET_NAME, MET_PARAMCOUNT = 40, 0, 38
FLD_SZ, FLD_NAME = 12, 0

def get_str(idx):
    if idx == 0xFFFFFFFF or idx >= stringSize: return ""
    start = stringOffset + idx
    end = data.index(b'\x00', start, stringOffset + stringSize)
    return data[start:end].decode('utf-8', 'ignore')

n_td = typeDefsSize // TD_SZ
n_m = methodsSize // MET_SZ
print(f"TypeDefs: {n_td}, Methods: {n_m}", file=sys.stderr)

kw = sys.argv[2].lower() if len(sys.argv) > 2 else None
found = 0
for i in range(n_td):
    off = typeDefsOffset + i*TD_SZ
    name = get_str(u32(off+TD_NAME)); ns = get_str(u32(off+TD_NS))
    full = f"{ns}.{name}" if ns else name
    ms = u32(off+TD_METHOD_START); mc = u16(off+TD_METHOD_COUNT)
    fs = u32(off+TD_FIELD_START); fc = u16(off+TD_FIELD_COUNT)
    methods = []
    for j in range(mc):
        mi = ms + j
        if mi >= n_m: break
        moff = methodsOffset + mi*MET_SZ
        mn = get_str(u32(moff+MET_NAME))
        pc = u16(moff+MET_PARAMCOUNT)
        methods.append((mn, pc))
    fields = []
    # (field detail dilewati bila tidak perlu)
    if kw:
        if kw in full.lower() or any(kw in m[0].lower() for m in methods):
            print(f"\n== {full} [{i}] ({mc} methods, {fc} fields)")
            for mn, pc in methods: print(f"   - {mn}({pc})")
            found += 1
            if found > 25: break
    elif mc:
        print(f"{full}: {mc}")
