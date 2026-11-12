#!/usr/bin/env python3
"""IL2CPP global-metadata.dat v39 parser (Unity 6000.3.x, ToE3 0.9.52).
Header: sanity(4) + version(4) + 31 x Il2CppSectionMetadata{offset,size,count} = 380 bytes.
Record layouts per c01ns/Il2CppDumper (v39 index widths):
  typeDefinitionIndexSize=2 (17758 types), genericContainerIndexSize=2 (2501),
  typeIndexSize=2 (interfaceOffsets record 6 bytes), parameterIndexSize=4 (146903),
  event/interfaces/nested/property/method/field/genericParameter/defaultValue indices = 4.
Record sizes (validated against section size/count):
  ImageDefinition 36, TypeDefinition 76, MethodDefinition 30, FieldDefinition 10,
  ParameterDefinition 10, PropertyDefinition 20, EventDefinition 22,
  GenericContainer 16, GenericParameter 14.
NOTE: TypeDefinition byval/declaring/parent are runtime Il2CppType indices
(not typeDef indices) -- values may exceed 17758; not resolved here.
"""
import struct, json

PATH = 'base-apk/assets/bin/Data/Managed/Metadata/global-metadata.dat'

SEC_NAMES = ["stringLiteral","stringLiteralData","string","events","properties","methods",
    "parameterDefaultValues","fieldDefaultValues","fieldAndParameterDefaultValueData",
    "fieldMarshaledSizes","parameters","fields","genericParameters","genericParameterConstraints",
    "genericContainers","nestedTypes","interfaces","vtableMethods","interfaceOffsets",
    "typeDefinitions","images","assemblies","fieldRefs","referencedAssemblies",
    "attributeData","attributeDataRanges","unresolvedIndirectCallParameterTypes",
    "unresolvedIndirectCallParameterRanges","windowsRuntimeTypeNames","windowsRuntimeStrings",
    "exportedTypeDefinitions"]

