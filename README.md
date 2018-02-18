# A500_ACCEL_RAM_IDE-Rev-1
Initial design attempt for Amiga 500 in socket 68000 Accelerator, FastRAM and IDE Interface

### Warning
This design has not been compliance tested and will not be. It may cause damage to your A500. I take no responsibility for this.
I accept no responsibiltiy for any damage to any equipment that results from the use of this design and its components. IT IS ENTIRELY AT YOUR OWN RISK!

### Overview
The main purpose of this design was to become familiar with the Amiga 500 Hardware, Xilinx CPLDs (and the design tools) and the necessary aspects of what is needed to develop such hardware. This release was not and is not intended to be final. It is only for development purposes.

### Appearance
Before any real work started, the PCB was populated nicely and looked like this:
![Image of Top of PCB](/Images/Overview.jpg)

... and then it ended up looking like this:
![Image of Top of PCB](/Images/RastsNest.jpg)

I quickly realised that my chosen 44 PIN XC9572XL CPLD would have enough IO Pins so I needed to add another. Likely I took the approach a only routing the POWER, ADDRESS and DATA signals between the CPU and Amiga Motherbaord. All control signals are jumped. This was to allow easy debugging development. Here is a performace overview:
![SYSINFO Data](/Images/PerformanceOverview.jpg)

... and the Zorro II mappings:
![SYSINFO Data](/Images/ZorroIIMappings.jpg)
