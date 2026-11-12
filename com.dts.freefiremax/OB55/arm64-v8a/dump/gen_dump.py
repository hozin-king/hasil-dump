#!/usr/bin/env python3
"""Generate dump.cs-style dari global-metadata.dat v31 untuk namespace COW.*"""
import struct, sys

data = open('global-metadata-dec.dat', 'rb').read()
hdr = struct.unpack('<74I', data[:296])
STR_OFF, STR_SZ = hdr[6], hdr[7]
MET_OFF, MET_SZ = hdr[12], hdr[13]
FLD_OFF, FLD_SZ = hdr[24], hdr[25]
TD_OFF, TD_SZ = hdr[40], hdr[41]
n_td, n_met, n_fld = TD_SZ // 88, MET_SZ // 40, FLD_SZ // 12

def getstr(idx):
    if idx == 0xFFFFFFFF or idx >= STR_SZ:
        return ''
    end = data.index(b'\x00', STR_OFF + idx)
    return data[STR_OFF + idx:end].decode('utf-8', 'replace')

# kelompokkan per namespace
ns_map = {}
for i in range(n_td):
    off = TD_OFF + i * 88
    name_i, ns_i = struct.unpack('<II', data[off:off+8])
    ns = getstr(ns_i)
    if not ns.startswith('COW'):
        continue
    mstart = struct.unpack('<i', data[off+36:off+40])[0]
    fstart = struct.unpack('<i', data[off+32:off+36])[0]
    mc = struct.unpack('<H', data[off+64:off+66])[0]
    fc = struct.unpack('<H', data[off+68:off+70])[0]
    bitfield = struct.unpack('<I', data[off+80:off+84])[0]
    kind = 'struct' if (bitfield & 1) else 'class'
    fields = []
    if 0 <= fstart < n_fld:
        for j in range(fc):
            if fstart + j >= n_fld:
                break
            foff = FLD_OFF + (fstart + j) * 12
            fn = getstr(struct.unpack('<I', data[foff:foff+4])[0])
            if fn:
                fields.append(fn)
    methods = []
    if 0 <= mstart < n_met:
        for j in range(mc):
            if mstart + j >= n_met:
                break
            moff = MET_OFF + (mstart + j) * 40
            mn = getstr(struct.unpack('<I', data[moff:moff+4])[0])
            pc = struct.unpack('<H', data[moff+38:moff+40])[0]
            if mn:
                methods.append((mn, pc))
    ns_map.setdefault(ns, []).append((getstr(name_i), kind, i, fields, methods))

with open('FFMax-dump.cs', 'w', encoding='utf-8') as f:
    f.write('// Generated from global-metadata.dat (XOR 0xE8 decrypted), metadata v31\n')
    f.write(f'// {n_td} typedefs total, {sum(len(v) for v in ns_map.values())} classes in COW.*\n\n')
    for ns in sorted(ns_map):
        f.write(f'// ===== Namespace: {ns} ({len(ns_map[ns])} types) =====\n\n')
        for name, kind, idx, fields, methods in sorted(ns_map[ns], key=lambda x: x[0]):
            f.write(f'{kind} {name} // TypeDefIndex: {idx}\n{{\n')
            if fields:
                f.write('\t// Fields\n')
                for fn in fields:
                    f.write(f'\t//   {fn}\n')
            if methods:
                f.write('\t// Methods\n')
                for mn, pc in methods:
                    f.write(f'\t//   {mn}({pc} params)\n')
            f.write('}\n\n')

total = sum(len(v) for v in ns_map.values())
print(f'done: {total} types, namespaces: {sorted(ns_map.keys())}')
