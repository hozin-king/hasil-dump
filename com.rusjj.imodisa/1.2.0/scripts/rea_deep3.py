"""Dump b/z methods a/b/c, WorkspaceActivity server method, AssistantService onStartCommand."""
import re
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

a, d, dx = AnalyzeAPK("apks_split/base.apk")
DEX = d[0]
OUT = open("dump/rea_deep3.txt", "w")

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

def show_method(cls_name, meth_name, max_ins=250):
    for cl in DEX.get_classes():
        if cl.get_name() != cls_name:
            continue
        for m in cl.get_methods():
            if m.get_name() != meth_name:
                continue
            w(f"### {cls_name}::{m.get_name()}{m.get_descriptor()} access={m.get_access_flags_string()}")
            code = m.get_code()
            if code is None:
                w("[no code]")
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

for mn in ["a", "b", "c"]:
    show_method("Lb/z;", mn, max_ins=300)

# WorkspaceActivity: find method using ServerSocket
for cl in DEX.get_classes():
    if cl.get_name() != "Lcom/rusjj/imodisa/ui/WorkspaceActivity;":
        continue
    for m in cl.get_methods():
        code = m.get_code()
        if code is None:
            continue
        if any("ServerSocket" in x.get_output() for x in code.get_bc().get_instructions()):
            w(f"### WorkspaceActivity::{m.get_name()}{m.get_descriptor()} [uses ServerSocket]")
            ins = list(code.get_bc().get_instructions())
            for i, x in enumerate(ins[:200]):
                w(f"    {i:4d} {x.get_name():28s} {x.get_output()}")
            ss = method_strings(m)
            if ss:
                w(f"    [const-strings: {ss}]")
            w()

# AssistantService onStartCommand
show_method("Lcom/rusjj/imodisa/ui/AssistantService;", "onStartCommand", max_ins=200)

# b/a - MCP client handler (per-connection thread)
for cl in DEX.get_classes():
    if cl.get_name() != "Lb/a;":
        continue
    w("### CLASS Lb/a; (mcp-client runnable)")
    for f in cl.get_fields():
        w(f"  FIELD {f.get_name()} : {f.get_descriptor()}")
    for m in cl.get_methods():
        w(f"  METHOD {m.get_name()}{m.get_descriptor()}")
    for m in cl.get_methods():
        if m.get_name() == "run":
            code = m.get_code()
            if code is None:
                continue
            w(f"### Lb/a;::run")
            ins = list(code.get_bc().get_instructions())
            for i, x in enumerate(ins[:250]):
                w(f"    {i:4d} {x.get_name():28s} {x.get_output()}")
            ss = method_strings(m)
            if ss:
                w(f"    [const-strings: {ss}]")
            w()
OUT.close()
print("WROTE dump/rea_deep3.txt")
