#!/usr/bin/env python3
"""Dump semua type di Assembly-CSharp.dll (types 0..37669), grup per namespace."""
import struct

data = open('global-metadata-dec.dat', 'rb').read()
hdr = struct.unpack('<74I', data[:296])
STR_OFF, STR_SZ = hdr[6], hdr[7]
MET_OFF, MET_SZ = hdr[12], hdr[13]
FLD_OFF, FLD_SZ = hdr[24], hdr[25]
TD_OFF = hdr[40]
n_met, n_fld = MET_SZ // 40, FLD_SZ // 12

def getstr(idx):
    if idx == 0xFFFFFFFF or idx >= STR_SZ:
        return ''
    end = data.index(b'\x00', STR_OFF + idx)
    return data[STR_OFF + idx:end].decode('utf-8', 'replace')

ns_map = {}
for i in range(37670):
    off = TD_OFF + i * 88
    name_i, ns_i = struct.unpack('<II', data[off:off+8])
    ns, name = getstr(ns_i), getstr(name_i)
    if not name:
        continue
    mstart = struct.unpack('<i', data[off+36:off+40])[0]
    fstart = struct.unpack('<i', data[off+32:off+36])[0]
    mc = struct.unpack('<H', data[off+64:off+66])[0]
    fc = struct.unpack('<H', data[off+68:off+70])[0]
    bitfield = struct.unpack('<I', data[off+80:off+84])[0]
    kind = 'struct' if (bitfield & 1) else 'class'
    fields = []
    if 0 <= fstart < n_fld:
        for j in range(min(fc, 500)):
            if fstart + j >= n_fld:
                break
            foff = FLD_OFF + (fstart + j) * 12
            fn = getstr(struct.unpack('<I', data[foff:foff+4])[0])
            if fn:
                fields.append(fn)
    methods = []
    if 0 <= mstart < n_met:
        for j in range(min(mc, 2000)):
            if mstart + j >= n_met:
                break
            moff = MET_OFF + (mstart + j) * 40
            mn = getstr(struct.unpack('<I', data[moff:moff+4])[0])
            pc = struct.unpack('<H', data[moff+38:moff+40])[0]
            if mn:
                methods.append((mn, pc))
    ns_map.setdefault(ns, []).append((name, kind, i, fields, methods))

with open('FFMax-Assembly-CSharp.cs', 'w', encoding='utf-8') as f:
    f.write('// Assembly-CSharp.dll — full dump from global-metadata.dat (XOR 0xE8), v31\n')
    f.write('// 37670 types\n\n')
    for ns in sorted(ns_map):
        label = ns if ns else '(global namespace)'
        f.write(f'// ===== Namespace: {label} ({len(ns_map[ns])} types) =====\n\n')
        for name, kind, idx, fields, methods in sorted(ns_map[ns], key=lambda x: x[0]):
            f.write(f'{kind} {name} // TypeDefIndex: {idx}\n{{\n')
            for fn in fields:
                f.write(f'\t// field: {fn}\n')
            for mn, pc in methods:
                f.write(f'\t// method: {mn}({pc} params)\n')
            f.write('}\n\n')
print('namespaces:', len(ns_map), 'types:', sum(len(v) for v in ns_map.values()))
