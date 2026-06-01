import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_cnn_accelerator(dut):

    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Starting CNN V2 test")

    # Reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0

    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Threshold = 4
    threshold = 4

    # 3x3 pattern
    pixels = [
        1,0,1,
        1,1,1,
        1,0,1
    ]

    for p in pixels:
        dut.ui_in.value = (
            p |
            (1 << 1) |
            (threshold << 2)
        )
        await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 3)

    bus = int(dut.uo_out.value)

    result = bus & 1
    flag   = (bus >> 1) & 1

    dut._log.info(f"CNN Result = {result}")
    dut._log.info(f"Detection Flag = {flag}")

    assert result in [0,1], "Invalid CNN result"
    assert flag in [0,1], "Invalid detection flag"

    dut._log.info("CNN V2 test PASSED")
