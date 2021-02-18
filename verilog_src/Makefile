
TARGET=clocked_reg_file

build:
	rm *.v
	sv2v --write=adjacent *.sv
	yosys -p 'synth_ice40 -top $(TARGET)' *.v

clean:
	rm *.v
