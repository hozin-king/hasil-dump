#!/usr/bin/env python3
"""Validator: parse balik Assembly-CSharp.dll hasil emit."""
import struct, sys

d = open('Assembly-CSharp.dll', 'rb').read()
assert d[0:2] == b'MZ', 'bukan MZ'
e_lfanew = struct.unpack('<I', d[0x3C:0x40])[0]
assert d[e_lfanew:e_lfanew+4] == b'PE\x00\x00', 'bukan PE'
coff = e_lfanew + 4
nsec = struct.unpack('<H', d[coff+2:coff+4])[0]
opt_sz = struct.unpack('<H', d[coff+16:coff+18])[0]
print(f"PE OK: {nsec} section, optsize={opt_sz}")
assert opt_sz == 224
# CLI directory = entry 14 (optional header mulai di coff+20, dirs di +96)
dd_off = coff + 20 + 96
num_dirs = struct.unpack('<I', d[dd_off:dd_off+4])[0]
cli_rva, cli_sz = struct.unpack('<II', d[dd_off+14*8:dd_off+14*8+8])
print(f"CLI rva={cli_rva:#x} size={cli_sz}")
# section .text: file offset dari RVA
sh = coff + 20 + opt_sz
s_vaddr, s_raw = struct.unpack('<II', d[sh+12:sh+20])
s_prdata = struct.unpack('<I', d[sh+20:sh+24])[0]
cli_off = s_prdata + (cli_rva - s_vaddr)
assert struct.unpack('<I', d[cli_off:cli_off+4])[0] == 72
md_rva, md_sz = struct.unpack('<II', d[cli_off+8:cli_off+16])
md_off = s_prdata + (md_rva - s_vaddr)
assert d[md_off:md_off+4] == b'BSJB', 'bukan BSJB'
print(f"Metadata OK di offset {md_off:#x}, size {md_sz}")
ver_len = struct.unpack('<I', d[md_off+12:md_off+16])[0]
p = md_off + 16 + ((ver_len + 3) // 4) * 4
p += 2  # flags
nstreams = struct.unpack('<H', d[p:p+2])[0]
p += 2
streams = {}
for _ in range(nstreams):
    off, sz = struct.unpack('<II', d[p:p+8])
    nm_end = d.index(b'\x00', p + 8)
    nm = d[p+8:nm_end].decode()
    streams[nm] = (md_off + off, sz)
    p = nm_end + 1
    while (p - md_off) % 4:
        p += 1
print("streams:", {k: v[1] for k, v in streams.items()})
# parse #~
to = streams['#~'][0]
heap_sizes = d[to+7]
str_big = bool(heap_sizes & 1)
blob_big = bool(heap_sizes & 4)
S = 4 if str_big else 2
print(f"heapSizes={heap_sizes:#x} str_big={str_big} blob_big={blob_big}")
valid = struct.unpack('<Q', d[to+8:to+16])[0]
p = to + 24
present = [t for t in range(64) if valid & (1 << t)]
rows = {}
for t in present:
    rows[t] = struct.unpack('<I', d[p:p+4])[0]
    p += 4
print("rows:", rows)
# baca TypeDef (0x02): Flags(4) Name(S) Ns(S) Extends(4) FieldList(F) MethodList(4)
n_td = rows[0x02]
F = 4 if rows.get(0x04, 0) >= 0xFFFF else 2
str_off = streams['#Strings'][0]
def gs(idx):
    e = d.index(b'\x00', str_off + idx)
    return d[str_off+idx:e].decode('utf-8', 'replace')
ok = 0
for i in range(min(n_td, 5000)):
    r = p + i * (4 + S + S + 4 + F + 4)
    nm = gs(struct.unpack('<I' if S == 4 else '<H', d[r+4:r+4+S])[0])
    if nm and len(nm) < 200:
        ok += 1
print(f"TypeDef sample valid: {ok}/5000")
# cari Player
found = None
for i in range(n_td):
    r = p + i * (4 + S + S + 4 + F + 4)
    nm = gs(struct.unpack('<I' if S == 4 else '<H', d[r+4:r+4+S])[0])
    if nm == 'Player':
        nsp = gs(struct.unpack('<I' if S == 4 else '<H', d[r+4+S:r+4+S+S])[0])
        found = (i, nsp)
        break
print("Player:", found)
print("VALIDASI SELESAI" if found and found[1] == 'COW.GamePlay' else "GAGAL: Player/COW.GamePlay tidak ketemu")
