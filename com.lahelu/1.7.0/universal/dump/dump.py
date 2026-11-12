#!/usr/bin/env python3
"""Dump total class/method/field dari classes.dex + classes2.dex Lahelu."""
import os, sys, json
from collections import Counter

from androguard.core.dex import DEX

D = os.path.dirname(os.path.abspath(__file__))

all_classes = []
all_methods = []   # (class, name, descriptor)
all_fields = []    # (class, name, type)
total_methods = total_fields = 0
dex_sizes = {}

for fn in ("classes.dex", "classes2.dex"):
    p = os.path.join(D, fn)
    if not os.path.exists(p):
        continue
    dex_sizes[fn] = os.path.getsize(p)
    print(f"[+] parsing {fn} ({dex_sizes[fn]} bytes)...", flush=True)
    with open(p, "rb") as fh:
        d = DEX(fh.read())
    for cls in d.get_classes():
        cname = cls.get_name()  # Lpkg/name;
        all_classes.append(cname)
        for m in cls.get_methods():
            total_methods += 1
            all_methods.append((cname, m.get_name(), m.get_descriptor()))
        for f in cls.get_fields():
            total_fields += 1
            all_fields.append((cname, f.get_name(), f.get_descriptor()))

print(f"classes: {len(all_classes)}, methods: {total_methods}, fields: {total_fields}")

with open(os.path.join(D, "classes.txt"), "w") as f:
    for c in sorted(all_classes):
        f.write(c + "\n")

with open(os.path.join(D, "methods.txt"), "w") as f:
    for c, n, desc in sorted(all_methods):
        f.write(f"{c} {n}{desc}\n")

# top 20 packages by class count
def pkg_of(cname):
    # Lpkg/sub/name; -> pkg.sub
    s = cname[1:].rsplit("/", 1)[0] if "/" in cname else ""
    parts = s.split("/")
    return ".".join(parts[:3]) if parts else "(default)"

pkgs = Counter(pkg_of(c) for c in all_classes)
top20 = pkgs.most_common(20)

summary = {
    "dex_sizes": dex_sizes,
    "total_classes": len(all_classes),
    "total_methods": total_methods,
    "total_fields": total_fields,
    "top20_packages": [{"package": p, "classes": n} for p, n in top20],
}
with open(os.path.join(D, "summary.json"), "w") as f:
    json.dump(summary, f, indent=2)

print(json.dumps(summary, indent=2))
