#!/usr/bin/env python3
"""Il2CppDumper-equivalent for Unity 6 (metadata v106.0, Unity 6000.5.x), arm64 ELF.
Written from rodroid il2cppdumper struct layouts (structures.rs / base.rs / elf.rs)
because Perfare Il2CppDumper and MyDearMoon v1.4.0 both reject metadata v107
(which is really the v106.0 layout: Unity 6.5.1 backported the number 107
without the layout changes; v106.1 needs Unity >= 6.6.0a6).

Pipeline:
  1. parse ELF program headers (VA -> file offset)
  2. parse global-metadata.dat header (full section table)
  3. find Il2CppCodeGenModule structs by scanning RW segments for a
     module_name pointer to a known assembly name; a module's last two
     slots point back at g_CodeRegistration / g_MetadataRegistration
  4. validate both registrations (count/pointer plausibility)
  5. read code_gen_modules -> per-image method pointer arrays
  6. resolve every method def RVA: ptrs[(token & 0xFFFFFF) - 1] within its image
  7. emit dump.cs + JSON model (for the dummy-DLL generator)
"""
import json, struct, sys, os

VERSION = 106.0
METADATA = os.path.expanduser('~/workspace/rea-trafficrider-221/extract/assets/assets/bin/Data/Managed/Metadata/global-metadata.dat')
LIB = os.path.expanduser('~/workspace/rea-trafficrider-221/extract/lib/arm64-v8a/libil2cpp.so')
WORK = os.path.expanduser('~/workspace/rea-trafficrider-221')

# ---------- index widths for v106.0 (rodroid layout.rs) ----------
IW = dict(type_def=2, generic_container=2, type_index=2, parameter_def=4,
          interface_offset=2, event=2, property=2, nested_type=2,
          method=4, generic_param=2, field=2, default_value_data=4)

def u16(b,o): return struct.unpack_from('<H', b, o)[0]
def i16(b,o): return struct.unpack_from('<h', b, o)[0]
def u32(b,o): return struct.unpack_from('<I', b, o)[0]
def i32(b,o): return struct.unpack_from('<i', b, o)[0]
def u64(b,o): return struct.unpack_from('<Q', b, o)[0]
def i64(b,o): return struct.unpack_from('<q', b, o)[0]

# ---------- ELF ----------
class Elf:
    def __init__(self, path):
        self.data = open(path,'rb').read()
        d = self.data
        assert d[:4] == b'\x7fELF' and d[4] == 2 and d[5] == 1, 'not 64-bit LE ELF'
        self.is_64 = True
        self.phoff = u64(d, 0x20)
        self.phentsize, self.phnum = u16(d, 0x36), u16(d, 0x38)
        self.loads = []  # (vaddr, filesz, memsz, offset, flags)
        for i in range(self.phnum):
            o = self.phoff + i*self.phentsize
            p_type, p_flags = u32(d,o), u32(d,o+4)
            p_offset, p_vaddr, p_filesz, p_memsz = u64(d,o+8), u64(d,o+16), u64(d,o+32), u64(d,o+40)
            if p_type == 1:  # PT_LOAD
                self.loads.append(dict(vaddr=p_vaddr, filesz=p_filesz, memsz=p_memsz,
                                       offset=p_offset, flags=p_flags))
        self.vsize = max(s['vaddr']+s['memsz'] for s in self.loads)
        self.exec_ranges = [(s['vaddr'], s['vaddr']+s['filesz']) for s in self.loads if s['flags'] & 1]
        self.data_ranges = [(s['vaddr'], s['vaddr']+s['filesz'], s['offset']) for s in self.loads if not (s['flags'] & 1) and s['filesz'] > 0]
    def va2off(self, va):
        for s in self.loads:
            if s['vaddr'] <= va < s['vaddr'] + s['filesz']:
                return s['offset'] + (va - s['vaddr'])
        return None
    def in_exec(self, va):
        return any(a <= va < b for a,b in self.exec_ranges)
    def in_file_va(self, va):
        return any(s['vaddr'] <= va < s['vaddr']+s['filesz'] for s in self.loads)
    def read_cstr_at_va(self, va, maxlen=512):
        off = self.va2off(va)
        if off is None: return None
        end = self.data.find(b'\x00', off, off+maxlen)
        if end < 0: return None
        try: return self.data[off:end].decode('utf-8')
        except UnicodeDecodeError: return None
    def read_u64_at_va(self, va):
        off = self.va2off(va)
        return None if off is None else u64(self.data, off)
    def read_array_u64(self, va, count):
        off = self.va2off(va)
        if off is None or off + 8*count > len(self.data): return None
        return list(struct.unpack_from('<%dQ' % count, self.data, off))

