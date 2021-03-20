#!/bin/bash

BIN_PATH=/home/nicholasrighi/gcc-arm-none-eabi-10-2020-q4-major/bin/arm-none-eabi

BIN_FILE=test

$BIN_PATH-objdump -d $BIN_FILE > sim_data/dissassembled_code
$BIN_PATH-objcopy --dump-section .text=sim_data/raw_code $BIN_FILE
hexdump -v sim_data/raw_code > sim_data/hex_code
python3 create_mem_files.py
rm verilog_src/instruction_mem.mem
cp sim_data/instruction_mem.mem verilog_src/