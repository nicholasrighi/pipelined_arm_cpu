TARGET=arm_cpu

build:
	sv2v --write=adjacent *.sv
	yosys -p 'synth_ice40 -top $(TARGET)' *.v > build_log

clean:
	rm *.v build_log
