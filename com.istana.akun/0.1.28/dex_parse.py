#!/usr/bin/env python3
"""Parse classes.dex: strings, types, methods, fields, class defs.
Outputs text dumps into the dump/ dir next to this script."""
import struct, os, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
DEX = os.path.join(ROOT, "..", "extract", "classes.dex")

def u32(b, o): return struct.unpack_from("<I", b, o)[0]
def u16(b, o): return struct.unpack_from("<H", b, o)[0]

def read_uleb128(b, o):
    res = 0; shift = 0
    while True:
        byte = b[o]; o += 1
        res |= (byte & 0x7F) << shift
        if byte & 0x80 == 0: break
        shift += 7
    return res, o

def read_mutf8(b, o):
    _ln, o = read_uleb128(b, o)
    end = b.index(b"\x00", o)
    return b[o:end].decode("utf-8", "replace"), end + 1

def main():
    dex = open(DEX, "rb").read()
    string_ids_size = u32(dex, 56); string_ids_off = u32(dex, 60)
    type_ids_size = u32(dex, 64); type_ids_off = u32(dex, 68)
    proto_ids_size = u32(dex, 72); proto_ids_off = u32(dex, 76)
    field_ids_size = u32(dex, 80); field_ids_off = u32(dex, 84)
    method_ids_size = u32(dex, 88); method_ids_off = u32(dex, 92)
    class_defs_size = u32(dex, 96); class_defs_off = u32(dex, 100)

    strings = []
    for i in range(string_ids_size):
        off = u32(dex, string_ids_off + i * 4)
        s, _ = read_mutf8(dex, off)
        strings.append(s)

    types = []
    for i in range(type_ids_size):
        idx = u32(dex, type_ids_off + i * 4)
        types.append(strings[idx])

    protos = []
    for i in range(proto_ids_size):
        off = proto_ids_off + i * 12
        shorty_idx = u32(dex, off)
        return_idx = u32(dex, off + 4)
        params_off = u32(dex, off + 8)
        params = []
        if params_off:
            size = u32(dex, params_off)
            for j in range(size):
                params.append(types[u16(dex, params_off + 4 + j * 2)])
        protos.append((strings[shorty_idx], types[return_idx], params))

    fields = []
    for i in range(field_ids_size):
        off = field_ids_off + i * 8
        fields.append((types[u16(dex, off)], types[u16(dex, off + 2)], strings[u32(dex, off + 4)]))

    methods = []
    for i in range(method_ids_size):
        off = method_ids_off + i * 8
        cls = types[u16(dex, off)]
        proto_idx = u16(dex, off + 2)
        name = strings[u32(dex, off + 4)]
        methods.append((cls, proto_idx, name))

    def fmt_proto(pi):
        _s, ret, params = protos[pi]
        return "(%s)%s" % (", ".join(params), ret)

    with open(os.path.join(ROOT, "strings.txt"), "w") as f:
        for i, s in enumerate(strings):
            f.write(f"[{i}] {s}\n")

    with open(os.path.join(ROOT, "classes.txt"), "w") as f:
        for t in sorted(set(types)):
            f.write(t + "\n")

    with open(os.path.join(ROOT, "methods.txt"), "w") as f:
        for cls, pi, name in methods:
            f.write(f"{cls} -> {name}{fmt_proto(pi)}\n")

    with open(os.path.join(ROOT, "fields.txt"), "w") as f:
        for cls, typ, name in fields:
            f.write(f"{cls} -> {typ} {name}\n")

    # app classes: class_defs + their direct methods/fields
    app_classes = []
    for i in range(class_defs_size):
        off = class_defs_off + i * 32
        cls = types[u32(dex, off)]
        if cls.startswith("Lcom/istana/"):
            app_classes.append(cls)
    with open(os.path.join(ROOT, "app_classes.txt"), "w") as f:
        for cls in sorted(app_classes):
            f.write(cls + "\n")
            for c2, pi, name in methods:
                if c2 == cls:
                    f.write(f"    M {name}{fmt_proto(pi)}\n")
            for c2, typ, name in fields:
                if c2 == cls:
                    f.write(f"    F {typ} {name}\n")

    print(f"strings={len(strings)} types={len(types)} protos={len(protos)} "
          f"fields={len(fields)} methods={len(methods)} app_classes={len(app_classes)}")

if __name__ == "__main__":
    main()
