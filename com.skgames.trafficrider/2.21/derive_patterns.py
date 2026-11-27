#!/usr/bin/env python3
"""Derive update-resistant byte patterns for Traffic Rider 2.21 (code 1010).

Reads the first 32 bytes (prologue) of each hook target from libil2cpp.so
2.21 and verifies each pattern occurs EXACTLY ONCE in the executable
segment. If 32 bytes are not unique, the length grows (36/40/48) until
unique. Output: patterns_v221.h (C arrays, injector style) + manifest JSON.

Why this exists: the injector's v2.20/v2.11 32-byte patterns score 0 hits
in 2.21 (13 of 14 dead) because the 2.20 -> 2.21 update moved all code
(+0x98/+0xA4 game code, +0x158 Unity engine code), changing the ADRP
immediates inside every prologue. The primary IL2CPP name resolution
still works, but the pattern fallback is dead; the anti-kick patch has
no pattern fallback at all (hardcoded BL word 0x9400FF4C -> 0x9400FF4F
in 2.21), which is why anti-kick skor fails on device.

Usage: python3 derive_patterns.py
Input: libil2cpp.so 2.21 in extract/lib/arm64-v8a/ (VA == file offset + 0x4000
for the R E segment).
"""
import json, struct

LIB = 'extract/lib/arm64-v8a/libil2cpp.so'
EXEC_OFF, EXEC_SIZE, EXEC_VA = 0x181e4c0, 0x23fde70, 0x18224c0

TARGETS = [
    # (name, RVA 2.21, note)
    ('TR_PATTERN_CRASH_V221',        0x1c6c720, 'MotorMover.Crash() — god mode'),
    ('TR_PATTERN_TRIGGER_V221',      0x1c6d8e8, 'MotorMover.OnTriggerEnter(Collider) — noclip'),
    ('TR_PATTERN_SPEED_V221',        0x1c6c1a0, 'MotorMover.HandleSpeed() — speed multiplier'),
    ('TR_PATTERN_MM_FIXEDUPDATE_V221', 0x1c6a644, 'MotorMover.FixedUpdate() — barrier scan host'),
    ('TR_PATTERN_MM_UPDATE_V221',    0x1c6cbcc, 'MotorMover.Update()'),
    ('TR_PATTERN_OFFROAD_SHAKE_V221', 0x1c6cc94, 'MotorMover.HandleOffroadShake() — offroad shake bypass'),
    ('TR_PATTERN_TM_FIXEDUPDATE_V221', 0x1c82708, 'TrafficManager.FixedUpdate() — ESP instance capture'),
    ('TR_PATTERN_GM_FIXEDUPDATE_V221', 0x1c46f58, 'GameManager.FixedUpdate() — limiter + score-kick host'),
    ('TR_PATTERN_CAM_LATE_V221',     0x1c3e694, 'CameraMover.LateUpdate() — camera offset'),
    ('TR_PATTERN_GETPOS_V221',       0x3960754, 'Transform.get_position()'),
    ('TR_PATTERN_SETPOS_V221',       0x3960828, 'Transform.set_position(Vector3)'),
    ('TR_PATTERN_CAM_MAIN_V221',     0x3907258, 'Camera.get_main()'),
    ('TR_PATTERN_W2S_V221',          0x3906fc8, 'Camera.WorldToScreenPoint(Vector3) 1-arg'),
    ('TR_PATTERN_SCRW_V221',         0x3911278, 'Screen.get_width()'),
    ('TR_PATTERN_SCRH_V221',         0x39112a0, 'Screen.get_height()'),
    ('TR_PATTERN_GETNAME_V221',      0x3955d04, 'Object.get_name()'),
    ('TR_PATTERN_BOX_CENTER_V221',   0x39bbecc, 'BoxCollider.get_center()'),
    ('TR_PATTERN_BOX_SIZE_V221',     0x39bc07c, 'BoxCollider.get_size()'),
]

def va2off(va):
    return va - EXEC_VA + EXEC_OFF

