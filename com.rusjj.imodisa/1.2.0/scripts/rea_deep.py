"""Deep REA: disassemble key app classes + PairIP license classes (androguard 4.1.4)."""
import re
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

APK = "apks_split/base.apk"
a, d, dx = AnalyzeAPK(APK)
DEX = d[0] if isinstance(d, list) else d

OUT = open("dump/rea_deep.txt", "w")

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
            if x.get_name() == "const-string":
                mm = re.search(r',\s*"(.*)"\s*$', out)
                if mm:
                    vals.append(mm.group(1))
            elif "const-string" in x.get_name():
                vals.append(out)
    except Exception:
        pass
    return vals

def show_class(cls_name, max_ins=70):
    w("=" * 78)
    w(f"CLASS {cls_name}")
    w("=" * 78)
    found = False
    for cl in DEX.get_classes():
        if cl.get_name() != cls_name:
            continue
        found = True
        w(f"superclass: {cl.get_superclassname()}")
        w(f"interfaces: {cl.get_interfaces()}")
        try:
            w(f"source file: {cl.get_sourcefile()}")
        except Exception:
            pass
        for f in cl.get_fields():
            w(f"  FIELD {f.get_name()} : {f.get_descriptor()}  access={f.get_access_flags_string()}")
        for m in cl.get_methods():
            w(f"  METHOD {m.get_name()}{m.get_descriptor()}  access={m.get_access_flags_string()}")
        w()
        for m in cl.get_methods():
            code = m.get_code()
            if code is None:
                continue
            w(f"--- {cls_name}::{m.get_name()}{m.get_descriptor()} ---")
            ins = list(code.get_bc().get_instructions())
            for i, x in enumerate(ins[:max_ins]):
                w(f"    {i:4d} {x.get_name():28s} {x.get_output()}")
            if len(ins) > max_ins:
                w(f"    ... ({len(ins)-max_ins} more instructions, total {len(ins)})")
            ss = method_strings(m)
            if ss:
                w(f"    [const-strings: {ss[:25]}]")
            w()
    if not found:
        w("[class not found]")

TARGETS = [
    "Lcom/rusjj/imodisa/App;",
    "Lcom/rusjj/imodisa/engine/NativeBridge;",
    "Lcom/rusjj/imodisa/ui/HomeActivity;",
    "Lcom/rusjj/imodisa/ui/DexActivity;",
    "Lcom/rusjj/imodisa/ui/WorkspaceActivity;",
    "Lcom/rusjj/imodisa/ui/SettingsActivity;",
    "Lcom/rusjj/imodisa/ui/AppPickerActivity;",
    "Lcom/rusjj/imodisa/ui/AssistantService;",
    "Lcom/rusjj/imodisa/ui/ExportService;",
    "Lcom/rusjj/imodisa/ui/views/CodeEditText;",
    "Lcom/rusjj/imodisa/ui/Hbz/ntfdfdnxofooegtfzikkztx/vlvypapvwqyvjabwwwrwyrwbmasqj;",
]
for t in TARGETS:
    show_class(t)

w("=" * 78)
w("PAIRIP CLASSES (all)")
w("=" * 78)
for cl in DEX.get_classes():
    n = cl.get_name()
    if "pairip" in n.lower():
        w(n)
w()
for t in ["Lcom/pairip/licensecheck/LicenseClient;",
          "Lcom/pairip/licensecheck/LicenseActivity;",
          "Lcom/pairip/application/Application;"]:
    show_class(t, max_ins=90)

w("=" * 78)
w("NETWORK / HTTP REFERENCES")
w("=" * 78)
for m in DEX.get_methods():
    cn = m.get_class_name()
    if any(k in cn for k in ["okhttp", "retrofit", "HttpURLConnection", "cronet", "volley", "java/net/"]):
        w(f"{cn}->{m.get_name()}{m.get_descriptor()}")
w()
w("=== methods referencing AI endpoints ===")
for m in DEX.get_methods():
    for s in method_strings(m):
        if any(k in s for k in ["api.", "openai", "anthropic", "11434", "1234", "huggingface", "openrouter", "groq", "deepseek", "mistral", "cerebras", "sambanova", "x.ai", "nvidia", "github.ai", "generativelanguage"]):
            w(f"{m.get_class_name()}->{m.get_name()}  :: {s!r}")
            break
OUT.close()
print("WROTE dump/rea_deep.txt")
