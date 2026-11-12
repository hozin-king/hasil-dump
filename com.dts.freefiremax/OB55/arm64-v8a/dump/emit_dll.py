#!/usr/bin/env python3
"""Emit dummy Assembly-CSharp.dll (ECMA-335) dari global-metadata.dat v31.
Isi: TypeDef + Field + MethodDef + Param (stub, tanpa body) — cukup untuk
dibuka di dnSpy/ILSpy dan browsing nama class/method.
"""
import struct, sys

# ---------- 1. Parse metadata (layout v31) ----------
data = open('global-metadata-dec.dat', 'rb').read()
hdr = struct.unpack('<74I', data[:296])
assert hdr[0] == 0xFAB11BAF and hdr[1] == 31
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

types = []  # (ns, name, is_struct, [fields], [(method, paramcount)])
for i in range(37670):  # Assembly-CSharp.dll saja
    off = TD_OFF + i * 88
    name = getstr(struct.unpack('<I', data[off:off+4])[0])
    if not name:
        continue
    ns = getstr(struct.unpack('<I', data[off+4:off+8])[0])
    is_struct = bool(struct.unpack('<I', data[off+80:off+84])[0] & 1)
    mstart = struct.unpack('<i', data[off+36:off+40])[0]
    fstart = struct.unpack('<i', data[off+32:off+36])[0]
    mc = struct.unpack('<H', data[off+64:off+66])[0]
    fc = struct.unpack('<H', data[off+68:off+70])[0]
    fields = []
    if 0 <= fstart < n_fld and fc < 2000:
        for j in range(fc):
            if fstart + j >= n_fld:
                break
            fn = getstr(struct.unpack('<I', data[FLD_OFF + (fstart+j)*12: FLD_OFF + (fstart+j)*12 + 4])[0])
            if fn and len(fn) < 256:
                fields.append(fn)
    methods = []
    if 0 <= mstart < n_met and mc < 5000:
        for j in range(mc):
            if mstart + j >= n_met:
                break
            moff = MET_OFF + (mstart + j) * 40
            mn = getstr(struct.unpack('<I', data[moff:moff+4])[0])
            pc = struct.unpack('<H', data[moff+38:moff+40])[0]
            if mn and len(mn) < 256 and pc < 64:
                methods.append((mn, pc))
    types.append((ns, name, is_struct, fields, methods))
print(f"parsed {len(types)} types", flush=True)

# dedup (ns, name)
seen = {}
clean = []
for ns, name, st, fields, methods in types:
    key = (ns, name)
    if key in seen:
        seen[key] += 1
        name = f"{name}_{seen[key]}"
    else:
        seen[key] = 1
    clean.append((ns, name, st, fields, methods))
types = clean
print(f"after dedup {len(types)} types", flush=True)

# ---------- 2. Heaps ----------
str_heap = bytearray(b'\x00')
str_idx = {}
def add_str(s):
    if s in str_idx:
        return str_idx[s]
    i = len(str_heap)
    str_idx[s] = i
    str_heap.extend(s.encode('utf-8') + b'\x00')
    return i

blob_heap = bytearray(b'\x00')
def add_blob(bts):
    i = len(blob_heap)
    blob_heap.extend(bts)
    return i

EMPTY_BLOB = add_blob(b'')
OBJ = b'\x1c'  # ELEMENT_TYPE_OBJECT

def method_sig(paramcount):
    # DEFAULT sig: ret OBJECT, params OBJECT
    out = bytearray(b'\x00')
    # compressed param count
    if paramcount < 128:
        out.append(paramcount)
    else:
        out.extend(struct.pack('>H', paramcount | 0x8000))
    out.extend(OBJ)
    out.extend(OBJ * paramcount)
    return bytes(out)

FIELD_SIG = add_blob(b'\x06' + OBJ)

# Strings yg pasti dipakai
add_str("Assembly-CSharp")
add_str("<Module>")
add_str("mscorlib")
add_str("System")
add_str("Object")
add_str("ValueType")
add_str("")

n_type_pre = len(types)
# ---------- pre-pass: isi heap dulu biar ukuran index (2/4 byte) benar ----------
sig_cache = {}
def method_sig_cached(pc):
    if pc not in sig_cache:
        sig_cache[pc] = add_blob(method_sig(pc))
    return sig_cache[pc]

for ns, name, st, fields, methods in types:
    add_str(name); add_str(ns)
    for fn in fields:
        add_str(fn)
    for mn, pc in methods:
        add_str(mn)
        method_sig_cached(pc)
        for p in range(pc):
            add_str(f"p{p}")
print(f"pre-pass done: #Strings={len(str_heap)} #Blob={len(blob_heap)}", flush=True)

