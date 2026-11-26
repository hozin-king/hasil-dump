#!/usr/bin/env python3
"""Deep REA of Istana Virtual via androguard: service catalog, crypto,
license flow, updater, WebView bridge, protections."""
import sys
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

APK = "/home/hatch/workspace/user/files/istana-virtual-android-0.1.28_0_gbrk.apk"
OUT = "/home/hatch/workspace/rea-istana-virtual/dump"

a, d, dx = AnalyzeAPK(APK)

def methods_of(cls):
    return [m.method for m in dx.get_methods() if m.method.get_class_name() == cls]

def show_method(m, max_ins=400):
    print(f"\n===== {m.get_class_name()}->{m.get_name()}{m.get_descriptor()} =====")
    code = m.get_code()
    if code is None:
        print("  (no code)")
        return
    ins = list(code.get_bc().get_instructions())
    print(f"  instructions: {len(ins)}")
    for i, insn in enumerate(ins[:max_ins]):
        print(f"  {i:4d} {insn.get_name():28s} {insn.get_output()}")

def strings_of(m):
    code = m.get_code()
    if code is None:
        return []
    out = []
    for insn in code.get_bc().get_instructions():
        o = insn.get_output()
        if "String" in insn.get_name() or "const-string" in insn.get_name():
            out.append(o)
    return out

APP = "Lcom/istana/akun/"

# 1. Services.<clinit> — full disassembly to recover the catalog
for m in methods_of(APP + "Services;"):
    if m.get_name() == "<clinit>":
        show_method(m, 800)

# 2. ServiceCategory enum constants
for m in methods_of(APP + "ServiceCategory;"):
    if m.get_name() == "<clinit>":
        show_method(m, 60)

# 3. CryptoStore — all methods (short)
for m in methods_of(APP + "CryptoStore;"):
    show_method(m, 120)

# 4. LicenseManager — all methods (short)
for m in methods_of(APP + "LicenseManager;"):
    show_method(m, 150)
