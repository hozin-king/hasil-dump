"""Dex summary + dump lists for imodisa base.apk (androguard 4.1.4)."""
import os, json
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

APK = "apks_split/base.apk"
DUMP = "dump"
os.makedirs(DUMP, exist_ok=True)

a, d, dx = AnalyzeAPK(APK)
print("package:", a.get_package(), a.get_androidversion_name(), a.get_androidversion_code())

# --- dex files ---
dexes = d if isinstance(d, list) else [d]
print("dex count:", len(dexes))
summary = {"dex_count": len(dexes), "dex": []}
all_strings, all_classes, all_methods, all_fields = [], [], [], []
app_classes = []
for i, dd in enumerate(dexes):
    s = dd.get_strings()
    t = []
    m = dd.get_methods()
    f = dd.get_fields()
    c = dd.get_classes()
    summary["dex"].append({
        "index": i,
        "size_bytes": os.path.getsize(APK) if i == 0 else None,
        "dex_file_size": dd.get_length() if hasattr(dd, 'get_length') else None,
        "strings": len(s), "types": len(t), "methods": len(m),
        "fields": len(f), "classes": len(c),
        "dex_version": dd.get_format_type() if hasattr(dd, 'get_format_type') else None,
    })
    all_strings.extend(s)
    all_classes.extend(c)
    all_methods.extend(m)
    all_fields.extend(f)
    for cl in c:
        name = cl.get_name()
        if name.startswith("Lcom/rusjj/"):
            app_classes.append(name)

# strings.txt
with open(f"{DUMP}/strings.txt", "w", errors="replace") as fh:
    for s in sorted(set(all_strings)):
        fh.write(s + "\n")

# classes.txt
with open(f"{DUMP}/classes.txt", "w") as fh:
    for cl in sorted(set(c.get_name() for c in all_classes)):
        fh.write(cl + "\n")

# methods.txt
with open(f"{DUMP}/methods.txt", "w") as fh:
    for m in sorted(set(f"{m.get_class_name()}->{m.get_name()}{m.get_descriptor()}" for m in all_methods)):
        fh.write(m + "\n")

# fields.txt
with open(f"{DUMP}/fields.txt", "w") as fh:
    for fl in sorted(set(f"{fl.get_class_name()}->{fl.get_name()}:{fl.get_descriptor()}" for fl in all_fields)):
        fh.write(fl + "\n")

# app_classes.txt
with open(f"{DUMP}/app_classes.txt", "w") as fh:
    for c in sorted(set(app_classes)):
        fh.write(c + "\n")

summary["total_strings"] = len(set(all_strings))
summary["total_methods"] = len(all_methods)
summary["total_fields"] = len(all_fields)
summary["total_classes"] = len(all_classes)
summary["app_classes_count"] = len(set(app_classes))
summary["app_classes"] = sorted(set(app_classes))
json.dump(summary, open(f"{DUMP}/dex_summary.json", "w"), indent=2)
print(json.dumps({k: v for k, v in summary.items() if k != "app_classes"}, indent=2))
print("app classes:")
for c in sorted(set(app_classes)):
    print("  ", c)

# apk-info.txt
with open(f"{DUMP}/apk-info.txt", "w") as fh:
    fh.write(f"package: {a.get_package()}\n")
    fh.write(f"versionName: {a.get_androidversion_name()}\n")
    fh.write(f"versionCode: {a.get_androidversion_code()}\n")
    fh.write(f"minSdk: {a.get_min_sdk_version()} targetSdk: {a.get_target_sdk_version()}\n")
    fh.write(f"appName: {a.get_app_name()}\n")
    fh.write(f"mainActivity: {a.get_main_activity()}\n")
    fh.write(f"activities: {a.get_activities()}\n")
    fh.write(f"services: {a.get_services()}\n")
    fh.write(f"receivers: {a.get_receivers()}\n")
    fh.write(f"providers: {a.get_providers()}\n")
    fh.write(f"permissions: {a.get_permissions()}\n")
    fh.write(f"signed v1/v2/v3: {a.is_signed_v1()} {a.is_signed_v2()} {a.is_signed_v3()}\n")
    for c in a.get_certificates():
        fh.write(f"cert subject: {c.subject.human_friendly}\n")
        fh.write(f"cert issuer: {c.issuer.human_friendly}\n")
        fh.write(f"cert serial: {c.serial_number}\n")
        fh.write(f"cert valid: {c.not_valid_before} -> {c.not_valid_after}\n")
        fh.write(f"cert sha256: {c.sha256_fingerprint}\n")
        fh.write(f"cert sha1: {c.sha1_fingerprint}\n")
    fh.write(f"dex files: {a.get_dex()}\n")
    fh.write(f"files: {len(a.get_files())}\n")

# file-list.txt (all three splits)
with open(f"{DUMP}/file-list.txt", "w") as fh:
    for split, path in [("base.apk", "apks_split/base.apk"),
                        ("split_config.arm64_v8a.apk", "apks_split/split_config.arm64_v8a.apk"),
                        ("split_config.in.apk", "apks_split/split_config.in.apk")]:
        aa, _, _ = AnalyzeAPK(path)
        fh.write(f"### {split}\n")
        for f in sorted(aa.get_files()):
            fh.write(f + "\n")

# manifest.xmltree.txt via aapt if available else androguard xml
import subprocess
for split, path in [("base", "apks_split/base.apk"),
                    ("arm64", "apks_split/split_config.arm64_v8a.apk"),
                    ("in", "apks_split/split_config.in.apk")]:
    aa, _, _ = AnalyzeAPK(path)
    xml = aa.get_android_manifest_xml()
    with open(f"{DUMP}/manifest_{split}.xmltree.txt", "w") as fh:
        fh.write(xml.toxml() if hasattr(xml, 'toxml') else str(xml))
    # resources
    try:
        res = aa.get_android_resources()
        with open(f"{DUMP}/resources_{split}.txt", "w") as fh:
            fh.write(str(res))
    except Exception as e:
        with open(f"{DUMP}/resources_{split}.txt", "w") as fh:
            fh.write(f"ERR {e}\n")
print("DONE")