# ---------- 3. Tables ----------
# TypeRef: (resScopeCoded, name, ns)
typerefs = [
    ((1 << 2) | 2, "Object", "System"),    # row 1 -> AssemblyRef[1]
    ((1 << 2) | 2, "ValueType", "System"), # row 2
]
# AssemblyRef row 1 = mscorlib (dicatat di tabel nanti)

type_rows = []   # (flags, name, ns, extendsCoded)
field_rows = []  # (flags, name, sigBlob)
method_rows = [] # (rva, implflags, flags, name, sigBlob)
param_rows = []  # (flags, seq, name)

for ns, name, is_struct, fields, methods in types:
    ext = ((2 << 2) | 1) if is_struct else ((1 << 2) | 1)  # TypeRef row 2/1
    type_rows.append((0x00200001, name, ns, ext,
                      len(field_rows) + 1, len(method_rows) + 1))
    for fn in fields:
        field_rows.append((0x0006, fn, FIELD_SIG))
    for mn, pc in methods:
        method_rows.append((0, 0, 0x0086, mn, method_sig_cached(pc),
                            len(param_rows) + 1))
        for p in range(pc):
            param_rows.append((0, p + 1, f"p{p}"))

n_type, n_field, n_method, n_param = len(type_rows), len(field_rows), len(method_rows), len(param_rows)
print(f"tables: TypeDef={n_type} Field={n_field} Method={n_method} Param={n_param}", flush=True)

# index sizes
STR_BIG = len(str_heap) > 0xFFFF
BLOB_BIG = len(blob_heap) > 0xFFFF
S = 4 if STR_BIG else 2
B = 4 if BLOB_BIG else 2
F = 4 if n_field >= 0xFFFF else 2
M = 4 if n_method >= 0xFFFF else 2
P = 4 if n_param >= 0xFFFF else 2
# ResolutionScope coded (Module,ModuleRef,AssemblyRef,TypeRef): max rows kecil -> 2
RS = 2
# TypeDefOrRef coded (TypeDef 37k > 16383) -> 4
TDR = 4

def pack_idx(v, size):
    return struct.pack('<I' if size == 4 else '<H', v)

tables = bytearray()
# Module (0x00): Generation(2) Name(S) Mvid(G) EncId(4) EncBaseId(4)
tables.extend(struct.pack('<H', 0) + pack_idx(add_str("<Module>"), S)
              + pack_idx(1, 2) + struct.pack('<II', 0, 0))
# TypeRef (0x01)
for rs, nm, nsp in typerefs:
    tables.extend(pack_idx(rs, RS) + pack_idx(add_str(nm), S) + pack_idx(add_str(nsp), S))
# TypeDef (0x02)
for flags, nm, nsp, ext, flist, mlist in type_rows:
    tables.extend(struct.pack('<I', flags) + pack_idx(add_str(nm), S)
                  + pack_idx(add_str(nsp), S) + pack_idx(ext, TDR)
                  + pack_idx(flist, F) + pack_idx(mlist, M))
# Field (0x04)
for flags, nm, sig in field_rows:
    tables.extend(struct.pack('<H', flags) + pack_idx(add_str(nm), S) + pack_idx(sig, B))
# MethodDef (0x06)
for rva, impl, flags, nm, sig, plist in method_rows:
    tables.extend(struct.pack('<IHH', rva, impl, flags) + pack_idx(add_str(nm), S)
                  + pack_idx(sig, B) + pack_idx(plist, P))
# Param (0x08)
for flags, seq, nm in param_rows:
    tables.extend(struct.pack('<HH', flags, seq) + pack_idx(add_str(nm), S))
# Assembly (0x20)
tables.extend(struct.pack('<IHHHHI', 0x8004, 0, 0, 0, 0, 0)
              + pack_idx(EMPTY_BLOB, B) + pack_idx(add_str("Assembly-CSharp"), S)
              + pack_idx(add_str(""), S))
# AssemblyRef (0x23)
tables.extend(struct.pack('<HHHHI', 4, 0, 0, 0, 0) + pack_idx(EMPTY_BLOB, B)
              + pack_idx(add_str("mscorlib"), S) + pack_idx(add_str(""), S)
              + pack_idx(EMPTY_BLOB, B))

# ---------- 4. #~ stream ----------
heapsizes = (0x01 if STR_BIG else 0) | (0x04 if BLOB_BIG else 0)
valid = (1 << 0x00) | (1 << 0x01) | (1 << 0x02) | (1 << 0x04) | (1 << 0x06) | (1 << 0x08) | (1 << 0x20) | (1 << 0x23)
hdr_tilde = struct.pack('<I', 0) + struct.pack('<BB', 2, 0) + struct.pack('<B', heapsizes) \
    + struct.pack('<B', 0) + struct.pack('<Q', valid) + struct.pack('<Q', 0)
