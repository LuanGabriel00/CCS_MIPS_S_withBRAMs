# Complex Computing System (MIPS_S_withBRAMs)

![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)
![Language](https://img.shields.io/badge/Language-VHDL%20%7C%20Assembly-blue)
![Platform](https://img.shields.io/badge/Platform-FPGA%20Nexys%202-orange)

## About the Project
This repository contains the development of **Assignment T4**, whose general objective is to handle the complex computing system `MIPS_S_withBRAMs` and develop the hardware of a Peripheral capable of interacting with it.

The development follows an incremental hardware/software co-design approach, culminating in the transfer and visualization of data between a peripheral's memory and the processor's data memory.

## Structure and Development Stages

The project is divided into 4 main stages:

* **Project 1 - Base Simulation:** Simulating the MIPS system hardware executing basic applications (`SomaVet.asm`) using the MARS simulator and Xilinx tools to master the BRAM memory structure.
* **Project 2 - Software (MIPS Assembly):** Developing an assembly language software capable of performing a mass data copy (similar to `strcpy`), transferring a large amount of text data (an excerpt from *Romeo and Juliet*) to the MIPS_S data memory.
* **Project 3 - Integrated Simulation:** Adapting and simulating the software generated in Project 2 running directly on the simulated hardware of the `MIPS_S_Sim` system, validating its execution.
* **Project 4 - Hardware (VHDL):** Creating the top module and the Peripheral interconnected to the MIPS interface. The peripheral features:
    * An independent state machine and local memory.
    * Interface with the outside world through buttons, slide switches, an LED, and a 7-segment display.
    * Memory-Mapped I/O (MMIO) communication to suspend the processor, transfer data, and control byte-by-byte or word-by-word visualization.

## Technologies Used
* **Languages:** VHDL (Hardware Description), MIPS Assembly (Software).
* **Simulation:** MARS (MIPS Assembler and Runtime Simulator).
* **Synthesis and Prototyping:** Xilinx ISE / Vivado.
* **Target Hardware:** Nexys 2 FPGA Board (Due to the project's requirement of 17 BRAMs).

---
*Project developed as an academic requirement for mastering Complex Computing Systems.*
