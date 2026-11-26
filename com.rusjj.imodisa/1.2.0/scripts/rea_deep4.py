"""Dump b/f0 methods (esp. e - token check), b/g0, and WorkspaceActivity O0 tail."""
import re
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

a, d, dx = AnalyzeAPK("apks_split/base.apk")
DEX = d[0]
OUT = open("dump/rea_deep4.txt", "w")

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

def show_class(cls_name, max_ins=300):
    for cl in DEX.get_classes():
        if cl.get_name() != cls_name:
            continue
        w(f"### CLASS {cls_name} super={cl.get_superclassname()}")
        for f in cl.get_fields():
            w(f"  FIELD {f.get_name()} : {f.get_descriptor()} {f.get_access_flags_string()}")
        for m in cl.get_methods():
            w(f"  METHOD {m.get_name()}{m.get_descriptor()} {m.get_access_flags_string()}")
        w()
        for m in cl.get_methods():
            code = m.get_code()
            if code is None:
                w(f"### {cls_name}::{m.get_name()} [no code]")
                continue
            w(f"### {cls_name}::{m.get_name()}{m.get_descriptor()}")
            ins = list(code.get_bc().get_instructions())
            for i, x in enumerate(ins[:max_ins]):
                w(f"    {i:4d} {x.get_name():28s} {x.get_output()}")
            if len(ins) > max_ins:
                w(f"    ... ({len(ins)-max_ins} more, total {len(ins)})")
            ss = method_strings(m)
            if ss:
                w(f"    [const-strings: {ss}]")
            w()

show_class("Lb/f0;")
show_class("Lb/g0;")
OUT.close()
print("WROTE dump/rea_deep4.txt")