for t, cnt in [(0x00, 1), (0x01, 2), (0x02, n_type), (0x04, n_field),
               (0x06, n_method), (0x08, n_param), (0x20, 1), (0x23, 1)]:
    hdr_tilde += struct.pack('<I', cnt)
tilde = hdr_tilde + bytes(tables)
while len(tilde) % 4:
    tilde += b'\x00'

# ---------- 5. Metadata root ----------
us_heap = b'\x00'
guid_heap = b'\x00' * 16
streams = [(b'#~\x00\x00', tilde), (b'#Strings\x00\x00\x00', bytes(str_heap)),
           (b'#US\x00', us_heap), (b'#GUID\x00\x00\x00', guid_heap), (b'#Blob\x00\x00\x00', bytes(blob_heap))]
version_str = b'v4.0.30319\x00'
while len(version_str) % 4:
    version_str += b'\x00'
root = b'BSJB' + struct.pack('<IHH', 1, 1, 0) + struct.pack('<I', len(version_str)) \
    + version_str + struct.pack('<HH', 0, len(streams))
off = len(root) + sum(8 + len(nm) for nm, _ in streams)
# align: stream headers dulu, data sesudahnya
hdrs = b''
data_blobs = []
for nm, blob in streams:
    while off % 4:
        off += 1
    hdrs += struct.pack('<II', off, len(blob)) + nm
    data_blobs.append((off, blob))
    off += len(blob)
root += hdrs
meta = bytearray(root)
for o, blob in data_blobs:
    while len(meta) < o:
        meta += b'\x00'
    meta[o:o+len(blob)] = blob
while len(meta) % 4:
    meta += b'\x00'

# ---------- 6. PE ----------
cli = struct.pack('<I', 72) + struct.pack('<HH', 2, 5)
rva_text = 0x2000
meta_rva = rva_text + 72
cli += struct.pack('<II', meta_rva, len(meta))
cli += struct.pack('<I', 0x00000001)  # ILONLY
cli += struct.pack('<I', 0x06000001)  # EntryPointToken (dummy)
cli += struct.pack('<II', 0, 0) * 6   # resources..managednativeheader (6 dirs x 8)
assert len(cli) == 72
text_content = cli + bytes(meta)

# PE32 headers
e_lfanew = 0x80
dos = b'MZ' + b'\x00' * 58 + struct.pack('<I', e_lfanew)
pe_sig = b'PE\x00\x00'
coff = struct.pack('<HHIIIHH', 0x14C, 1, 0, 0, 0, 0xE0, 0x2102)
# optional header (224 bytes)
opt = struct.pack('<H', 0x10B)
opt += struct.pack('<BB', 0, 0)          # linkerver
opt += struct.pack('<III', 0x200, 0x200, 0)  # code/data/bss size-ish
opt += struct.pack('<I', 0)              # addressofentrypoint
opt += struct.pack('<I', 0x2000)         # baseofcode
opt += struct.pack('<I', 0x2000)         # baseofdata
opt += struct.pack('<I', 0x400000)       # imagebase
opt += struct.pack('<I', 0x2000)         # sectionalignment
opt += struct.pack('<I', 0x200)          # filealignment
opt += struct.pack('<HHHHHH', 4, 0, 0, 0, 4, 0)  # os/img/subsys ver
opt += struct.pack('<I', 0)              # win32ver
size_image = 0x2000 + ((len(text_content) + 0x1FFF) // 0x2000) * 0x2000
opt += struct.pack('<II', size_image, 0x200)  # sizeimage, sizeheaders
opt += struct.pack('<I', 0)              # checksum
opt += struct.pack('<H', 3)              # subsystem console
opt += struct.pack('<H', 0x8140)         # dllcharacteristics
opt += struct.pack('<IIIIII', 0x100000, 0x1000, 0x100000, 0x1000, 0, 16)
# 16 directories
for i in range(16):
    if i == 14:  # CLI
        opt += struct.pack('<II', rva_text, len(text_content))
    else:
        opt += struct.pack('<II', 0, 0)
assert len(opt) == 224, len(opt)
# section header .text
raw_size = ((len(text_content) + 0x1FF) // 0x200) * 0x200
sechdr = b'.text\x00\x00\x00' + struct.pack('<IIIIIIHHI', len(text_content), rva_text,
           raw_size, 0x200, 0, 0, 0, 0, 0x60000020)
pe = dos + b'\x00' * (e_lfanew - len(dos)) + pe_sig + coff + opt + sechdr
while len(pe) < 0x200:
    pe += b'\x00'
pe += text_content
while len(pe) < 0x200 + raw_size:
    pe += b'\x00'

open('Assembly-CSharp.dll', 'wb').write(pe)
print(f"wrote Assembly-CSharp.dll ({len(pe)} bytes), #Strings={len(str_heap)}, #Blob={len(blob_heap)}")
