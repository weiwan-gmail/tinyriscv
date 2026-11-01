#!/usr/bin/env python3
"""Run every generated ISA .bin under iverilog."""
import os
import subprocess
import sys


def list_binfiles(path):
    files = []
    for maindir, _subdir, all_file in os.walk(path):
        for filename in all_file:
            apath = os.path.join(maindir, filename)
            if apath.endswith('.bin'):
                files.append(apath)
    return files


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    py = sys.executable
    sim = os.path.join(here, 'sim_new_nowave.py')
    bin_files = list_binfiles(os.path.join(here, '..', 'tests', 'isa', 'generated'))
    anyfail = False

    for file in bin_files:
        result = subprocess.run(
            [py, sim, file, 'inst.data'],
            cwd=here,
            capture_output=True,
            text=True,
        )
        text = (result.stdout or '') + (result.stderr or '')
        if 'TEST_PASS' in text:
            print(file + '    PASS')
        else:
            print(file + '    !!!FAIL!!!')
            print(text)
            anyfail = True
            break

    if not anyfail:
        print('Congratulation, All PASS...')
    return 1 if anyfail else 0


if __name__ == '__main__':
    sys.exit(main())
