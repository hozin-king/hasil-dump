#!/usr/bin/env python3
"""De-obfuscate + dump Free Fire OB53 IL2CPP metadata (v31, XOR 0xE8) — corrected.

Header = pairs (offset, sizeInBytes). String table = null-terminated strings
at `string` section offset; nameIndex = BYTE offset into that data.
TypeDefinition = 88 bytes: 16 int32 + 8 uint16 + bitfield + token.
MethodDefinition = 60 bytes (v31 layout).
"""
import struct, os

SRC = os.path.expanduser("~/workspace/rea-freefire-ob53/extracted/assets/bin/Data/Managed/Metadata/global-metadata.dat")
OUTDIR = os.path.expanduser("~/workspace/rea-freefire-ob53/dump")
os.makedirs(OUTDIR, exist_ok=True)

raw = open(SRC, "rb").read()
dec = bytes(b ^ 0xE8 for b in raw)
open(os.path.join(OUTDIR, "global-metadata.deobfuscated.dat"), "wb").write(dec)

sanity, version = struct.unpack("<II", dec[:8])
assert sanity == 0xFAB11BAF, hex(sanity)
print(f"magic OK, metadata version: {version}, size: {len(dec)}")

PAIRS = ["stringLiteral", "stringLiteralData", "string", "events", "properties", "methods",
         "parameterDefaultValues", "fieldDefaultValues", "fieldAndParameterDefaultValueData",
         "fieldMarshaledSizes", "parameters", "fields", "genericParameters",
         "genericParameterConstraints", "genericContainers", "nestedTypes", "interfaces",
         "vtableMethods", "interfaceOffsets", "typeDefinitions", "images", "assemblies",
         "metadataUsageLists", "metadataUsageTypes", "metadataUsageDictionaries",
         "metadataUsagePairs", "sortedFieldDefinition"]
hdr = {}
off = 8
for n in PAIRS:
    o, s = struct.unpack("<II", dec[off:off+8]); off += 8
    hdr[n] = (o, s)

sbase, ssize = hdr["string"]

def get_string(byte_off):
    if byte_off < 0 or byte_off >= ssize:
        return ""
    end = dec.find(b"\x00", sbase + byte_off)
    if end == -1:
        return ""
    return dec[sbase + byte_off:end].decode("utf-8", "replace")

# ---- Types (88-byte records) ----
TD_SIZE = 88
td_off, td_size = hdr["typeDefinitions"]
td_count = td_size // TD_SIZE
types = []
for i in range(td_count):
    base = td_off + i * TD_SIZE
    vals = struct.unpack("<16i8HII", dec[base:base + TD_SIZE])
    (nameIdx, nsIdx, custAttr, byvalType, byrefType, declaring, parent,
     elemType, genericContainer, flags, fieldStart, methodStart, eventStart,
     propertyStart, nestedStart, interfacesStart,
     method_count, property_count, field_count, event_count, nested_count,
     vtable_count, interfaces_count, iface_offsets_count, bitfield, token) = vals
    types.append({
        "name": get_string(nameIdx), "ns": get_string(nsIdx),
        "methodStart": methodStart, "method_count": method_count,
        "fieldStart": fieldStart, "field_count": field_count,
        "parent": parent, "declaring": declaring, "token": token,
    })

with open(os.path.join(OUTDIR, "types.txt"), "w") as f:
    for t in types:
        full = f"{t['ns']}.{t['name']}" if t['ns'] else t['name']
        f.write(f"{full}  methods={t['method_count']} fields={t['field_count']}\n")
print(f"types: {len(types)}")
print("first 5 types:", [(t['ns'], t['name']) for t in types[:5]])
print("token rids first 10:", [hex(t['token'] & 0xFFFFFF) for t in types[:10]])

# ---- Methods (60-byte records) ----
MD_SIZE = 56
md_off, md_size = hdr["methods"]
md_count = md_size // MD_SIZE
methods = []
for i in range(md_count):
    base = md_off + i * MD_SIZE
    (nameIdx, declType, retType, paramStart, custAttr, genericContainer,
     methodIndex, invokerIndex, delegateWrapperIndex, rgctxStart, rgctxCount,
     token, flags, iflags, slot, paramCount) = struct.unpack("<12IHHHH", dec[base:base + MD_SIZE])
    methods.append((get_string(nameIdx), declType, paramCount))

with open(os.path.join(OUTDIR, "methods.txt"), "w") as f:
    for name, decl, pc in methods:
        t = types[decl] if 0 <= decl < len(types) else None
        tname = (f"{t['ns']}.{t['name']}" if t and t['ns'] else (t['name'] if t else "?"))
        f.write(f"{tname}::{name}  params={pc}\n")
print(f"methods: {len(methods)}")
print("first 10 methods:", [m[0] for m in methods[:10]])

# ---- Images (24-byte records: nameIndex, assemblyIndex, typeStart, typeCount, exportedTypeStart, exportedTypeCount) ----
IMG_SIZE = 24
img_off, img_size = hdr["images"]
img_count = img_size // IMG_SIZE
print(f"images: {img_count}")
for i in range(img_count):
    base = img_off + i * IMG_SIZE
    nameIdx, asmIdx, typeStart, typeCount, expStart, expCount = struct.unpack("<6I", dec[base:base + IMG_SIZE])
    print(f"  {get_string(nameIdx)} types={typeCount}")

# ---- Assemblies (24-byte records: imageIndex, customAttributeIndex, referencedAssemblyStart, referencedAssemblyCount, nameIndex, cultureIndex) ----
ASM_SIZE = 24
asm_off, asm_size = hdr["assemblies"]
asm_count = asm_size // ASM_SIZE
print(f"assemblies: {asm_count}")
for i in range(asm_count):
    base = asm_off + i * ASM_SIZE
    imageIdx, custAttr, refStart, refCount, nameIdx, cultureIdx = struct.unpack("<6I", dec[base:base + ASM_SIZE])
    print(f"  {get_string(nameIdx)}")

# ---- Fields (12-byte records: nameIndex, typeIndex, customAttributeIndex) ----
F_SIZE = 12
f_off, f_size = hdr["fields"]
f_count = f_size // F_SIZE
print(f"fields: {f_count}")
