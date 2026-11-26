"""Dump resolved string resources for base + Indonesian split."""
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

for split in ["base", "in"]:
    path = f"apks_split/{'base.apk' if split=='base' else 'split_config.in.apk'}"
    a, d, dx = AnalyzeAPK(path)
    res = a.get_android_resources()
    strs = res.get_resolved_strings()
    with open(f"dump/resources_{split}.txt", "w") as fh:
        for pkg, table in strs.items():
            fh.write(f"### package {pkg}\n")
            for rid, val in sorted(table.items(), key=lambda kv: str(kv[0])):
                if isinstance(val, dict):
                    for cfg, s in val.items():
                        fh.write(f"{rid} [{cfg}] {s}\n")
                else:
                    fh.write(f"{rid} {val}\n")
    print(split, "packages:", list(strs.keys()), "entries:", sum(len(t) for t in strs.values()))
print("DONE")
