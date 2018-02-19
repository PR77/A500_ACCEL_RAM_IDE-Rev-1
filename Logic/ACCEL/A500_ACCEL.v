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

    Revision 0.0 - 17.01.2018:
    Initial revision.

    Revision 1.0 - 09.02.2018:
    Added support for asynchronous clocking and /INTERNAL_CYCLE support.
*/

module A500_ACCEL(
    
    // Control Inputs and Outputs
    input RESET,
    input MB_CLK,
    input CPU_CLK,
    
    input CPU_AS,
    output MB_AS,
       
    input MB_DTACK,
    output CPU_DTACK,
    
    output MB_E_CLK,
    input MB_VPA,    
    output MB_VMA,
        
    input [2:0]	FC,
    
    input INTERNAL_CYCLE
    );
    
reg delayedMB_AS = 1'b1;
reg delayedMB_DTACK = 1'b1;
reg fastCPU_DTACK = 1'b1;

wire emulated_DTACK;

assign MB_AS = delayedMB_AS;
assign CPU_DTACK = emulated_DTACK & delayedMB_DTACK & fastCPU_DTACK;

MC6800 MC6800EMULATION(
    .RESET  (RESET),
    .CLK    (MB_CLK),
    .E_CLK  (MB_E_CLK),
    .VPA    (MB_VPA),    
    .VMA    (MB_VMA),
    .DTACK  (emulated_DTACK),
    .AS     (CPU_AS),
    .FC     (FC)
    );

// Shift /CPU_AS into the 7MHz clock domain gated by /INTERNAL_CYCLE.
// Delay /MB_DTACK by 1 7MHz clock cycle to sync up to asynchronous CPU_CLK.
always @(posedge MB_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1) begin
        delayedMB_DTACK <= 1'b1;
        delayedMB_AS <= 1'b1;
    end else begin
    
        delayedMB_AS <= CPU_AS | ~INTERNAL_CYCLE;
        
        /*
        delayedMB_DTACK <= MB_DTACK | delayedMB_AS;
        */
        
        delayedMB_DTACK <= MB_DTACK;
    end
end

// Generate a fast DTACK for accesses in Interal Space (FastRAM, IO Portetc)
always @(posedge CPU_CLK or posedge CPU_AS) begin
    
    if (CPU_AS == 1'b1) begin
        fastCPU_DTACK <= 1'b1;
    end else begin
    
        fastCPU_DTACK <= INTERNAL_CYCLE;
    end
end

endmodule
