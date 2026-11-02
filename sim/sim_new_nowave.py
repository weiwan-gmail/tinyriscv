#!/usr/bin/env python3
"""Convert a firmware .bin to inst.data, compile RTL, and run iverilog/vvp.

Safe to invoke from the repo root or from sim/. Paths are resolved against
this file's location; inst.data / out.vvp are written in sim/.
"""
import os
import subprocess
import sys


def main():
    if len(sys.argv) < 3:
        print('Usage: %s <firmware.bin> <inst.data>' % sys.argv[0])
        return 2

    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.abspath(os.path.join(here, '..'))
    py = sys.executable
    firmware = os.path.abspath(sys.argv[1])
    inst_arg = sys.argv[2]
    inst_path = inst_arg if os.path.isabs(inst_arg) else os.path.join(here, inst_arg)

    bin_to_mem = os.path.join(repo, 'tools', 'BinToMem_CLI.py')
    compile_rtl = os.path.join(here, 'compile_rtl.py')

    os.chdir(here)
    subprocess.run([py, bin_to_mem, firmware, inst_path], check=True)
    subprocess.run([py, compile_rtl, repo], check=True)

    timeout_s = float(os.environ.get('VVP_TIMEOUT', '30'))
    try:
        result = subprocess.run(['vvp', 'out.vvp'], timeout=timeout_s)
    except subprocess.TimeoutExpired:
        print('!!!Fail, vvp exec timeout!!!')
        return 1
    return result.returncode


if __name__ == '__main__':
    sys.exit(main())
