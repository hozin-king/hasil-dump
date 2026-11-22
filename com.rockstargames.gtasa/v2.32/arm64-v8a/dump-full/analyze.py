#!/usr/bin/env python3
"""Analisis statis libCheatMenu64_0_v8e4.so — semua dari file itu sendiri.
Membaca: strings_offsets.txt, 4 file disasm, dynsym, readelf.
Output: beberapa file analisis di folder yang sama.
"""
import re, os, json, collections

D = os.path.dirname(os.path.abspath(__file__))
F = os.path.expanduser("~/workspace/user/files/libCheatMenu64_0_v8e4.so")
data = open(F, "rb").read()

# ---------- string map dari strings -t x (addr hex -> string) ----------
strmap = {}   # vaddr -> string
with open(os.path.join(D, "strings_offsets.txt"), encoding="utf-8", errors="replace") as fh:
    for line in fh:
        parts = line.strip().split(None, 1)
        if len(parts) == 2:
            try:
                addr = int(parts[0], 16)
            except ValueError:
                continue
            strmap[addr] = parts[1]

def read_cstr(vaddr):
    """Baca string C di vaddr (khusus .rodata: vaddr == offset file)."""
    if vaddr < 0x2dac0 or vaddr >= 0x2dac0 + 0x3cb24:
        return None
    off = vaddr
    end = data.find(b"\x00", off)
    if end < 0:
        return None
    try:
        return data[off:end].decode("utf-8", "replace")
    except Exception:
        return None

# ---------- 1. URL / domain / IP ----------
urls = sorted({s for s in strmap.values() if re.match(r"https?://", s)})
domains = sorted({s for s in strmap.values()
                  if re.match(r"^[a-z0-9.-]+\.[a-z]{2,}$", s) and " " not in s and not s.startswith("http")})
ips = sorted({s for s in strmap.values()
              if re.match(r"^\d{1,3}(\.\d{1,3}){3}(:\d+)?$", s)})
with open(os.path.join(D, "analysis_urls.txt"), "w") as fh:
    fh.write("== URL ==\n" + "\n".join(urls) + "\n\n== DOMAIN (tanpa skema) ==\n" + "\n".join(domains) +
             "\n\n== ALAMAT IP literal ==\n" + ("\n".join(ips) if ips else "(tidak ada)") + "\n")

# ---------- 2. file data game, toml, bahasa, path ----------
dat_files = sorted({s for s in strmap.values() if s.endswith(".dat")})
toml_refs = sorted({s for s in strmap.values() if ".toml" in s})
lang_refs = sorted({s for s in strmap.values()
                    if re.search(r"(language|lang|locale|English|Indonesia)", s, re.I)})
paths = sorted({s for s in strmap.values()
                if "/" in s and re.search(r"(ARM|CheatMenu|gtasa|data|sdcard|Android|storage)", s)})
with open(os.path.join(D, "analysis_files_paths.txt"), "w") as fh:
    fh.write("== FILE *.dat ==\n" + "\n".join(dat_files) +
             "\n\n== REFERENSI .toml ==\n" + "\n".join(toml_refs) +
             "\n\n== REFERENSI BAHASA ==\n" + "\n".join(lang_refs) +
             "\n\n== PATH / DIREKTORI ==\n" + "\n".join(paths) + "\n")

# ---------- 3. string error / versi ----------
ver_strs = sorted({s for s in strmap.values()
                   if re.search(r"(v?\d+\.\d+|version|Version|WIP|Cheat Menu)", s)})
err_strs = sorted({s for s in strmap.values()
                   if re.search(r"(fail|error|Error|not |too old|invalid|denied|warning|Warning|crash|missing|unable|can.?t|couldn)", s, re.I)
                   and len(s) < 160})
with open(os.path.join(D, "analysis_versions_errors.txt"), "w") as fh:
    fh.write("== STRING VERSI / IDENTITAS ==\n" + "\n".join(ver_strs) +
             "\n\n== STRING ERROR / PERINGATAN ==\n" + "\n".join(err_strs) + "\n")

# ---------- 4. indikator anti-root / anti-debug / anti-tamper ----------
KEYWORDS = ["root", "magisk", "supersu", "su ", "/su", "frida", "xposed", "substrate",
            "ptrace", "debug", "tamper", "emulator", "signature", "checksum", "integrity",
            "verify", "hook detect", "jailbreak", "safetynet", "play integrity", "attest",
            "isDebugger", "tracer", "/proc/self", "maps", "bypass"]
hits = {}
for s in strmap.values():
    ls = s.lower()
    for k in KEYWORDS:
        if k.lower() in ls:
            hits.setdefault(k, []).append(s)
with open(os.path.join(D, "analysis_antitamper.txt"), "w") as fh:
    for k in sorted(hits):
        fh.write(f"--- keyword: {k} ({len(hits[k])} string) ---\n")
        for s in sorted(set(hits[k]))[:30]:
            fh.write("  " + s + "\n")
    if not hits:
        fh.write("(tidak ada string yang cocok dengan kata kunci anti-root/anti-debug/anti-tamper)\n")

