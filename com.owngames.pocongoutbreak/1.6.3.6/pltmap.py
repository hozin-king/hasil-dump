#!/usr/bin/env python3
"""Build PLT stub address -> imported symbol name map for an ARM64 .so."""
import sys
from elftools.elf.elffile import ELFFile
from elftools.elf.relocation import RelocationSection

def plt_map(path):
    ef = ELFFile(open(path, 'rb'))
    plt = ef.get_section_by_name('.plt')
    rela = ef.get_section_by_name('.rela.plt')
    dynsym = ef.get_section_by_name('.dynsym')
    plt_addr = plt['sh_addr']
    # AArch64 PLT: PLT0 is 16 bytes, then one 16-byte entry per relocation, in order
    out = {}
    for i, rel in enumerate(rela.iter_relocations()):
        sym_idx = rel['r_info_sym']
        sym = dynsym.get_symbol(sym_idx)
        stub = plt_addr + 16 * (i + 1)
        out[stub] = sym.name
    return out

if __name__ == '__main__':
    m = plt_map(sys.argv[1])
    print(len(m), 'PLT entries')
    for addr in sorted(m):
        print(hex(addr), m[addr])
