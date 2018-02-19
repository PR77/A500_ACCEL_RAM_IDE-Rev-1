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

    Revision 0.0 - 02.01.2018:
    Initial revision. Majority concept taken from TerribleFire TF530 design.
    Refer to <https://github.com/terriblefire/tf530>.
*/

module MC6800(

    input RESET,

    input CLK,
        
    output reg E_CLK,
    input VPA,    
    output VMA,
    output DTACK,

    input AS,
    input [2:0]	FC
    );

reg [3:0] eClockRingCounter = 'h4;
reg generatedVMA = 1'b1;
reg generatedDTACK = 1'b1;

wire CPUSPACE = &FC;

// Let's get the 709379 Hz E_CLOCK out the way by creating it from the motherboard base 7MHz Clock.
always @(posedge CLK) begin
    
    if (eClockRingCounter == 'd9) begin
        eClockRingCounter <= 'd0;
        
    end else begin
    
        eClockRingCounter <= eClockRingCounter + 'd1;

        if (eClockRingCounter == 'd4) begin
            E_CLK <= 'b1;       
        end

        if (eClockRingCounter == 'd8) begin
            E_CLK <= 'b0;
        end
    end
end

// Determine if current Bus Cycle is a 6800 type where VPA has been asserted.
always @(posedge CLK or posedge VPA) begin

    if (RESET == 1'b0) begin
        generatedVMA <= 1'b1;
    end

    if (VPA == 1'b1) begin
        generatedVMA <= 1'b1;
    end else begin

        if (eClockRingCounter == 'd9) begin
            generatedVMA <= 1'b1;
        end

        if (eClockRingCounter == 'd2) begin
            generatedVMA <= VPA | CPUSPACE;
        end
    end
end

// Generate /DTACK if 6800 Bus Cycle has been emulated (generatedVMA).
always @(posedge CLK or posedge AS) begin
    
    if (RESET == 1'b0) begin
        generatedDTACK <= 1'b1;
    end
    
    if (AS == 1'b1) begin
        generatedDTACK <= 1'b1;
    end else begin
               
        if (eClockRingCounter == 'd9) begin
            generatedDTACK <= 1'b1;
        end

        if (eClockRingCounter == 'd8) begin
            generatedDTACK <= generatedVMA;
        end
    end 
end

assign VMA = generatedVMA;
assign DTACK = generatedDTACK;

endmodule
