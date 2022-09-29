VERILATEOR 		= verilator
TESTBENCH_DIR 	= ./testbench
TARGET 			= ahb_master

VC_FLAGS 		+= -CFLAGS -I./src
VC_FLAGS 		+= -CFLAGS -g

V_FLAGS 		= -Wall -cc --trace --exe

run: binary
	@ ./obj_dir/V$(TARGET)

binary: verilate
	@ make -C ./obj_dir -f V$(TARGET).mk --silent

verilate:
	@ verilator $(V_FLAGS) $(VC_FLAGS) $(TARGET).sv $(TESTBENCH_DIR)/tb_$(TARGET).cpp

lint:
	$(VERILATEOR) --lint-only $(TARGET).sv

clean:
	-rm -rf ./obj_dir/*
