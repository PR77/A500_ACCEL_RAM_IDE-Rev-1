`timescale 1ns / 1ps
/*
    This file is part of A500_ACCEL_RAM_IDE originally designed by
    Paul Raspa 2017-2018.

    A500_ACCEL_RAM_IDE is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    A500_ACCEL_RAM_IDE is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with A500_ACCEL_RAM_IDE. If not, see <http://www.gnu.org/licenses/>.

    Revision 0.0 - 11.05.2017:
    Initial revision.

    Revision 1.0 - 07.01.2018:
    Maps 1MByte of FastRAM to AutoConfig location. MID 1977, PID 103.

    Revision 1.1 - 21/01/2018:
    Added support for two Autoconfig I/O spaces. MID 1977, PID 102, 101.
*/

module A500_RAM(

    // Control Inputs
    input RESET,
    input CPU_CLK,
    input CPU_RW,
    input CPU_AS,
    input CPU_UDS,
    input CPU_LDS,
    
    // Address Inputs
    input [6:0] ADDRESS_LOW,
    input [23:16] ADDRESS_HIGH,
    
    // Data Inputs / Outputs
    inout [15:12] DATA,
    
    // Internal cycle indication
    output INTERNAL_CYCLE,
    
    // RAM control outputs
    output CE_LOW, CE_HIGH,
    output OE_LOW, OE_HIGH,
    output WE_LOW, WE_HIGH,
    
    // IO port control outputs
    output IO_PORT_A_CS,
    output IO_PORT_B_CS
    );

reg [2:0] configured = 3'b000;
reg [2:0] shutup = 3'b000;
reg [3:0] autoConfigData = 4'b0000;
reg [7:0] autoConfigBaseFastRam = 8'b00000000;
reg [7:0] autoConfigBaseIOPortA = 8'b00000000;
reg [7:0] autoConfigBaseIOPortB = 8'b00000000;
reg writeStable = 1'b0;

wire DS = CPU_LDS & CPU_UDS;

wire AUTOCONFIG_RANGE = ({ADDRESS_HIGH[23:16]} == {8'hE8}) && ~&shutup && ~&configured;
wire AUTOCONFIG_READ = (AUTOCONFIG_RANGE && (CPU_RW == 1'b1));
wire AUTOCONFIG_WRITE = (AUTOCONFIG_RANGE && (CPU_RW == 1'b0));

wire FASTRAM_RANGE = ({ADDRESS_HIGH[23:20]} == {autoConfigBaseFastRam[7:4]}) && ~CPU_AS && configured[0];
wire FASTRAM_READ = (FASTRAM_RANGE && (CPU_RW == 1'b1) && (DS == 1'b0));
wire FASTRAM_WRITE = (FASTRAM_RANGE && (CPU_RW == 1'b0) && (writeStable == 1'b1));

wire IOPORTA_RANGE = ({ADDRESS_HIGH[23:20]} == {autoConfigBaseIOPortA[7:4]}) && ~CPU_AS && configured[1];
wire IOPORTA_READ = (IOPORTA_RANGE && (CPU_RW == 1'b1) && (DS == 1'b0));
wire IOPORTA_WRITE = (IOPORTA_RANGE && (CPU_RW == 1'b0) && (writeStable == 1'b1));

wire IOPORTB_RANGE = ({ADDRESS_HIGH[23:20]} == {autoConfigBaseIOPortB[7:4]}) && ~CPU_AS && configured[2];
wire IOPORTB_READ = (IOPORTB_RANGE && (CPU_RW == 1'b1) && (DS == 1'b0));
wire IOPORTB_WRITE = (IOPORTB_RANGE && (CPU_RW == 1'b0) && (writeStable == 1'b1));

// INTERNAL_CYCLE signalling is actually /INTERNAL_CYCLE as expected by Accelerator CPLD.
assign INTERNAL_CYCLE = ~(FASTRAM_RANGE || IOPORTA_RANGE || IOPORTB_RANGE);

// Generate a Write Stable signal for timing Bus Assertions after UDS || LDS are LOW.
always @(negedge CPU_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1)
        writeStable <= 1'b0;
    else begin
    
        if ((CPU_AS == 1'b0) && (CPU_RW == 1'b0) && (DS == 1'b0))
            writeStable <= 1'b1;
        else
            writeStable <= 1'b0;
    end
end        

// AUTOCONFIG cycle.
always @(negedge DS or negedge RESET) begin
    
    if (RESET == 1'b0) begin
        configured[2:0] <= 3'b000;
        shutup[2:0] <= 3'b000;
        autoConfigBaseFastRam[7:0] <= 8'h0;
        autoConfigBaseIOPortA[7:0] <= 8'h0;
        autoConfigBaseIOPortB[7:0] <= 8'h0;
    end else begin

       if (AUTOCONFIG_WRITE == 1'b1) begin
            // AutoConfig Write sequence. Here is where we receive from the OS the base address for the RAM.
            case (ADDRESS_LOW)
                8'h24: begin

                    if (configured[2:0] == 3'b000) begin
                        autoConfigBaseFastRam[7:4] <= DATA[15:12];     // FastRAM
                        configured[0] <= 1'b1;
                    end
                    
                    if (configured[2:0] == 3'b001) begin
                        autoConfigBaseIOPortA[7:4] <= DATA[15:12];     // IO Port A
                        configured[1] <= 1'b1;
                    end
                    
                    if (configured[2:0] == 3'b011) begin
                        autoConfigBaseIOPortB[7:4] <= DATA[15:12];     // IO Port B
                        configured[2] <= 1'b1;
                    end
                end

                8'h25: begin
                    if ({configured[2:0] == 3'b000}) autoConfigBaseFastRam[3:0] <= DATA[15:12];   // FastRAM
                    if ({configured[0] == 1'b1}) autoConfigBaseIOPortA[3:0] <= DATA[15:12];       // IO Port A
                    if ({configured[1] == 1'b1}) autoConfigBaseIOPortB[3:0] <= DATA[15:12];       // IO Port B
                end

                8'h26: begin
                    if ({configured[0] == 1'b1}) shutup[0] <= 1'b1;   // FastRAM
                    if ({configured[1] == 1'b1}) shutup[1] <= 1'b1;   // IO Port A
                    if ({configured[2] == 1'b1}) shutup[2] <= 1'b1;   // IO Port B
                end
                
            endcase
        end

        if (AUTOCONFIG_READ == 1'b1) begin
            // AutoConfig Read sequence. Here is where we publish the RAM and I/O port size and hardware attributes.
           case (ADDRESS_LOW)
                8'h00: begin
                    if ({configured[2:0] == 3'b000}) autoConfigData <= 4'hE;     // (00) FastRAM
                    if ({configured[2:0] == 3'b001}) autoConfigData <= 4'hC;     // (00) IO Port A
                    if ({configured[2:0] == 3'b011}) autoConfigData <= 4'hC;     // (00) IO Port B
                end
                
                8'h01: begin
                    if ({configured[2:0] == 3'b000}) autoConfigData <= 4'h5;     // (02) FastRAM
                    if ({configured[2:0] == 3'b001}) autoConfigData <= 4'h1;     // (02) IO Port A
                    if ({configured[2:0] == 3'b011}) autoConfigData <= 4'h1;     // (02) IO Port B
                end
                
                8'h02: autoConfigData <= 4'h9;     // (04)  
                
                8'h03: begin
                    if ({configured[2:0]} == {3'b000}) autoConfigData <= 4'h8;     // (06) FastRAM
                    if ({configured[2:0]} == {3'b001}) autoConfigData <= 4'h9;     // (06) IO Port A
                    if ({configured[2:0]} == {3'b011}) autoConfigData <= 4'hA;     // (06) IO Port B
                end

                8'h04: autoConfigData <= 4'h7;  // (08/0A)
                8'h05: autoConfigData <= 4'hF;
                
                8'h06: autoConfigData <= 4'hF;  // (0C/0E)
                8'h07: autoConfigData <= 4'hF;
                
                8'h08: autoConfigData <= 4'hF;  // (10/12)
                8'h09: autoConfigData <= 4'h8;
                8'h0A: autoConfigData <= 4'h4;  // (14/16)
                8'h0B: autoConfigData <= 4'h6;                
                
                8'h0C: autoConfigData <= 4'hA;  // (18/1A)
                8'h0D: autoConfigData <= 4'hF;
                8'h0E: autoConfigData <= 4'hB;  // (1C/1E)
                8'h0F: autoConfigData <= 4'hE;
                8'h10: autoConfigData <= 4'hA;  // (20/22)
                8'h11: autoConfigData <= 4'hA;
                8'h12: autoConfigData <= 4'hB;  // (24/26)
                8'h13: autoConfigData <= 4'h3;

                default: 
                    autoConfigData <= 4'hF;

            endcase
        end
     end
end

// Output specific AUTOCONFIG data.
assign {DATA[15:12]} = (AUTOCONFIG_READ == 1'b1) ? autoConfigData : 4'bZZZZ;

// RAM control arbitration.
assign CE_LOW = ~(FASTRAM_RANGE);
assign CE_HIGH = ~(FASTRAM_RANGE);
assign OE_LOW = ~(FASTRAM_READ && ~CPU_LDS);
assign OE_HIGH = ~(FASTRAM_READ && ~CPU_UDS);
assign WE_LOW = ~(FASTRAM_WRITE && ~CPU_LDS);
assign WE_HIGH = ~(FASTRAM_WRITE && ~CPU_UDS);

// IO port control arbitration.
assign IO_PORT_A_CS = ~(IOPORTA_READ || IOPORTA_WRITE);
assign IO_PORT_B_CS = ~(IOPORTB_READ || IOPORTB_WRITE);

endmodule