# ---------- metadata ----------
class Meta:
    def __init__(self, path):
        self.data = open(path,'rb').read()
        d = self.data
        assert u32(d,0) == 0xFAB11BAF, 'bad magic'
        self.version = i32(d,4)
        assert self.version == 107, f'version {self.version} != 107'
        # header: sanity,version then sec triples (off,size,count) in order
        p = 8
        def sec():
            nonlocal p
            o,s,c = i32(d,p), i32(d,p+4), i32(d,p+8); p += 12
            return (o,s,c)
        self.string_literal = sec(); self.string_literal_data = sec(); self.string = sec()
        self.events = sec(); self.properties = sec(); self.methods = sec()
        self.parameter_default_values = sec(); self.field_default_values = sec()
        self.field_param_default_data = sec(); self.field_marshaled_sizes = sec()
        self.parameters = sec(); self.fields = sec(); self.generic_parameters = sec()
        self.generic_parameter_constraints = sec(); self.generic_containers = sec()
        self.nested_types = sec(); self.interfaces = sec(); self.vtable_methods = sec()
        self.interface_offsets = sec(); self.type_definitions = sec()
        self.type_inline_arrays = sec()  # v>=104
        # rgctx_entries: only v<=24.15 -> skip; images, assemblies
        self.images = sec(); self.assemblies = sec()
        # metadata usage lists/pairs: only v<27 -> skip
        self.field_refs = sec(); self.referenced_assemblies = sec()
        # v>=29: attribute_data + attribute_data_range (2 secs)
        self.attribute_data = sec(); self.attribute_data_range = sec()
        self.uvc_param_types = sec(); self.uvc_param_ranges = sec()
        self.winrt_type_names = sec(); self.winrt_strings = sec()
        self.exported_type_defs = sec()
        self.header_end = p
    def get_str(self, idx):
        o, s, _ = self.string
        if idx < 0 or idx >= s: return f'<badstr:{idx}>'
        end = self.data.find(b'\x00', o+idx, o+s)
        if end < 0: end = o+s
        return self.data[o+idx:end].decode('utf-8', 'replace')
    def parse_images(self):
        o, s, _ = self.images
        n = s // 36
        imgs = []
        for i in range(n):
            b = o + i*36
            name_idx, asm_idx = i32(self.data,b), i32(self.data,b+4)
            type_start = u16(self.data,b+8); type_count = u32(self.data,b+10)
            exp_start = u16(self.data,b+14); exp_count = u32(self.data,b+16)
            entry = i32(self.data,b+20); token = u32(self.data,b+24)
            imgs.append(dict(name=self.get_str(name_idx), assembly_index=asm_idx,
                             type_start=type_start, type_count=type_count,
                             exported_start=exp_start, exported_count=exp_count,
                             entry_point=entry, token=token))
        return imgs
    def parse_assemblies(self):
        o, s, _ = self.assemblies
        n = s // 68
        out = []
        for i in range(n):
            b = o + i*68
            image_index = i32(self.data,b)
            # aname: 48 bytes starting at b+20: name/culture/hash/pubkey/hashalg/hashlen/flags/major/minor/build/revision/token[8]
            name_idx = i32(self.data,b+20)
            out.append(dict(image_index=image_index, name=self.get_str(name_idx)))
        return out
    def parse_type_defs(self):
        o, s, _ = self.type_definitions
        n = s // 64
        tds = []
        for i in range(n):
            b = o + i*64
            td = dict(
                name=self.get_str(i32(self.data,b)), namespace=self.get_str(i32(self.data,b+4)),
                byval_type=u16(self.data,b+8), declaring_type=u16(self.data,b+10),
                parent=u16(self.data,b+12), generic_container=u16(self.data,b+14),
                flags=u32(self.data,b+16),
                field_start=u16(self.data,b+20), method_start=u32(self.data,b+22),
                event_start=u16(self.data,b+26), property_start=u16(self.data,b+28),
                nested_start=u16(self.data,b+30), interfaces_start=u16(self.data,b+32),
                vtable_start=i32(self.data,b+34), interface_offsets_start=u16(self.data,b+38),
                method_count=u16(self.data,b+40), property_count=u16(self.data,b+42),
                field_count=u16(self.data,b+44), event_count=u16(self.data,b+46),
                nested_count=u16(self.data,b+48), vtable_count=u16(self.data,b+50),
                interfaces_count=u16(self.data,b+52), interface_offsets_count=u16(self.data,b+54),
                bitfield=u32(self.data,b+56), token=u32(self.data,b+60))
            tds.append(td)
        return tds
    def parse_methods(self):
        o, s, _ = self.methods
        n = s // 30
        ms = []
        for i in range(n):
            b = o + i*30
            ms.append(dict(
                name=self.get_str(u32(self.data,b)), declaring_type=u16(self.data,b+4),
                return_type=u16(self.data,b+6), return_param_token=u32(self.data,b+8),
                param_start=u32(self.data,b+12), generic_container=u16(self.data,b+16),
                token=u32(self.data,b+18), flags=u16(self.data,b+22),
                iflags=u16(self.data,b+24), slot=u16(self.data,b+26),
                param_count=u16(self.data,b+28)))
        return ms
    def parse_fields(self):
        o, s, _ = self.fields
        n = s // 10
        fs = []
        for i in range(n):
            b = o + i*10
            fs.append(dict(name=self.get_str(i32(self.data,b)), type=u16(self.data,b+4),
                           token=u32(self.data,b+6)))
        return fs
    def parse_params(self):
        o, s, _ = self.parameters
        n = s // 10
        ps = []
        for i in range(n):
            b = o + i*10
            ps.append(dict(name=self.get_str(i32(self.data,b)), token=u32(self.data,b+4),
                           type=u16(self.data,b+8)))
        return ps

