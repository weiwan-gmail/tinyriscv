#!/usr/bin/env python3
"""Run iverilog/vvp against an already generated inst.data file in sim/."""
import os
import subprocess
import sys


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.abspath(os.path.join(here, '..'))
    py = sys.executable
    compile_rtl = os.path.join(here, 'compile_rtl.py')
    os.chdir(here)
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
