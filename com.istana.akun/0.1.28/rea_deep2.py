#!/usr/bin/env python3
"""REA part 2: DeviceInfo, Updater, AccountStore, MainActivity string refs,
signatures, anti-tamper scan."""
import sys
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

APK = "/home/hatch/workspace/user/files/istana-virtual-android-0.1.28_0_gbrk.apk"
a, d, dx = AnalyzeAPK(APK)

print("===== SIGNING =====")
for sig in a.get_signatures():
    print("sig name:", sig)
try:
    for cert in a.get_certificates():
        print("cert subject:", cert.subject.human_friendly if hasattr(cert.subject, "human_friendly") else cert.subject)
        print("cert issuer:", cert.issuer.human_friendly if hasattr(cert.issuer, "human_friendly") else cert.issuer)
        print("cert serial:", cert.serial_number)
        print("cert not_before:", cert.not_valid_before_utc, "not_after:", cert.not_valid_after_utc)
        print("cert sha256 fingerprint:", cert.fingerprint("sha256"))
except Exception as e:
    print("cert error:", e)
print("is_signed:", a.is_signed(), "is_signed_v2:", a.is_signed_v2(), "is_signed_v3:", a.is_signed_v3())

APP = "Lcom/istana/akun/"

def show(cls, name, max_ins=250):
    for m in dx.get_methods():
        mm = m.method
        if mm.get_class_name() == cls and mm.get_name() == name:
            print(f"\n===== {cls}->{name}{mm.get_descriptor()} =====")
            code = mm.get_code()
            if code is None:
                print("  (no code)"); return
            ins = list(code.get_bc().get_instructions())
            print(f"  instructions: {len(ins)}")
            for i, insn in enumerate(ins[:max_ins]):
                print(f"  {i:4d} {insn.get_name():28s} {insn.get_output()}")

show(APP + "DeviceInfo;", "a")
show(APP + "DeviceInfo;", "b")
show(APP + "AccountStore;", "a")
show(APP + "AccountStore;", "b")
show(APP + "AccountStore;", "c")
show(APP + "Updater;", "a")
show(APP + "Updater;", "b")
show(APP + "Updater;", "c")
show(APP + "Updater;", "d")

# MainActivity: list every const-string + interesting invoked APIs per method
print("\n===== MainActivity string refs per method =====")
for m in dx.get_methods():
    mm = m.method
    if mm.get_class_name() != APP + "MainActivity;":
        continue
    code = mm.get_code()
    if code is None:
        continue
    strs = []
    apis = []
    for insn in code.get_bc().get_instructions():
        nm = insn.get_name()
        out = insn.get_output()
        if "const-string" in nm:
            strs.append(out)
        if "invoke" in nm and ("WebView" in out or "addJavascriptInterface" in out or
                                "setJavaScriptEnabled" in out or "evaluateJavascript" in out or
                                "Download" in out or "FileProvider" in out or "getExternal" in out or
                                "Settings" in out or "Cookie" in out or "loadUrl" in out):
            apis.append(out)
    if strs or apis:
        print(f"\n-- {mm.get_name()}{mm.get_descriptor()}")
        for s in strs:
            print(f"   STR {s}")
        for s in apis:
            print(f"   API {s}")

# anti-tamper / root / emulator / pinning scan across all dex strings
print("\n===== protection keyword scan =====")
import re
all_strings = set()
for m in dx.get_strings():
    try:
        all_strings.add(m.get_value())
    except Exception:
        all_strings.add(str(m))
for kw in ["root", "magisk", "su", "supersu", "emulator", "xposed", "frida",
           "certificate", "pinning", "ssl", "debug", "isDebugger", "tamper",
           "verify", "signature", "play integrity", "safetynet"]:
    hits = sorted(s for s in all_strings if kw in s.lower())
    hits = [h for h in hits if len(h) < 120]
    if hits:
        print(f"[{kw}] {len(hits)}: {hits[:12]}")
