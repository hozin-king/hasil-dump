#!/usr/bin/env python3
"""Scan ARM64 .text for BL calls to given targets; print call sites."""
import sys
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
from capstone.arm64 import ARM64_OP_IMM
from elftools.elf.elffile import ELFFile

path = sys.argv[1]
targets = set(int(x, 16) for x in sys.argv[2:])
with open(path, 'rb') as f:
    data = f.read()
ef = ELFFile(open(path, 'rb'))
secs = {s.name: (s['sh_addr'], s['sh_offset'], s['sh_size']) for s in ef.iter_sections()}
taddr, toff, tsize = secs['.text']
code = data[toff:toff+tsize]
md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
md.detail = True
md.skipdata = False
for ins in md.disasm(code, taddr):
    if ins.mnemonic == 'bl':
        for op in ins.operands:
            if op.type == ARM64_OP_IMM and op.imm in targets:
                print('0x%x -> 0x%x' % (ins.address, op.imm))
