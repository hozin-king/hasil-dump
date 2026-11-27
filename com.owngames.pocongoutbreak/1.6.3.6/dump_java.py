#!/usr/bin/env python3
"""Dump methods of target classes from classes.dex with string/method refs."""
import sys
from loguru import logger
logger.remove()
from androguard.core.dex import DEX

dex = DEX(open('classes.dex', 'rb').read())

def find_methods(class_name):
    for cls in dex.get_classes():
        if cls.get_name() == class_name:
            return cls
    return None

def dump_method(m):
    print('  METHOD:', m.get_name(), m.get_descriptor())
    code = m.get_code()
    if code is None:
        print('    (no code - native/abstract)')
        return
    insns = list(code.get_bc().get_instructions())
    print('    insns:', len(insns))
    for i, ins in enumerate(insns):
        print('    [%d] %s %s' % (i, ins.get_name(), ins.get_output()))

targets = sys.argv[1:]
for t in targets:
    cls = find_methods(t)
    if cls is None:
        print('CLASS NOT FOUND:', t)
        continue
    print('CLASS:', t, ' superclass:', cls.get_superclassname())
    for m in cls.get_methods():
        dump_method(m)
    print()
