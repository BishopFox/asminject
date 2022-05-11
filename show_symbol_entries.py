#!/usr/bin/env python3
# test script to help build emulation of the original dlinject.py

import argparse
import elftools.elf.sections
import os

from elftools.elf.elffile import ELFFile

def list_elf_symbols(elf_path):
    with open(elf_path, "rb") as elf_file:
        elf = ELFFile(elf_file)
        #symtab = elf.get_section_by_name(".symtab")
        #if not symtab:
        #    print("Section .symtab not found")
        #    return None
        for elf_section in elf.iter_sections():
            is_symbol_section = False
            
            if isinstance(elf_section, elftools.elf.sections.SymbolTableSection):
                is_symbol_section = True
            #if isinstance(elf_section, elftools.elf.gnuversions.GNUVerSymSection):
            #    is_symbol_section = True
            
            if is_symbol_section:
                print(f"{elf_section.name}\t{elf_section}")
                for symbol in elf_section.iter_symbols():
                    print(f"\t{symbol.name}\t{hex(symbol.entry.st_value)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="List symbol table entries using elftools Python library")

    parser.add_argument("elf_path", type=str, help="Path to the ELF binary to analyze")

    args = parser.parse_args()

    elf_path = os.path.abspath(args.elf_path)
    
    list_elf_symbols(elf_path)
    