def plausibility_pairs(pairs, elf):
    """pairs: list of (name, count, ptr). Returns list of problems."""
    probs = []
    for name, count, ptr in pairs:
        if count == 0:
            if ptr != 0: probs.append(f'{name}: count 0 but ptr 0x{ptr:x}')
            continue
        if count > 2_000_000:
            probs.append(f'{name}: count {count} absurd'); continue
        if ptr == 0 or not elf.in_file_va(ptr):
            probs.append(f'{name}: ptr 0x{ptr:x} outside file'); continue
        off = elf.va2off(ptr)
        if off is None or off + 8*count > len(elf.data):
            probs.append(f'{name}: array 0x{ptr:x} x {count} overruns file')
    return probs

# ---------- relocations ----------
# The .so's data pointers are NOT resolved on disk: pointer slots in
# .data.rel.ro/.data contain 0 and the real values live only in .rela.dyn
# as R_AARCH64_RELATIVE addends (RELACOUNT 420014). Every pointer read must
# go through ptr_at(): relmap[va] if present, else the on-disk u64.
class Rela:
    def __init__(self, elf, rela_off=0x31510, rela_size=10127832):
        self.map = {}
        self.rev = {}
        d = elf.data
        n = rela_size // 24
        for i in range(n):
            r_offset, r_info, r_addend = struct.unpack_from('<QQq', d, rela_off + i*24)
            if (r_info & 0xffffffff) == 1027:  # R_AARCH64_RELATIVE
                self.map[r_offset] = r_addend
                self.rev.setdefault(r_addend, []).append(r_offset)
    def ptr_at(self, elf, va):
        if va in self.map:
            return self.map[va]
        off = elf.va2off(va)
        return None if off is None else u64(elf.data, off)
    def refs_to(self, elf, target):
        """All VAs in data sections whose resolved pointer == target."""
        out = list(self.rev.get(target, []))
        needle = struct.pack('<Q', target)
        for va_start, va_end, foff in elf.data_ranges:
            seg = elf.data[foff:foff + (va_end - va_start)]
            st = 0
            while True:
                j = seg.find(needle, st)
                if j < 0: break
                if j % 8 == 0:
                    out.append(va_start + j)
                st = j + 1
        return out

