#!/usr/bin/env python3
"""Verifikasi (namespace, class, method) hook modul terhadap metadata v31."""
import struct, sys

data = open(sys.argv[1], 'rb').read()
hdr = struct.unpack('<74I', data[:296])
STR_OFF, STR_SZ = hdr[6], hdr[7]
MET_OFF, MET_SZ = hdr[12], hdr[13]
TD_OFF, TD_SZ = hdr[40], hdr[41]
TD_SIZE, MET_SIZE, PC_OFF = 88, 40, 38
n_td, n_met = TD_SZ // TD_SIZE, MET_SZ // MET_SIZE

def getstr(idx):
    if idx == 0xFFFFFFFF or idx >= STR_SZ:
        return ''
    end = data.index(b'\x00', STR_OFF + idx)
    return data[STR_OFF + idx:end].decode('utf-8', 'replace')

# method name -> set((ns, class))
method_owners = {}
for i in range(n_td):
    off = TD_OFF + i * TD_SIZE
    name_i, ns_i = struct.unpack('<II', data[off:off+8])
    ns, cname = getstr(ns_i), getstr(name_i)
    mstart = struct.unpack('<i', data[off+36:off+40])[0]
    mc = struct.unpack('<H', data[off+64:off+66])[0]
    if not (0 <= mstart < n_met):
        continue
    for j in range(mc):
        if mstart + j >= n_met:
            break
        moff = MET_OFF + (mstart + j) * MET_SIZE
        mn_i = struct.unpack('<I', data[moff:moff+4])[0]
        mname = getstr(mn_i)
        if mname:
            method_owners.setdefault(mname, set()).add((ns, cname))

hooks = [
    ("COW.GamePlay", "FollowCamera", "get_OffsetForNormal"),
    ("COW", "GameConfig", "get_ResetGuest"),
    ("COW.GamePlay", "Player", "GetCurrentDashSpeed"),
    ("COW.GamePlay", "Player", "get_MaxJumpHeight"),
    ("COW.GamePlay", "Player", "get_CustomGravity"),
    ("COW.GamePlay", "Player", "get_RisingGravity"),
    ("COW.GamePlay", "Player", "get_FallingGravity"),
    ("COW.GamePlay", "Player", "get_HeadCollider"),
]
for ns, cls, meth in hooks:
    owners = method_owners.get(meth, set())
    exact = (ns, cls) in owners
    print(f"[{'OK' if exact else 'GAGAL'}] {ns}.{cls}.{meth}")
    if not exact:
        cow = sorted(o for o in owners if o[0].startswith("COW"))
        if cow:
            print(f"       method ada di: {cow[:8]}")
        else:
            print(f"       method tidak ada di namespace COW* (pemilik lain: {len(owners)})")
