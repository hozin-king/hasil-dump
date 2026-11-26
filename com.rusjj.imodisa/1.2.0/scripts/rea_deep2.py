"""Dump specific classes/methods: b/t0 clinit, local-server classes, AssistantService, WorkspaceActivity key methods."""
import re
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

a, d, dx = AnalyzeAPK("apks_split/base.apk")
DEX = d[0]
OUT = open("dump/rea_deep2.txt", "w")

def w(s=""):
    OUT.write(s + "\n")

def method_strings(m):
    vals = []
    try:
        code = m.get_code()
        if code is None:
            return vals
        for x in code.get_bc().get_instructions():
            out = x.get_output()
            mm = re.search(r'const-string(?:/jumbo)?\s+\w+,\s*"(.*)"', out)
            if mm:
                vals.append(mm.group(1))
    except Exception:
        pass
    return vals

def show_method(cls_name, meth_name, max_ins=200):
    for cl in DEX.get_classes():
        if cl.get_name() != cls_name:
            continue
        for m in cl.get_methods():
            if m.get_name() != meth_name:
                continue
            w(f"### {cls_name}::{m.get_name()}{m.get_descriptor()} access={m.get_access_flags_string()}")
            code = m.get_code()
            if code is None:
                w("[no code - abstract/native]")
                return
            ins = list(code.get_bc().get_instructions())
            for i, x in enumerate(ins[:max_ins]):
                w(f"    {i:4d} {x.get_name():28s} {x.get_output()}")
            if len(ins) > max_ins:
                w(f"    ... ({len(ins)-max_ins} more, total {len(ins)})")
            ss = method_strings(m)
            if ss:
                w(f"    [const-strings ({len(ss)}): {ss}]")
            w()
            return
    w(f"[not found {cls_name}::{meth_name}]")

def show_class_overview(cls_name):
    for cl in DEX.get_classes():
        if cl.get_name() != cls_name:
            continue
        w(f"### CLASS {cls_name} super={cl.get_superclassname()} ifaces={cl.get_interfaces()}")
        for f in cl.get_fields():
            w(f"  FIELD {f.get_name()} : {f.get_descriptor()} {f.get_access_flags_string()}")
        for m in cl.get_methods():
            w(f"  METHOD {m.get_name()}{m.get_descriptor()} {m.get_access_flags_string()}")
        w()

# 1. b/t0 - the endpoint preset table
w("=" * 78)
w("b/t0 - endpoint presets")
w("=" * 78)
show_class_overview("Lb/t0;")
show_method("Lb/t0;", "<clinit>", max_ins=400)

# 2. local server classes
for cls in ["Lb/d0;", "Lb/f0;", "Lb/z;"]:
    w("=" * 78)
    w(f"local-server class {cls}")
    w("=" * 78)
    show_class_overview(cls)
    for cl in DEX.get_classes():
        if cl.get_name() != cls:
            continue
        for m in cl.get_methods():
            code = m.get_code()
            if code is None:
                continue
            hit = any("ServerSocket" in x.get_output() for x in code.get_bc().get_instructions())
            if hit:
                show_method(cls, m.get_name(), max_ins=150)

# 3. AssistantService full
w("=" * 78)
w("AssistantService")
w("=" * 78)
show_class_overview("Lcom/rusjj/imodisa/ui/AssistantService;")
for cl in DEX.get_classes():
    if cl.get_name() != "Lcom/rusjj/imodisa/ui/AssistantService;":
        continue
    for m in cl.get_methods():
        show_method("Lcom/rusjj/imodisa/ui/AssistantService;", m.get_name(), max_ins=120)

OUT.close()
print("WROTE dump/rea_deep2.txt")
