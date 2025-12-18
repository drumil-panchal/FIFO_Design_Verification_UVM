# FIFO Design & Verification (SystemVerilog + UVM)

## 📌 Overview
This project implements and verifies a **16-deep, 8-bit synchronous FIFO** using **SystemVerilog** and a **full UVM-based verification environment**.  
The design supports **simultaneous read/write**, **full/empty detection**, and **overflow/underflow flagging**, while the UVM testbench validates all corner cases using multiple directed and randomized sequences.

---

## 📁 Structure
rtl/ → FIFO RTL design + interface
tb/ → UVM environment:
- transaction
- sequences (write, read, overflow, simultaneous R/W)
- driver
- monitor
- scoreboard (reference FIFO model)
- agent, environment, test

---

## 🧠 FIFO Design Highlights
- 16×8 FIFO memory
- Write pointer / Read pointer based control
- Full & Empty flag generation
- Overflow detection on write when full
- Underflow detection on read when empty
- Correct handling of simultaneous read & write

---

## 🧪 Verification Strategy (UVM)
- **Sequences:**  
  - Write-only  
  - Read-only (underflow)  
  - Write → Read  
  - Overflow stress  
  - Simultaneous read/write  

- **Driver:** Drives `wr`, `rd`, `din` and handles reset  
- **Monitor:** Captures data, flags, and status signals  
- **Scoreboard:**  
  - Implements a **reference FIFO model using an SV queue**  
  - Checks data ordering, flags, overflow & underflow behavior  
- **Agent / Env:** Modular, reusable UVM architecture

---

## ⭐ Key Features
- Full UVM compliance (sequencer, driver, monitor, scoreboard)
- Self-checking scoreboard with reference model
- Corner-case coverage: full, empty, overflow, underflow
- Simultaneous read/write verification
- Clean separation of design and verification