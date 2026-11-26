import hashlib, json
from loguru import logger
logger.remove()
from androguard.misc import AnalyzeAPK

out = {}
for name in ["base.apk", "split_config.arm64_v8a.apk", "split_config.in.apk"]:
    p = f"apks_split/{name}"
    a, d, dx = AnalyzeAPK(p)
    info = {}
    info["package"] = a.get_package()
    info["versionName"] = a.get_androidversion_name()
    info["versionCode"] = a.get_androidversion_code()
    info["minSdk"] = a.get_min_sdk_version()
    info["targetSdk"] = a.get_target_sdk_version()
    info["maxSdk"] = a.get_max_sdk_version()
    try:
        info["appName"] = a.get_app_name()
    except Exception as e:
        info["appName"] = f"ERR {e}"
    info["mainActivity"] = a.get_main_activity()
    info["activities"] = a.get_activities()
    info["services"] = a.get_services()
    info["receivers"] = a.get_receivers()
    info["providers"] = a.get_providers()
    info["permissions"] = a.get_permissions()
    info["features"] = a.get_features()
    info["dex"] = a.get_dex()
    info["files"] = a.get_files()
    info["nativeLibs"] = [f for f in a.get_files() if f.startswith("lib/")]
    info["signed_v1"] = a.is_signed_v1()
    info["signed_v2"] = a.is_signed_v2()
    info["signed_v3"] = a.is_signed_v3()
    certs = []
    for c in a.get_certificates():
        certs.append({
            "subject": str(c.subject.human_friendly),
            "issuer": str(c.issuer.human_friendly),
            "serial": str(c.serial_number),
            "not_before": str(c.not_valid_before),
            "not_after": str(c.not_valid_after),
            "sha256": c.sha256_fingerprint if hasattr(c, 'sha256_fingerprint') else hashlib.sha256(c.dump()).hexdigest(),
            "sha1": c.sha1_fingerprint,
        })
    info["certs"] = certs
    # manifest raw xml tree via androguard
    info["manifest_xml"] = a.get_android_manifest_xml().toxml() if hasattr(a.get_android_manifest_xml(), 'toxml') else str(a.get_android_manifest_xml())
    out[name] = info
    print("="*70)
    print("FILE:", name, "| pkg:", info["package"], "| v:", info["versionName"], info["versionCode"])
    print("min/target/max:", info["minSdk"], info["targetSdk"], info["maxSdk"])
    print("appName:", info["appName"], "| main:", info["mainActivity"])
    print("activities:", info["activities"])
    print("services:", info["services"])
    print("receivers:", info["receivers"])
    print("providers:", info["providers"])
    print("permissions:", info["permissions"])
    print("features:", info["features"])
    print("dex:", info["dex"])
    print("nativeLibs:", info["nativeLibs"])
    print("signed v1/v2/v3:", info["signed_v1"], info["signed_v2"], info["signed_v3"])
    for c in certs:
        print("  cert subject:", c["subject"])
        print("  cert issuer:", c["issuer"])
        print("  serial:", c["serial"], "| valid:", c["not_before"], "->", c["not_after"])
        print("  sha256:", c["sha256"])
        print("  sha1:", c["sha1"])

json.dump(out, open("apk_info.json", "w"), indent=2, default=str)
print("\nWROTE apk_info.json")
