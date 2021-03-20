import os.path
import random as rand

MAX_INST_SIZE = 512

NOP = "46C0"

# Generate instruction mem
with open("sim_data/hex_code", "r") as source_file:
    with open("sim_data/instruction_mem.mem", "w") as cpu_data_file:

        # Track how many lines we've written so we can fill in blanks with zeros
        written_lines = 0

        for line in source_file:

            split_line = line.split()

            # Have reached end of source_file, no more data to parse
            if (len(split_line) == 1):
                break

            # extract instructions from line
            instruction_list = split_line[1:]

            for instruction in instruction_list:
                cpu_data_file.write(instruction + "\n")
                written_lines += 1


        for i in range(written_lines, MAX_INST_SIZE-1):
            cpu_data_file.write(NOP + "\n")

RO_DATA_OFFSET = 4096
DATA_SIZE = 8192
WORD_SIZE = 4

# Generate data mem
if os.path.isfile("sim_data/data_section.txt") and os.stat("sim_data/data_section.txt").st_size > 0:
    with open("sim_data/data_section.txt", "r") as source_file:
        with open("sim_data/data_mem.mem", "w") as cpu_data_file:

            lines_written = 0

            # print empty lines for correct data offset
            for i in range(RO_DATA_OFFSET//WORD_SIZE):
                cpu_data_file.write("00000000\n")
                lines_written += 1

            for line in source_file:

                split_line = line.split()

                # Have reached end of source_file, no more data to parse
                if (len(split_line) == 1):
                    break

                # remove address from front of file
                data_list = split_line[1:]

                for i in range(0, len(data_list)//2):
                    lines_written += 1 
                    lower_half_word = data_list[2*i]
                    upper_half_word = data_list[2*i+1]
                    cpu_data_file.write(upper_half_word[0:2])
                    cpu_data_file.write(upper_half_word[2:])
                    cpu_data_file.write(lower_half_word[0:2])
                    cpu_data_file.write(lower_half_word[2:])
                    cpu_data_file.write("\n")

            for i in range(lines_written, DATA_SIZE//WORD_SIZE):
                cpu_data_file.write("00000000\n")
# Data memory doesn't exist, fill with zeros
else: 
    with open("sim_data/data_mem.mem", "w") as cpu_data_file:
        for i in range(DATA_SIZE//WORD_SIZE):
            cpu_data_file.write("00000000\n")
        