def main():
    d = open(LIB, 'rb').read()
    seg = d[EXEC_OFF:EXEC_OFF + EXEC_SIZE]
    results = []
    for name, rva, note in TARGETS:
        off = va2off(rva)
        for length in (32, 36, 40, 48, 64):
            pat = d[off:off + length]
            hits = []
            st = 0
            while True:
                j = seg.find(pat, st)
                if j < 0:
                    break
                hits.append(EXEC_VA + j)
                st = j + 1
                if len(hits) > 1:
                    break
            if len(hits) == 1 and hits[0] == rva:
                results.append(dict(name=name, rva=hex(rva), length=length,
                                    pattern=pat.hex(), hits=1, note=note))
                print(f'{name:32s} RVA 0x{rva:x} len={length} UNIQUE')
                break
        else:
            results.append(dict(name=name, rva=hex(rva), length=None,
                                pattern=None, hits=len(hits), note=note + ' [NOT UNIQUE]'))
            print(f'{name:32s} RVA 0x{rva:x} NOT UNIQUE (hits={hits})')
    # patch words (verified by capstone disassembly of GameManager.FixedUpdate 2.21)
    patches = {
        'TR_LIMIT_500_WORD_V221':   {'word': '0x52A87F48', 'offset_in_fixedupdate': '0x448',
                                     'note': 'mov w8, #500.0f at GameManager.FixedUpdate+0x448 — UNCHANGED vs v2.20'},
        'TR_SCORE_KICK_BL_WORD_V221': {'word': '0x9400FF4F', 'offset_in_fixedupdate': '0xFC',
                                     'note': 'bl LoadMenuScene (0x1c86d90) at GameManager.FixedUpdate+0xFC — v2.20 word was 0x9400FF4C; displacement grew 12 bytes'},
        'TR_SPEED_KICK_BL_WORD_V221': {'word': '0x9400FE6F', 'offset_in_fixedupdate': '0x47C',
                                     'note': 'bl LoadMenuScene at GameManager.FixedUpdate+0x47C (500 km/h limiter kick)'},
        'TR_NOP_WORD': {'word': '0xD503201F', 'offset_in_fixedupdate': None,
                        'note': 'NOP replacement for either kick BL'},
    }
    with open('patterns_v221.json', 'w') as f:
        json.dump({'targets': results, 'patch_words': patches}, f, indent=1)
    with open('patterns_v221.h', 'w') as f:
        f.write('// Traffic Rider 2.21 (code 1010) — byte patterns + patch words.\n')
        f.write('// Derived by derive_patterns.py from libil2cpp.so 2.21; every pattern\n')
        f.write('// verified EXACTLY ONCE in the executable segment (see patterns_v221.json).\n')
        f.write('// 2.20/2.11 patterns are DEAD in 2.21 (0 hits, 13 of 14) — do not reuse.\n')
        f.write('#pragma once\n#include <stdint.h>\n#include <stddef.h>\n\n')
        for r in results:
            if not r['pattern']:
                f.write(f"// {r['name']}: NO UNIQUE PATTERN (hits={r['hits']}) — {r['note']}\n")
                continue
            b = bytes.fromhex(r['pattern'])
            f.write(f"// {r['note']} — RVA {r['rva']}, {r['length']} bytes, unique\n")
            f.write(f"#define {r['name']}_RVA {r['rva']}\n")
            f.write(f"static const uint8_t {r['name']}[{len(b)}] = {{\n")
            for i in range(0, len(b), 8):
                f.write('    ' + ', '.join(f'0x{x:02x}' for x in b[i:i+8]) + ',\n')
            f.write('};\n\n')
        f.write('// ---- GameManager.FixedUpdate patch words (2.21) ----\n')
        for k, v in patches.items():
            f.write(f"// {v['note']}\n#define {k} {v['word']}u\n")
    print('wrote patterns_v221.json + patterns_v221.h')

if __name__ == '__main__':
    main()
