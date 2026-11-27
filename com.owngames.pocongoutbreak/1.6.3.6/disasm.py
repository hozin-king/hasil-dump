#!/usr/bin/env python3
"""Disassemble an ARM64 .so range with capstone, resolving ADR/ADRP string refs and BL targets."""
import sys
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN
from capstone.arm64 import ARM64_OP_IMM, ARM64_OP_REG
from elftools.elf.elffile import ELFFile

def load(path):
    with open(path, 'rb') as f:
        data = f.read()
    ef = ELFFile(open(path, 'rb'))
    secs = {}
    for s in ef.iter_sections():
        secs[s.name] = (s['sh_addr'], s['sh_offset'], s['sh_size'])
    # dynsym addr -> name
    names = {}
    symtab = ef.get_section_by_name('.dynsym')
    if symtab:
        for sym in symtab.iter_symbols():
            if sym['st_value']:
                names[sym['st_value']] = sym.name
    return data, secs, names

def va_to_off(secs, va):
    for name, (addr, off, size) in secs.items():
        if addr <= va < addr + size:
            return off + (va - addr)
    return None

def read_cstr(data, secs, va, maxlen=160):
    off = va_to_off(secs, va)
    if off is None:
        return None
    end = data.find(b'\x00', off, off + maxlen)
    if end == -1:
        end = off + maxlen
    raw = data[off:end]
    try:
        s = raw.decode('utf-8')
    except UnicodeDecodeError:
        return None
    if len(s) >= 3 and all(32 <= ord(c) < 127 or c in '\n\t' for c in s):
        return s
    return None

def dis(path, start, end):
    data, secs, names = load(path)
    text_addr, text_off, text_size = secs['.text']
    code = data[text_off + (start - text_addr): text_off + (end - text_addr)]
    md = Cs(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN)
    md.detail = True
    md.skipdata = True
    last_adrp = {}
    for ins in md.disasm(code, start):
        extra = ''
        if ins.mnemonic in ('adr', 'adrp'):
            for op in ins.operands:
                if op.type == ARM64_OP_IMM:
                    # capstone gives ADR/ADRP op.imm as the resolved target address
                    tgt = op.imm
                    s = read_cstr(data, secs, tgt)
                    extra = ' ; -> 0x%x' % tgt + (' %r' % s if s else '')
                    last_adrp[ins.reg_name(ins.operands[0].reg)] = tgt
        elif ins.mnemonic == 'add':
            try:
                ops = ins.operands
                if len(ops) == 3 and ops[1].type == ARM64_OP_REG and ops[2].type == ARM64_OP_IMM:
                    reg = ins.reg_name(ops[1].reg)
                    if reg in last_adrp:
                        tgt = last_adrp[reg] + ops[2].imm
                        s = read_cstr(data, secs, tgt)
                        extra = ' ; -> 0x%x' % tgt + (' %r' % s if s else '')
            except Exception:
                pass
        elif ins.mnemonic in ('bl', 'b', 'b.eq', 'b.ne', 'b.lt', 'b.gt', 'b.le', 'b.ge', 'b.cs', 'b.cc', 'b.mi', 'b.pl', 'b.hi', 'b.ls'):
            try:
                for op in ins.operands:
                    if op.type == ARM64_OP_IMM:
                        tgt = op.imm
                        if tgt in names:
                            extra = ' ; -> ' + names[tgt]
            except Exception:
                pass
        print('0x%x:\t%s\t%s%s' % (ins.address, ins.mnemonic, ins.op_str, extra))

if __name__ == '__main__':
    dis(sys.argv[1], int(sys.argv[2], 16), int(sys.argv[3], 16))
