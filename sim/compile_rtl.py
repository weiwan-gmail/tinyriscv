#!/usr/bin/env python3
"""Compile tinyriscv RTL + testbench with Icarus Verilog."""
import os
import subprocess
import sys


def main():
    raw = sys.argv[1] if len(sys.argv) > 1 else '..'
    # compliance_test.py historically passes '../..' (from sim/compliance_test).
    use_compliance = ('--compliance' in sys.argv) or (
        os.path.normpath(raw) in ('../..', r'..\..')
    )
    rtl_dir = os.path.abspath(raw)

    if use_compliance:
        tb_file = os.path.join(rtl_dir, 'tb', 'compliance_test', 'tinyriscv_soc_tb.v')
    else:
        tb_file = os.path.join(rtl_dir, 'tb', 'tinyriscv_soc_tb.v')

    iverilog_cmd = ['iverilog', '-o', 'out.vvp', '-I', os.path.join(rtl_dir, 'rtl', 'core')]
    iverilog_cmd += ['-D', r'OUTPUT="signature.output"']
    # nowave scripts skip VCD by default; set DUMP_WAVE=1 to keep gtkwave dumps.
    if os.environ.get('DUMP_WAVE', '0') != '1':
        iverilog_cmd += ['-D', 'NO_WAVE']
    iverilog_cmd.append(tb_file)

    rel_sources = [
        'rtl/core/clint.v',
        'rtl/core/csr_reg.v',
        'rtl/core/ctrl.v',
        'rtl/core/defines.v',
        'rtl/core/div.v',
        'rtl/core/ex.v',
        'rtl/core/id.v',
        'rtl/core/id_ex.v',
        'rtl/core/if_id.v',
        'rtl/core/pc_reg.v',
        'rtl/core/regs.v',
        'rtl/core/rib.v',
        'rtl/core/tinyriscv.v',
        'rtl/perips/ram.v',
        'rtl/perips/rom.v',
        'rtl/perips/timer.v',
        'rtl/perips/uart.v',
        'rtl/perips/gpio.v',
        'rtl/perips/spi.v',
        'rtl/debug/jtag_dm.v',
        'rtl/debug/jtag_driver.v',
        'rtl/debug/jtag_top.v',
        'rtl/debug/uart_debug.v',
        'rtl/soc/tinyriscv_soc_top.v',
        'rtl/utils/full_handshake_rx.v',
        'rtl/utils/full_handshake_tx.v',
        'rtl/utils/gen_buf.v',
        'rtl/utils/gen_dff.v',
    ]
    iverilog_cmd.extend(os.path.join(rtl_dir, p) for p in rel_sources)

    print(' '.join(iverilog_cmd), flush=True)
    subprocess.run(iverilog_cmd, check=True)


if __name__ == '__main__':
    sys.exit(main())
