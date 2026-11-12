#!/usr/bin/env python3
"""Parse global-metadata.dat v31 dengan layout yang benar.
TypeDefinition=88B (methodStart@36, method_count@64, field_count@68, bitfield@80)
MethodDefinition=40B (nameIndex@0, parameterCount dicari)
"""
import struct, sys

data = open(sys.argv[1], 'rb').read()
hdr = struct.unpack('<74I', data[:296])
assert hdr[0] == 0xFAB11BAF and hdr[1] == 31
STR_OFF, STR_SZ = hdr[6], hdr[7]
MET_OFF, MET_SZ = hdr[12], hdr[13]
TD_OFF, TD_SZ = hdr[40], hdr[41]

TD_SIZE, MET_SIZE = 88, 40
n_td, n_met = TD_SZ // TD_SIZE, MET_SZ // MET_SIZE
assert TD_SZ % TD_SIZE == 0 and MET_SZ % MET_SIZE == 0, (TD_SZ, MET_SZ)
print(f"typedefs={n_td} methods={n_met}", file=sys.stderr)

def getstr(idx):
    if idx == 0xFFFFFFFF or idx >= STR_SZ:
        return ''
    end = data.index(b'\x00', STR_OFF + idx)
    return data[STR_OFF + idx:end].decode('utf-8', 'replace')

# Kalibrasi offset parameterCount: pakai typedef pertama yg methodStart valid
# Cari method dengan nama dikenal, lihat u16 mana yg cocok jadi parameterCount
if len(sys.argv) > 3 and sys.argv[3] == 'calib':
    for i in range(n_td):
        off = TD_OFF + i * TD_SIZE
        mstart = struct.unpack('<i', data[off+36:off+40])[0]
        mc = struct.unpack('<H', data[off+64:off+66])[0]
        if 0 <= mstart < n_met and 0 < mc < 50:
            moff = MET_OFF + mstart * MET_SIZE
            mn = getstr(struct.unpack('<I', data[moff:moff+4])[0])
            if mn and not mn.startswith('<'):
                print(f"td[{i}] {mn}: raw40=", data[moff:moff+40].hex())
                if i > 3:
                    break
    sys.exit(0)

target_ns = sys.argv[2] if len(sys.argv) > 2 else "COW.GamePlay"
PC_OFF = int(sys.argv[4]) if len(sys.argv) > 4 else 38

out = []
for i in range(n_td):
    off = TD_OFF + i * TD_SIZE
    name_i, ns_i = struct.unpack('<II', data[off:off+8])
    if getstr(ns_i) != target_ns:
        continue
    mstart = struct.unpack('<i', data[off+36:off+40])[0]
    mc = struct.unpack('<H', data[off+64:off+66])[0]
    fc = struct.unpack('<H', data[off+68:off+70])[0]
    bitfield = struct.unpack('<I', data[off+80:off+84])[0]
    is_valuetype = bool(bitfield & 1)
    methods = []
    if 0 <= mstart < n_met:
        for j in range(mc):
            if mstart + j >= n_met:
                break
            moff = MET_OFF + (mstart + j) * MET_SIZE
            mn_i = struct.unpack('<I', data[moff:moff+4])[0]
            pc = struct.unpack('<H', data[moff+PC_OFF:moff+PC_OFF+2])[0]
            methods.append((getstr(mn_i), pc))
    out.append((getstr(name_i), fc, is_valuetype, methods))

print(f"== {target_ns}: {len(out)} class ==")
for name, fc, vt, methods in sorted(out, key=lambda x: x[0]):
    tag = "struct" if vt else "class"
    print(f"\n[{tag} {name}] fields={fc} methods={len(methods)}")
    for mn, pc in methods[:40]:
        print(f"    {mn} (params={pc})")
