amiga_cross_coding_install_vbcc

Script installs amiga cross compiling toolchain into users home.
Target platform: amiga 68000 Kickstart/WB 1.3 and 2.x/3.x

* Checks for and installs missing system packages, 
tested for Debian Scratch Stable and debian Buster stable

* Downloads and installs the needed amiga SDK tools,
and adds proper enviroment settings.

Usage
-----

$0 <RESOURCES_PATH> [BINARY_PATH] 
 
 - RESOURCES_PATH is a temporary folder to download and unpack stuff

 - BINARY_PATH is where all is copied and patched, 
   and where the system environment shall points to. 

   defaults to \${HOME}/.local/bin/
   
 - all variable-export are gathered into BINARY_PATH/set_vbcc_environment.sh
   You just may source it at startup.

Inspired by (Cross Development for the Amiga with VBCC Wei-ju Wu (2016))[https://www.youtube.com/watch?v=vFV0oEyY92I]
Have a look at the source of many tools: http://sun.hasenbraten.de/vbcc/ .

Toolchain
---------

 - vbcc (C-Compiler) ISO/IEC 9899:1989 and a subset of the new standard
   ISO/IEC 9899:1999 (C99) for amiga 68000 CPU and kickstart 1.3 or
   2.x/3.x
 - vasm (assembler)
 - vlink (linker)
 - NDK3.9 (Amiga OS headers and libraries)
   Maybe you also want this Amiga System headers and resources
   https://www.haage-partner.de/download/AmigaOS/NDK39.lha

You already set up an (FS-UAE?) emulator with shared volume
where the build binaries are put and executed inside emulation.


Install Cross Tools
-------------------

print usage:

    install_amiga68k_crosscompiler.sh

e.g. 

	install_amiga68k_crosscompiler.sh ./tmp
	source ~/.local/bin/set_vbcc_environment.sh

Folder $NKD_INC holds amiga system c-headers 
and $NKD_INC/../include_i holds assembler includes


Call vbcc C-Compiler
--------------------

Call to compile example.c and add needed amiga libs and automatically
open and close the amiga OS libraries (avoiding setup/teardown
boilerplate code).

    vc +kick13 -c99 -I$NDK_INC example.c -lamiga -lauto -o example

You can then execute the binary "example" within emulation, e.g. via shared folder of FS-UAE

Call vasm Assembler
-------------------

This is a snippet from my example Makefile:

	# this project only uses assembly, no intermediate .o files
	AS          = vasmm68k_mot
	AS_FLAGS    = -kick1hunks -Fhunkexe -nosym 
	
	%: %.asm
        $(AS) $(AS_FLAGS) -o $@ $<