# ---------- 5. kata Indonesia ----------
ID_WORDS = ["saya", "kamu", "anda", "selamat", "terima kasih", "tolong", "jangan",
            "misi", "uang", "kesehatan", "senjata", "kendaraan", "pemain", "bahasa"]
id_hits = sorted({s for s in strmap.values()
                  if any(re.search(r"\b" + w + r"\b", s, re.I) for w in ID_WORDS)})
with open(os.path.join(D, "analysis_indonesian.txt"), "w") as fh:
    fh.write("\n".join(id_hits) if id_hits else "(tidak ada string berbahasa Indonesia yang terdeteksi)\n")

# ---------- 6. kunci CamelCase + pengelompokan per tab ----------
# Tab = string yang berakhiran Tab / TabBar / Page, dari .rodata (urut alamat).
tab_addrs = sorted(a for a, s in strmap.items()
                   if re.match(r"^[A-Z][A-Za-z0-9]*(Tab|TabBar|Page)$", s))
tabs = [(a, strmap[a]) for a in tab_addrs]
camel_re = re.compile(r"^[A-Z][A-Za-z0-9]{2,}$")
keys = {}
for a, s in strmap.items():
    if camel_re.match(s) and s not in ("CheatMenu",):
        keys[a] = s
# tetapkan tiap kunci ke tab terdekat sebelumnya (berdasar alamat .rodata)
grouped = collections.defaultdict(list)
unassigned = []
for a in sorted(keys):
    prev = None
    for ta, tn in tabs:
        if ta <= a:
            prev = tn
        else:
            break
    if prev:
        grouped[prev].append(keys[a])
    else:
        unassigned.append(keys[a])
with open(os.path.join(D, "analysis_feature_keys_by_tab.txt"), "w") as fh:
    fh.write("== DAFTAR TAB (urut alamat .rodata) ==\n")
    for a, tn in tabs:
        fh.write(f"  0x{a:x} {tn}\n")
    fh.write(f"\nTotal tab: {len(tabs)} | Total kunci CamelCase: {len(keys)}\n")
    for tn in sorted(grouped, key=lambda t: -len(grouped[t])):
        fh.write(f"\n== {tn} ({len(grouped[tn])} kunci) ==\n")
        fh.write(", ".join(sorted(set(grouped[tn]))) + "\n")
    fh.write(f"\n== TANPA TAB (sebelum tab pertama, {len(unassigned)} kunci) ==\n")
    fh.write(", ".join(sorted(set(unassigned))) + "\n")
json.dump({"tabs": [t for _, t in tabs],
           "counts": {t: len(set(v)) for t, v in grouped.items()},
           "total_keys": len(keys),
           "unassigned": len(unassigned)},
          open(os.path.join(D, "analysis_feature_keys_summary.json"), "w"), indent=1)

# ---------- 7. xref string + pemanggilan PLT di 4 fungsi ----------
def analyze_disasm(fname):
    """Kembalikan daftar (addr, instr, detail): string-xref via adrp+add,
    dan pemanggilan bl (target + nama PLT bila ada)."""
    adrp = {}   # reg -> (page, instr_addr)
    out = []
    with open(os.path.join(D, fname), encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = re.match(r"\s*([0-9a-f]+):\s+[0-9a-f ]+\s+(\S+)\s*(.*)", line)
            if not m:
                continue
            addr = int(m.group(1), 16)
            op = m.group(2)
            rest = m.group(3).strip()
            if op == "adrp":
                mm = re.match(r"(x\d+),\s*0x([0-9a-f]+)", rest)
                if mm:
                    adrp[mm.group(1)] = int(mm.group(2), 16)
            elif op == "add":
                mm = re.match(r"(x\d+),\s*(x\d+),\s*#0x([0-9a-f]+)", rest)
                if mm and mm.group(2) in adrp:
                    tgt = adrp[mm.group(2)] + int(mm.group(3), 16)
                    s = read_cstr(tgt)
                    if s:
                        out.append((addr, "STR", f"{mm.group(1)} = 0x{tgt:x}  \"{s}\""))
            elif op in ("bl", "b"):
                mm = re.match(r"0x([0-9a-f]+)(?:\s+<([^>]+)>)?", rest)
                if mm:
                    tgt = int(mm.group(1), 16)
                    name = mm.group(2) or ""
                    out.append((addr, "CALL" if op == "bl" else "JMP",
                                f"0x{tgt:x}" + (f" <{name}>" if name else "")))
    return out

for fname, oname in [
    ("disasm_OnModPreLoad.txt", "analysis_xref_OnModPreLoad.txt"),
    ("disasm_OnModLoad.txt", "analysis_xref_OnModLoad.txt"),
    ("disasm_OnAllModsLoaded.txt", "analysis_xref_OnAllModsLoaded.txt"),
    ("disasm_GetModInfo.txt", "analysis_xref_GetModInfo.txt"),
]:
    res = analyze_disasm(fname)
    with open(os.path.join(D, oname), "w") as fh:
        for addr, kind, detail in res:
            fh.write(f"0x{addr:x}  {kind:4} {detail}\n")
    print(fname, "->", len(res), "xref/call")

print("tabs:", len(tabs), "| camel keys:", len(keys))
print("urls:", len(urls), "| dat:", len(dat_files), "| toml:", len(toml_refs))
print("DONE")
