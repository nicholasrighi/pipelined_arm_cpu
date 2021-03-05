TARGET=decode_block

build:
	sv2v --write=adjacent *.sv
	yosys -p 'synth_ice40 -top $(TARGET)' *.v

clean:
	rm *.v
