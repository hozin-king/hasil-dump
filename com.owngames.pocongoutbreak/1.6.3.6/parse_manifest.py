import sys
from loguru import logger
logger.remove()
from androguard.core.apk import APK
from androguard.core.dex import DEX

a = APK('extract/xapk/com.owngames.pocongoutbreak.apk')
out = []
out.append('package: ' + str(a.get_package()))
out.append('versionName: ' + str(a.get_androidversion_name()))
out.append('versionCode: ' + str(a.get_androidversion_code()))
out.append('minSdk: ' + str(a.get_min_sdk_version()))
out.append('targetSdk: ' + str(a.get_target_sdk_version()))
out.append('main activity: ' + str(a.get_main_activity()))
out.append('activities:')
for x in a.get_activities():
    out.append('  ' + str(x))
out.append('services:')
for x in a.get_services():
    out.append('  ' + str(x))
out.append('receivers:')
for x in a.get_receivers():
    out.append('  ' + str(x))
out.append('providers:')
for x in a.get_providers():
    out.append('  ' + str(x))
out.append('permissions:')
for x in a.get_permissions():
    out.append('  ' + str(x))
out.append('features:')
for x in a.get_features():
    out.append('  ' + str(x))
out.append('dex files: ' + str(a.get_dex()))
out.append('is signed v1: ' + str(a.is_signed_v1()))
out.append('is signed v2: ' + str(a.is_signed_v2()))
out.append('is signed v3: ' + str(a.is_signed_v3()))
# cert fingerprint
try:
    certs = a.get_certificates()
    for c in certs:
        out.append('cert sha256: ' + str(c.sha256_fingerprint))
        out.append('cert subject: ' + str(c.subject))
        out.append('cert issuer: ' + str(c.issuer))
except Exception as e:
    out.append('cert error: ' + repr(e))
open('manifest.txt', 'w').write('\n'.join(out) + '\n')
print('manifest.txt written,', len(out), 'lines')

# dex classes
d = DEX(a.get_dex()[0] if isinstance(a.get_dex(), list) else a.get_dex())
classes = sorted(d.get_classes_names())
open('dex-classes.txt', 'w').write('\n'.join(classes) + '\n')
print('dex-classes.txt written,', len(classes), 'classes')
# count by top package
from collections import Counter
tops = Counter()
for c in classes:
    parts = c.strip('L').split('/')
    tops[parts[0] if parts else '?'] += 1
print('top packages:', tops.most_common(25))
# owngames classes
own = [c for c in classes if 'owngames' in c.lower() or 'pocong' in c.lower()]
print('owngames/pocong classes:', len(own))
for c in own:
    print('  ', c)
