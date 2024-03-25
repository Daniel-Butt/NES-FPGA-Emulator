## Generated SDC file "EmptyVidorProject.out.sdc"

## Copyright (C) 2020  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition"

## DATE    "Sat Mar 02 19:43:49 2024"

##
## DEVICE  "10CL016YU256C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK} -period 20.833 -waveform { 0.000 10.416 } [get_ports {CLOCK}]
create_clock -name {PPU:inst9|clk_out} -period 40.000 -waveform { 0.000 20.00 } [get_registers {PPU:inst9|clk_out}]
create_clock -name {PPU:inst9|VGA_CLK} -period 40.000 -waveform { 0.000 20.00 } [get_registers {PPU:inst9|VGA_CLK}]
create_clock -name {CLKDIV:inst4|CLK_OUT~reg0} -period 40.000 -waveform { 0.000 20.00 } [get_registers {CLKDIV:inst4|CLK_OUT~reg0}]
create_clock -name {MemoryController:inst8|DMA_WRITE} -period 40.000 -waveform { 0.000 20.00 } [get_registers {MemoryController:inst8|DMA_WRITE}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {inst6|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {inst6|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 25 -divide_by 24 -master_clock {CLOCK} [get_pins {inst6|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {inst6|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {inst6|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 125 -divide_by 48 -master_clock {CLOCK} [get_pins {inst6|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -rise_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|clk_out}] -fall_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {inst6|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {PPU:inst9|clk_out}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {CLKDIV:inst4|CLK_OUT~reg0}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {PPU:inst9|VGA_CLK}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -rise_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -fall_to [get_clocks {PPU:inst9|VGA_CLK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -rise_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {MemoryController:inst8|DMA_WRITE}] -fall_to [get_clocks {MemoryController:inst8|DMA_WRITE}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

