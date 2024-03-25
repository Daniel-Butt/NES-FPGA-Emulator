import math
import struct
import pyperclip


def decode_nes_rom(file_path):
    rom_parts = {}

    with open(file_path, 'rb') as f:
        # Read and parse header
        header = f.read(16)
        rom_parts['header'] = header

        # Extract information from header
        prg_rom_size = struct.unpack('B', header[4:5])[0] * 0x4000
        chr_rom_size = struct.unpack('B', header[5:6])[0] * 0x2000

        # Read PRG ROM
        prg_rom_start = 16
        prg_rom_end = prg_rom_start + prg_rom_size
        f.seek(prg_rom_start)
        prg_rom_data = f.read(prg_rom_size)
        rom_parts['prg_rom'] = prg_rom_data

        # Read CHR ROM (if available)
        chr_rom_start = prg_rom_end
        f.seek(chr_rom_start)
        chr_rom_data = f.read(chr_rom_size)
        rom_parts['chr_rom'] = chr_rom_data

    return rom_parts


def prg_rom_to_mif(prg_rom, output_file, depth=32768):
    with open(output_file, 'w') as file:
        # Write Quartus MIF header
        file.write("WIDTH=8;\n")
        file.write("DEPTH={};\n".format(depth))
        file.write("ADDRESS_RADIX=HEX;\n")
        file.write("DATA_RADIX=HEX;\n")
        file.write("CONTENT BEGIN\n")

        # Write PRG ROM data to MIF file
        k = int(math.ceil(depth / len(prg_rom)))
        address = 0

        for i in range(k):
            for byte in prg_rom:
                file.write("{:X} : {:02X};\n".format(address, byte))
                address += 1

        # Write Quartus MIF footer
        file.write("END;\n")


def chr_rom_to_vhdl(chr_rom, name):

    s = "constant " + name.upper().replace(" ", "_") + "_CHR_ROM : CHR_ROM_ARRAY := ("

    for i in range(len(chr_rom) // 128):
        for byte in chr_rom[i*128:i*128+128]:
            s += "x\"{:02X}\", ".format(byte)

        s += "\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"

    s = s[:-18] + ");"

    pyperclip.copy(s)
    print("CHR ROM copied to clipboard")


if __name__ == "__main__":
    rom_name = "Mario Bros"
    directory = "EmptyVidorProject/games/"

    parts = decode_nes_rom(directory + rom_name + ".nes")

    prg_rom_to_mif(parts['prg_rom'], directory + rom_name + ".mif")

    chr_rom_to_vhdl(parts['chr_rom'], rom_name)