def main():
    data = open(PATH,'rb').read()
    sanity, version = struct.unpack_from('<II', data, 0)
    assert sanity == 0xFAB11BAF, hex(sanity)
    secs = {}
    for i, nm in enumerate(SEC_NAMES):
        off, size, cnt = struct.unpack_from('<III', data, 8 + i*12)
        secs[nm] = (off, size, cnt)
    print(f"metadata v{version}, file {len(data)} bytes, sanity OK")
    for nm in SEC_NAMES:
        off, size, cnt = secs[nm]
        rec = size//cnt if cnt else 0
        print(f"  {nm:42s} off={off:9d} size={size:9d} cnt={cnt:8d} rec={rec}")

    STR_OFF, STR_SIZE, _ = secs['string']
    def getstr(idx):
        if idx < 0 or idx >= STR_SIZE: return f"<bad:{idx}>"
        end = data.find(b'\x00', STR_OFF+idx, STR_OFF+STR_SIZE)
        return data[STR_OFF+idx:end].decode('utf-8','replace')

    # --- images ---
    IMG_OFF, _, IMG_CNT = secs['images']
    images = []
    for i in range(IMG_CNT):
        nameIdx, asmIdx = struct.unpack_from('<II', data, IMG_OFF+i*36)
        typeStart, typeCount = struct.unpack_from('<HI', data, IMG_OFF+i*36+8)
        images.append({'name': getstr(nameIdx), 'asm': asmIdx, 'typeStart': typeStart, 'typeCount': typeCount})
    with open('images.txt','w') as f:
        for i, im in enumerate(images):
            f.write(f"{i}\t{im['name']}\ttypes={im['typeCount']} start={im['typeStart']}\n")
    print(f"images: {len(images)}")

    # --- types ---
    TD_OFF, _, TD_CNT = secs['typeDefinitions']
    types = []
    for i in range(TD_CNT):
        b = TD_OFF + i*76
        nameIdx, nsIdx = struct.unpack_from('<II', data, b)
        flags, = struct.unpack_from('<I', data, b+16)
        fieldStart, methodStart, eventStart, propStart, nestedStart, ifacesStart, vtableStart, ifaceOffStart = struct.unpack_from('<8I', data, b+20)
        mCnt, pCnt, fCnt, eCnt, nCnt, vCnt, iCnt, ioCnt = struct.unpack_from('<8H', data, b+52)
        bitfield, token = struct.unpack_from('<2I', data, b+68)
        types.append({'idx': i, 'name': getstr(nameIdx), 'ns': getstr(nsIdx),
                      'flags': flags, 'fieldStart': fieldStart, 'methodStart': methodStart,
                      'eventStart': eventStart, 'propStart': propStart,
                      'nestedStart': nestedStart, 'ifacesStart': ifacesStart,
                      'vtableStart': vtableStart, 'ifaceOffStart': ifaceOffStart,
                      'mCnt': mCnt, 'pCnt': pCnt, 'fCnt': fCnt, 'eCnt': eCnt,
                      'nCnt': nCnt, 'vCnt': vCnt, 'iCnt': iCnt, 'ioCnt': ioCnt,
                      'bitfield': bitfield, 'token': token})
    for im in images:
        for t in range(im['typeStart'], im['typeStart']+im['typeCount']):
            if 0 <= t < len(types):
                types[t]['image'] = im['name']
    with open('types.txt','w') as f:
        for t in types:
            f.write(f"{t['idx']}\t{t.get('image','?')}\t{t['ns']}\t{t['name']}\tmethods={t['mCnt']} fields={t['fCnt']} props={t['pCnt']} events={t['eCnt']}\n")
    print(f"types: {len(types)}")

    # --- methods ---
    M_OFF, _, M_CNT = secs['methods']
    methods = []
    for i in range(M_CNT):
        b = M_OFF + i*30
        nameIdx, = struct.unpack_from('<I', data, b)
        declaringType, returnType = struct.unpack_from('<HH', data, b+4)
        retTok, paramStart = struct.unpack_from('<II', data, b+8)
        genCont, = struct.unpack_from('<H', data, b+16)
        token, = struct.unpack_from('<I', data, b+18)
        flags, iflags, slot, paramCount = struct.unpack_from('<4H', data, b+22)
        methods.append({'idx': i, 'name': getstr(nameIdx), 'declaringType': declaringType,
                        'returnType': returnType, 'paramStart': paramStart, 'paramCount': paramCount,
                        'flags': flags, 'slot': slot, 'token': token})
    with open('methods.txt','w') as f:
        for m in methods:
            f.write(f"{m['idx']}\t{m['name']}\tdeclType={m['declaringType']} params={m['paramCount']}\n")
    print(f"methods: {len(methods)}")

    # --- fields ---
    F_OFF, _, F_CNT = secs['fields']
    fields = []
    for i in range(F_CNT):
        b = F_OFF + i*10
        nameIdx, = struct.unpack_from('<I', data, b)
        typeIdx, = struct.unpack_from('<H', data, b+4)
        token, = struct.unpack_from('<I', data, b+6)
        fields.append({'idx': i, 'name': getstr(nameIdx), 'typeIdx': typeIdx, 'token': token})
    with open('fields.txt','w') as f:
        for fl in fields:
            f.write(f"{fl['idx']}\t{fl['name']}\ttypeIdx={fl['typeIdx']}\n")
    print(f"fields: {len(fields)}")

    # --- properties ---
    P_OFF, _, P_CNT = secs['properties']
    props = []
    for i in range(P_CNT):
        b = P_OFF + i*20
        nameIdx, get_, set_, attrs, token = struct.unpack_from('<IIIII', data, b)
        props.append({'idx': i, 'name': getstr(nameIdx), 'get': get_, 'set': set_, 'attrs': attrs})
    with open('properties.txt','w') as f:
        for p in props:
            f.write(f"{p['idx']}\t{p['name']}\tget={p['get']} set={p['set']}\n")
    print(f"properties: {len(props)}")

    # --- events ---
    E_OFF, _, E_CNT = secs['events']
    with open('events.txt','w') as f:
        for i in range(E_CNT):
            b = E_OFF + i*22
            nameIdx, = struct.unpack_from('<I', data, b)
            typeIdx, = struct.unpack_from('<H', data, b+4)
            add, rem, raise_ = struct.unpack_from('<III', data, b+6)
            f.write(f"{i}\t{getstr(nameIdx)}\tadd={add} remove={rem} raise={raise_}\n")
    print(f"events: {E_CNT}")

    # --- per-type member dump for targets ---
    def type_members(t):
        ms = [methods[t['methodStart']+k] for k in range(t['mCnt']) if t['methodStart'] != 0xFFFFFFFF and t['methodStart']+k < len(methods)]
        fs = [fields[t['fieldStart']+k] for k in range(t['fCnt']) if t['fieldStart'] != 0xFFFFFFFF and t['fieldStart']+k < len(fields)]
        ps = [props[t['propStart']+k] for k in range(t['pCnt']) if t['propStart'] != 0xFFFFFFFF and t['propStart']+k < len(props)]
        return ms, fs, ps

    targets = ['Prefs','TruckController','TruckDamage','TrafficSpawner','TrafficCar','Job',
               'ProfileData','PlayerData','MultiPlayer','NetworkManager','ChatManager',
               'Autopilot','Spectate','ConvoyManager','RoomManager','VoiceChat','OtherPlayer']
    out = []
    found = {}
    for t in types:
        for tgt in targets:
            if t['name'] == tgt or tgt.lower() in t['name'].lower():
                found.setdefault(tgt, []).append(t)
    for tgt, tlist in found.items():
        for t in tlist:
            ms, fs, ps = type_members(t)
            out.append(f"=== {t.get('image','?')} :: {t['ns']}.{t['name']} (typeIdx {t['idx']}) methods={t['mCnt']} fields={t['fCnt']} props={t['pCnt']} ===")
            for m in ms: out.append(f"  M[{m['idx']}] {m['name']} (params={m['paramCount']})")
            for fl in fs: out.append(f"  F[{fl['idx']}] {fl['name']} (typeIdx={fl['typeIdx']})")
            for p in ps: out.append(f"  P[{p['idx']}] {p['name']} get={p['get']} set={p['set']}")
    open('targets.txt','w').write('\n'.join(out) + '\n')
    print(f"target types found: {sum(len(v) for v in found.values())} across {len(found)} target keys")
    for k, v in found.items():
        print(f"  {k}: {len(v)} -> {[t['name'] + ' (' + t.get('image','?') + ')' for t in v][:6]}")

    json.dump({'types': types, 'images': images}, open('dump.json','w'))
    print("wrote types.txt methods.txt fields.txt properties.txt events.txt images.txt targets.txt dump.json")

if __name__ == '__main__':
    main()
