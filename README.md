# NES-FPGA-Emulator
An NES FPGA emulator for the Arduino MKR Vidor 4000 board (Intel Cyclone 10 LP). Western University Capstone project 2023-2024.

### Setup Instructions
1. Download and extract repo zip
2. Open NES Intel Quartus Prime project and compile
3. Run Python/ttf_fliper.py to convert the Quartus output_files/NES.ttf file into an Arduino compatible fpga_program.h file
4. Use the Arduino Sketch to upload the compiled design to the Vidor board

### Tests
Successfully complete the NESTEST rom for legal opcodes


Compatible with Mapper 0 games.<br/>

Tested playing the following games:<br/>
•    Donkey Kong <br/>
•    Donkey Kong Jr<br/>
•    Duck Hunt (no gun though)<br/>
•    Pinball<br/>
•    Wrecking Crew<br/>
•    Road Fighter<br/>
•    1942 (ww2 Galaga)<br/>
•    Ms. Pac Man<br/>
•    Tennis<br/>
•    Mario Bros (not super :( )<br/>