def find_code_registration(elf, rela, image_count):
    """rodroid find_code_registration_2019_with_feature (v>=27 branch)."""
    d = elf.data
    for feat in (b'mscorlib.dll\x00', b'System.Private.CoreLib.dll\x00'):
        # find the string in any section (rodata)
        dll_va = None
        for s in elf.loads:
            seg = d[s['offset']:s['offset']+s['filesz']]
            j = seg.find(feat)
            if j >= 0:
                dll_va = s['vaddr'] + j
                break
        if dll_va is None:
            continue
        refs1 = rela.refs_to(elf, dll_va)
        for ref_va in refs1:
            refs2 = rela.refs_to(elf, ref_va)
            for ref_va2 in refs2:
                min_target = ref_va2 - (image_count - 1) * 8
                max_target = ref_va2
                # scan data sections for (count==image_count, ptr in range)
                for va_start, va_end, foff in elf.data_ranges:
                    n = (va_end - va_start) // 8
                    words = struct.unpack_from('<%dQ' % n, d, foff)
                    for i in range(n - 1):
                        if words[i] != image_count:
                            continue
                        pv = rela.ptr_at(elf, va_start + (i+1)*8)
                        if pv is None or pv < min_target or pv > max_target:
                            continue
                        k = (ref_va2 - pv) // 8
                        if k >= image_count or pv != ref_va2 - k*8:
                            continue
                        # ref_va3 = VA of codeGenModules pointer field (slot 17)
                        cr_va = (va_start + (i+1)*8) - 17*8
                        return cr_va, dll_va, ref_va, ref_va2
    return None

def find_metadata_registration(elf, rela, type_count):
    """rodroid find_metadata_registration_v21: two equal type-counts 10 slots apart."""
    d = elf.data
    for va_start, va_end, foff in elf.data_ranges:
        n = (va_end - va_start) // 8
        words = struct.unpack_from('<%dQ' % n, d, foff)
        for i in range(n - 13):
            if words[i] != type_count or words[i+2] != type_count:
                continue
            ptr_va = rela.ptr_at(elf, va_start + (i+3)*8)
            if ptr_va is None:
                continue
            # sample first 10 entries of the typeDefinitionsSizes pointer array
            ok = True
            for k in range(min(10, type_count)):
                v = rela.ptr_at(elf, ptr_va + k*8)
                if v is None or not elf.in_file_va(v):
                    ok = False; break
            if not ok:
                continue
            return va_start + i*8 - 10*8
    return None
    """pairs: list of (name, count, ptr). Returns list of problems."""
    probs = []
    for name, count, ptr in pairs:
        if count == 0:
            if ptr != 0: probs.append(f'{name}: count 0 but ptr 0x{ptr:x}')
            continue
        if count > 2_000_000:
            probs.append(f'{name}: count {count} absurd'); continue
        if ptr == 0 or not elf.in_file_va(ptr):
            probs.append(f'{name}: ptr 0x{ptr:x} outside file'); continue
        off = elf.va2off(ptr)
        if off is None or off + 8*count > len(elf.data):
            probs.append(f'{name}: array 0x{ptr:x} x {count} overruns file')
    return probs

