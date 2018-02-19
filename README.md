# A500_ACCEL_RAM_IDE-Rev-1
Initial design attempt for Amiga 500 in socket 68000 Accelerator, FastRAM and IDE Interface

### Warning
This design has not been compliance tested and will not be. It may cause damage to your A500. I take no responsibility for this. I accept no responsibility for any damage to any equipment that results from the use of this design and its components. IT IS ENTIRELY AT YOUR OWN RISK!

### Overview
The main purpose of this design was to become familiar with the Amiga 500 Hardware, Amiga AUTOCONFIG (C) (referred to future as AutoConfig), Zorro II, Xilinx CPLDs (and the design tools) and the necessary aspects of what is needed to develop such hardware. This release was not and is not intended to be final. It is only for development purposes and to unearth 20 years of forgotten MC68000 knowledge.

### Appearance
Before any real work started, the PCB was populated nicely and looked like this:
![Populated PCB](/Images/Overview.jpg)

... and then it ended up looking like this:
![Jumpered PCB](/Images/RastsNest.jpg)

I quickly realised that my chosen 44 PIN XC9572XL CPLD would have enough IO Pins so I needed to add another (the nicely mounted CPLD handles the FastRAM and IO Port interface with AutoConfig and the second CPLD stuck on the RAM chips handles the Accelerator logic). Luckily I took the approach of only routing the POWER, ADDRESS and DATA signals between the CPU and Amiga Motherbaord. All control signals are jumped. This was to allow easy debugging development.

My initial design goals were to:

1. AutoConfig working at 7MHz (PAL) with no FastRAM.
2. FastRAM automatically added to the Free Memory Pool via AutoConfig parameterisation.
3. CPU Acceleration at synchronised 14MHz (CPUCLK ^ CDAC).
4. Finally asynchronous clocking with an external crystal (not shown loaded in the previous picture).

Here is a performance overview with all four goals achieved (the 68000 I have on hand is the MC68000P12 16MHz so anything significantly faster than 18.4MHz is unstable- so I limited to 18.4MHz):
![SYSINFO Speed](/Images/PerformanceOverview.jpg)

... and the Zorro II mappings:
![SYSINFO Boards](/Images/ZorroIIMappings.jpg)

### CPLD Logic
Contained within the "Logic" folder are two elements;

#### RAM
The A500_RAM top level design implements the AutoConfig protocol and memory decoding on a pseudo Zorro II bus which is actually directly coupled with the target 68000 on the Amiga 500 Motherboard. This devices handles the FastRAM /CS, /OE and /WR. In addition is generates two /CS signals for two AutoConfig 64K IO Port interfaces.

Any memory access to these memory spaces (FastRAM or IO Port) an external signal /INTERNAL_CYCLE is generated which is used by the ACCEL CPLD to override the GARY /DTACK generation (see below).

#### ACCEL
The A500_ACCEL top level design implements a MC6800 synchronous bus cycles emulator by creating the /VMA (and necessary /DTACK) and E signals based on the Amiga Motherboard /VPA request. The purpose of this is to decouple this interface from the target CPU for two reasons:

1. Simplify asynchronous clocking.
2. Future proof the design to allow for Rev 2 to support MC68SEC000 which do not have the MC6800 interface BUT can be clocked above 16MHz.

In addition to the MC6800 bus cycle emulator, the A500_ACCEL design also handle the pseudo Amiga /OVR signal for the /INTERNAL_CYCLE bus cycle to allow for a fast /DTACK (0 wait state). This means FastRAM or IO Port access do not assert the /AS from the CPU to the Amiga Motherboard. When one of these bus cycles occurs the Amiga essentially does not know anything is happening and will simple consider the CPU is busy. This is essentially the same the /OVR but avoids jumper wires to GARY and has the added benefit that Amiga Motherbaord address decoding will still occur.

Lastly the A500_ACCEL design handles clock domain synchroniation between the Amiga 7MHz clock and the asynchronously clocked MC68000. This sounds complex but is actually fairly simple where the CPU /AS to Amiga Motherboard /AS and the Amiga Motherboard /DTACK to the CPU /DTACK and only latch on rising edges of the 7MHz clock. Anything occurring during an /INTERNAL_CYCLE bus cycle the CPU /DTACK is simply asserted 1 clock after (0 wait state).
