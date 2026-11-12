#!/usr/bin/env python3
"""Minimal IL2CPP global-metadata.dat parser (metadata v29, Unity 2022.3).
Dumps images -> types (namespace + name) and, for selected types, methods/fields.
Usage: python3 il2cpp_meta.py <metadata.dat> [out.txt]
"""
import struct, sys

def u32(b, o): return struct.unpack_from('<I', b, o)[0]
def i32(b, o): return struct.unpack_from('<i', b, o)[0]
def u16(b, o): return struct.unpack_from('<H', b, o)[0]

def main():
    path = sys.argv[1]
    data = open(path, 'rb').read()
    magic = u32(data, 0)
    version = i32(data, 4)
    assert magic == 0xFAB11BAF, hex(magic)
    print(f"metadata version={version} size={len(data)}", file=sys.stderr)

    # header offsets (v29)
    hdr = {}
    names = ["stringLiteralOffset","stringLiteralCount","stringLiteralDataOffset","stringLiteralDataCount",
             "stringOffset","stringCount","eventsOffset","eventsCount","propertiesOffset","propertiesCount",
             "methodsOffset","methodsCount","parameterDefaultValuesOffset","parameterDefaultValuesCount",
             "fieldDefaultValuesOffset","fieldDefaultValuesCount","fieldAndParameterDefaultValueDataOffset",
             "fieldAndParameterDefaultValueDataCount","fieldMarshaledSizesOffset","fieldMarshaledSizesCount",
             "parametersOffset","parametersCount","fieldsOffset","fieldsCount","genericParametersOffset",
             "genericParametersCount","genericParameterConstraintsOffset","genericParameterConstraintsCount",
             "genericContainersOffset","genericContainersCount","nestedTypesOffset","nestedTypesCount",
             "interfacesOffset","interfacesCount","vtableMethodsOffset","vtableMethodsCount",
             "interfaceOffsetsOffset","interfaceOffsetsCount","typeDefinitionsOffset","typeDefinitionsCount",
             "imagesOffset","imagesCount","assembliesOffset","assembliesCount","metadataUsageListsOffset",
             "metadataUsageListsCount","metadataUsagePairsOffset","metadataUsagePairsCount","fieldRefsOffset",
             "fieldRefsCount","referencedAssembliesOffset","referencedAssembliesCount","attributesInfoOffset",
             "attributesInfoCount","attributeTypesOffset","attributeTypesCount",
             "unresolvedVirtualCallParameterTypesOffset","unresolvedVirtualCallParameterTypesCount",
             "unresolvedVirtualCallParameterRangesOffset","unresolvedVirtualCallParameterRangesCount",
             "windowsRuntimeTypeNamesOffset","windowsRuntimeTypeNamesSize","exportedTypeDefinitionsOffset",
             "exportedTypeDefinitionsCount"]
    for i, n in enumerate(names):
        hdr[n] = i32(data, 8 + i*4)

    str_off, str_cnt = hdr["stringOffset"], hdr["stringCount"]
    def get_str(idx):
        # string section: sequence of uint32 offsets then data; idx is offset into string data
        # In metadata, string indices are byte offsets into the string data blob.
        end = data.find(b'\x00', str_off + idx)
        return data[str_off+idx:end].decode('utf-8', 'replace')

    # TypeDefinition = 92 bytes (v29)
    TD_SIZE = 88  # metadata v31
    td_off = hdr["typeDefinitionsOffset"]
    td_cnt = hdr["typeDefinitionsCount"] // TD_SIZE
    print(f"typeDefinitions: {td_cnt}", file=sys.stderr)

    # ImageDefinition = 32 bytes
    IMG_SIZE = 40  # metadata v31
    img_off = hdr["imagesOffset"]
    img_cnt = hdr["imagesCount"] // IMG_SIZE
    images = []
    for i in range(img_cnt):
        o = img_off + i*IMG_SIZE
        name_idx = u32(data, o)
        asm_idx = i32(data, o+4)
        type_start = i32(data, o+8)
        type_count = u32(data, o+12)
        images.append((get_str(name_idx), asm_idx, type_start, type_count))

    # MethodDefinition = 32 bytes; FieldDefinition = 12 bytes
    meth_off = hdr["methodsOffset"]
    field_off = hdr["fieldsOffset"]
    def method_name(midx):
        o = meth_off + midx*36  # v31 MethodDefinition=36B
        return get_str(i32(data, o))
    def field_name(fidx):
        o = field_off + fidx*12
        return get_str(i32(data, o))

    out = open(sys.argv[2], 'w') if len(sys.argv) > 2 else sys.stdout
    types = []
    for ti in range(td_cnt):
        o = td_off + ti*TD_SIZE
        name = get_str(u32(data, o))
        ns = get_str(u32(data, o+4))
        field_start = i32(data, o+32)
        method_start = i32(data, o+36)
        mcount = u16(data, o+64)
        fcount = u16(data, o+68)
        types.append((ti, ns, name, method_start, mcount, field_start, fcount))

    # group by image
    for img_name, asm_idx, tstart, tcount in images:
        out.write(f"\n### IMAGE {img_name} (types {tcount})\n")
        for ti in range(tstart, tstart+tcount):
            _, ns, name, mstart, mcount, fstart, fcount = types[ti]
            out.write(f"{ns}.{name}  [methods={mcount} fields={fcount}]\n")
    out.write("\n\n===== METHODS/FIELDS FOR SELECTED TYPES =====\n")
    sel = sys.argv[3].split(',') if len(sys.argv) > 3 else []
    for ti, ns, name, mstart, mcount, fstart, fcount in types:
        full = f"{ns}.{name}"
        if sel and not any(s.lower() in full.lower() for s in sel):
            continue
        out.write(f"\n## {full}\n")
        for mi in range(mstart, mstart+mcount):
            out.write(f"  M: {method_name(mi)}\n")
        for fi in range(fstart, fstart+fcount):
            out.write(f"  F: {field_name(fi)}\n")
    if out is not sys.stdout:
        out.close()
    print("done", file=sys.stderr)

if __name__ == '__main__':
    main()
