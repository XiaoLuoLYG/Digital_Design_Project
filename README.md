# Digital Design Project

Author: Yige Luo

Description: AHB and AXI master




## Directory Structure
```
|-- ahb_master.sv 			# AHB master source file
|-- ahb.sv 				# AHB package definition file
|-- axi_master.sv 			# AXI master source file
|-- rtl.f 				# Filelist for vcs compilation
|-- run.vcs.bat 			# Execute vcs compilation 
|-- README.md 				# This file
|-- testbench 				# Testbench folder
    |-- axi4.hpp			# AXI4 header file
    |-- axi4_mem.hpp 			# AXI4 memory header file
    |-- axi4_slave.hpp			# AXI4 slave header file
    |-- tb_ahb_master.cpp		# AHB testbench for read and write channel
    |-- tb_axi_master.cpp 		# AXI testbench for writing data to slave
```
## Quick Start Guide
1.Install verilator and gcc with correct version
2.`make run`
3.Open the .vcd file using any waveform viewer (verdi/gtkwave recommended)

## Building the Environment (CentOS 7)
(Note: for convenient purpose, a config file that autoinstall these tools might be written.)

Tools you need:
1. Verilator (see source file here:https://github.com/verilator/verilator and quick installation guide:https://verilator.org/guide/latest/install.html)

2. gcc(if not automatically install with the verilator)
installation guide: https://gcc.gnu.org/install/index.html

3. Others
- vcs for optional compilation (2018.09sp2)
- verdi to open waveform (2018.09sp2)

## RTL Simulation

Once setup the environment, `cd` into your local directory (contain the Makefile)

`make` or `make run`

This will lint the default .sv file (ahb_master.sv), create object directory (/obj_dir) and run the corresponding testbench. The waveform will be saved in a .vcd file, which can be opened by any waveform viewers.

If everything runs smoothly, a short test message will be displayed:
```
data retrived from AHB: 16 20 24 ...
data read from slave: 16 20 24 ...
```

To change the target file, use:

`make run TARGET=axi_master`

Similar message will be displayed.

To clean the object directory:

`make clean`

To lint the source file:

`make lint`

To see the waveform using verdi:
1.Open verdi and import source file
2.Click new waveform
3.Click open dump file within the waveform window
4.Change the file filter to `*.*`
5.Select the desired .vcd file
6.A corresponding FSDB file will be generated and loaded to view


## VCS Compilation 

`run.vcs.bat`

This will automatically vcs compile the files listed in rtl.f 
A vcs.compile.log will be generated for debugging purpose.(2 folders and a simv executable will also be generated)