def find_modules(elf, image_names):
    """Scan RW data segments for Il2CppCodeGenModule structs (17 x u64)."""
    found = {}
    names = set(image_names)
    d = elf.data
    for va_start, va_end, foff in elf.data_ranges:
        base = foff
        n = (va_end - va_start) // 8
        # read all u64s in segment once
        words = struct.unpack_from('<%dQ' % n, d, base)
        for i in range(n - 17):
            name_va = words[i]
            if name_va == 0 or not elf.in_file_va(name_va):
                continue
            s = elf.read_cstr_at_va(name_va, 128)
            if s is None or s not in names:
                continue
            cnt = words[i+1]
            if not (0 < cnt <= 200000):
                continue
            mp = words[i+2]
            if mp == 0 or not elf.in_file_va(mp):
                continue
            # sample method pointers: must be code addresses (or 0)
            ok = True
            sample = elf.read_array_u64(mp, min(cnt, 32))
            if sample is None:
                continue
            nonzero = [x for x in sample if x != 0]
            if len(nonzero) < max(1, min(cnt, 32) // 2):
                continue
            if not all(elf.in_exec(x) for x in nonzero[:8]):
                continue
            mr = words[i+15]; cr = words[i+16]
            if mr == 0 or cr == 0 or not elf.in_file_va(mr) or not elf.in_file_va(cr):
                continue
            va = va_start + i*8
            found[s] = dict(va=va, method_pointer_count=cnt, method_pointers=mp,
                            metadata_registration=mr, code_registration=cr)
    return found

def read_code_registration(elf, va):
    off = elf.va2off(va)
    f = struct.unpack_from('<17Q', elf.data, off)
    # v106 order: rpw_count, rpw, gmp_count, gmp, adj_thunk_count?, ...
    # read fn order: rpw_count(0), rpw(1), gmp_count(2), gmp(3),
    #   adjustor_thunks only if (24.5<=v<27)||v>=27.1 -> present for 106:
    #   adj_count(4), adj_thunks(5), invoker_count(6), invoker(7),
    #   uvc_count(8), uvc(9), uic(10), usc(11), interop_count(12), interop(13),
    #   wrtf_count(14), wrtf(15), cgm_count(16), cgm(17) -> 18 slots!
    f = struct.unpack_from('<18Q', elf.data, off)
    return dict(reverse_pinvoke_wrapper_count=f[0], reverse_pinvoke_wrappers=f[1],
                generic_method_pointers_count=f[2], generic_method_pointers=f[3],
                adjustor_thunk_count=f[4], adjustor_thunks=f[5],
                invoker_pointers_count=f[6], invoker_pointers=f[7],
                unresolved_virtual_call_count=f[8], unresolved_virtual_call_pointers=f[9],
                unresolved_instance_call_pointers=f[10], unresolved_static_call_pointers=f[11],
                interop_data_count=f[12], interop_data=f[13],
                windows_runtime_factory_count=f[14], windows_runtime_factory_table=f[15],
                code_gen_modules_count=f[16], code_gen_modules=f[17])

def read_metadata_registration(elf, va):
    off = elf.va2off(va)
    f = struct.unpack_from('<16Q', elf.data, off)
    return dict(generic_classes_count=f[0], generic_classes=f[1],
                generic_insts_count=f[2], generic_insts=f[3],
                generic_method_table_count=f[4], generic_method_table=f[5],
                types_count=f[6], types=f[7],
                method_specs_count=f[8], method_specs=f[9],
                field_offsets_count=f[10], field_offsets=f[11],
                type_definitions_sizes_count=f[12], type_definitions_sizes=f[13],
                metadata_usages_count=f[14], metadata_usages=f[15])

def load_modules(elf, rela, cr):
    """Read code_gen_modules array -> {image_name: [method ptrs]} + module structs."""
    cgm_va = rela.ptr_at(elf, cr['va'] + 17*8)
    cnt = cr['code_gen_modules_count']
    arr = []
    for i in range(cnt):
        arr.append(rela.ptr_at(elf, cgm_va + i*8))
    modules = {}
    for mva in arr:
        if mva is None: continue
        slots = [rela.ptr_at(elf, mva + k*8) for k in range(17)]
        name = elf.read_cstr_at_va(slots[0], 128) if slots[0] else None
        if name is None: continue
        mpc = slots[1]
        mps = []
        if mpc and slots[2]:
            for i in range(mpc):
                mps.append(rela.ptr_at(elf, slots[2] + i*8))
        modules[name] = dict(va=mva, method_pointer_count=mpc, method_pointers=mps,
                             metadata_registration=slots[15], code_registration=slots[16])
    return modules

if __name__ == '__main__':
    meta = Meta(METADATA)
    elf = Elf(LIB)
    print(f'metadata v{meta.version} size {len(meta.data)} header_end {meta.header_end}')
    print(f'libil2cpp.so size {len(elf.data)} VA size 0x{elf.vsize:x} LOADs {len(elf.loads)}')
    imgs = meta.parse_images()
    print(f'images: {len(imgs)}')
    tds = meta.parse_type_defs(); ms = meta.parse_methods(); fs = meta.parse_fields(); ps = meta.parse_params()
    print(f'type_defs {len(tds)} methods {len(ms)} fields {len(fs)} params {len(ps)}')
    rela = Rela(elf)
    print(f'RELA relative relocs: {len(rela.map)}')
    cr_res = find_code_registration(elf, rela, len(imgs))
    assert cr_res, 'CodeRegistration not found'
    cr_va, dll_va, mod_va, arr_entry = cr_res
    print(f'CodeRegistration @ VA 0x{cr_va:x} (via mscorlib str 0x{dll_va:x}, module 0x{mod_va:x}, array entry 0x{arr_entry:x})')
    cr = read_code_registration(elf, cr_va)
    cr['va'] = cr_va
    cr_probs = plausibility_pairs([
        ('genericMethodPointers', cr['generic_method_pointers_count'], rela.ptr_at(elf, cr_va+3*8)),
        ('invokerPointers', cr['invoker_pointers_count'], rela.ptr_at(elf, cr_va+7*8)),
        ('reversePInvokeWrapper', cr['reverse_pinvoke_wrapper_count'], rela.ptr_at(elf, cr_va+1*8)),
        ('unresolvedVirtualCall', cr['unresolved_virtual_call_count'], rela.ptr_at(elf, cr_va+9*8)),
        ('interopData', cr['interop_data_count'], rela.ptr_at(elf, cr_va+13*8)),
        ('codeGenModules', cr['code_gen_modules_count'], rela.ptr_at(elf, cr_va+17*8)),
        ('windowsRuntimeFactory', cr['windows_runtime_factory_count'], rela.ptr_at(elf, cr_va+15*8)),
    ], elf)
    print('CR counts: gmp=%d inv=%d rpw=%d uvc=%d interop=%d wrtf=%d cgm=%d' % (
        cr['generic_method_pointers_count'], cr['invoker_pointers_count'],
        cr['reverse_pinvoke_wrapper_count'], cr['unresolved_virtual_call_count'],
        cr['interop_data_count'], cr['windows_runtime_factory_count'], cr['code_gen_modules_count']))
    print('CR plausibility problems (reloc-resolved):', cr_probs or 'NONE')
    mr_va = find_metadata_registration(elf, rela, len(tds))
    assert mr_va, 'MetadataRegistration not found'
    print(f'MetadataRegistration @ VA 0x{mr_va:x}')
    mr = read_metadata_registration(elf, mr_va)
    mr['va'] = mr_va
    # reloc-resolve MR pointers
    mr_ptr = {k: rela.ptr_at(elf, mr_va + i*8) for i, k in enumerate(
        ['generic_classes_count','generic_classes','generic_insts_count','generic_insts',
         'generic_method_table_count','generic_method_table','types_count','types',
         'method_specs_count','method_specs','field_offsets_count','field_offsets',
         'type_definitions_sizes_count','type_definitions_sizes','metadata_usages_count','metadata_usages'])}
    mr_probs = plausibility_pairs([
        ('genericClasses', mr['generic_classes_count'], mr_ptr['generic_classes']),
        ('genericInsts', mr['generic_insts_count'], mr_ptr['generic_insts']),
        ('genericMethodTable', mr['generic_method_table_count'], mr_ptr['generic_method_table']),
        ('types', mr['types_count'], mr_ptr['types']),
        ('methodSpecs', mr['method_specs_count'], mr_ptr['method_specs']),
        ('fieldOffsets', mr['field_offsets_count'], mr_ptr['field_offsets']),
        ('typeDefinitionsSizes', mr['type_definitions_sizes_count'], mr_ptr['type_definitions_sizes']),
        ('metadataUsages', mr['metadata_usages_count'], mr_ptr['metadata_usages']),
    ], elf)
    print('MR counts: gc=%d gi=%d gmt=%d types=%d mspec=%d fo=%d tds=%d mu=%d' % (
        mr['generic_classes_count'], mr['generic_insts_count'], mr['generic_method_table_count'],
        mr['types_count'], mr['method_specs_count'], mr['field_offsets_count'],
        mr['type_definitions_sizes_count'], mr['metadata_usages_count']))
    print('MR plausibility problems (reloc-resolved):', mr_probs or 'NONE')
    # cross-check: read_code_registration used on-disk values; rebuild with resolved ptrs
    cr['generic_method_pointers'] = rela.ptr_at(elf, cr_va+3*8)
    cr['invoker_pointers'] = rela.ptr_at(elf, cr_va+7*8)
    cr['reverse_pinvoke_wrappers'] = rela.ptr_at(elf, cr_va+1*8)
    cr['unresolved_virtual_call_pointers'] = rela.ptr_at(elf, cr_va+9*8)
    cr['interop_data'] = rela.ptr_at(elf, cr_va+13*8)
    cr['windows_runtime_factory_table'] = rela.ptr_at(elf, cr_va+15*8)
    cr['code_gen_modules'] = rela.ptr_at(elf, cr_va+17*8)
    modules = load_modules(elf, rela, cr)
    print(f'modules loaded: {len(modules)} (expect {len(imgs)})')
    # cross-validate module back-pointers
    bad = [n for n, m in modules.items() if m['code_registration'] != cr_va or m['metadata_registration'] != mr_va]
    print('modules with mismatched CR/MR back-pointers:', bad or 'NONE')
    total_mps = sum(m['method_pointer_count'] for m in modules.values())
    print(f'total method pointers across modules: {total_mps} (methods in metadata: {len(ms)})')
    # resolve method RVAs
    img_of_type = {}
    for im in imgs:
        for t in range(im['type_start'], im['type_start']+im['type_count']):
            img_of_type[t] = im['name']
    rva = [0]*len(ms)
    missing = 0
    for i, m in enumerate(ms):
        img = img_of_type.get(m['declaring_type'])
        if img is None:
            missing += 1; continue
        mod = modules.get(img)
        if mod is None:
            missing += 1; continue
        rid = (m['token'] & 0xFFFFFF)
        if 1 <= rid <= len(mod['method_pointers']):
            rva[i] = mod['method_pointers'][rid-1] or 0
        else:
            missing += 1
    nonzero = sum(1 for x in rva if x)
    print(f'method RVAs resolved: {nonzero}/{len(ms)} nonzero, {missing} unresolvable')
    # spot check: RVAs must be in .text
    bad_rva = sum(1 for x in rva if x and not elf.in_exec(x))
    print(f'RVAs outside executable segment: {bad_rva}')
    json.dump(dict(code_registration_va=hex(cr_va), metadata_registration_va=hex(mr_va),
                   modules={k: dict(va=hex(v['va']), method_pointer_count=v['method_pointer_count']) for k, v in modules.items()},
                   resolved_nonzero=nonzero, total_methods=len(ms)),
              open(f'{WORK}/registrations.json','w'), indent=1)
    # save full model for dump.cs / dll generation
    model = dict(images=imgs, type_defs=tds, methods=ms, fields=fs, params=ps,
                 rva=rva, img_of_type={str(k): v for k, v in img_of_type.items()})
    json.dump(model, open(f'{WORK}/model.json','w'))
    print('model.json written')
