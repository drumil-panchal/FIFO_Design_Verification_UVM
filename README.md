# FIFO Design & Verification (SystemVerilog + UVM)

## 📌 Overview
This project implements a **SystemVerilog FIFO** and verifies it using a **UVM-based constrained-random verification environment**.  
The testbench includes **self-checking scoreboards, reference modeling, and functional coverage** to ensure correctness across normal and corner-case scenarios.

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
- **Monitor:** Captures data, flags, and status signals and collects functional coverage
- **Scoreboard:**  
  - Implements a **reference FIFO model using an SV queue**  
  - Checks data ordering, flags, overflow & underflow behavior  
- **Agent / Env:** Modular, reusable UVM architecture

---

## 📊 Functional Coverage
Functional coverage is implemented inside the **monitor** using covergroups and crosses to ensure thorough verification.
### Covered Scenarios
- FIFO operations:
  - Idle
  - Write
  - Read
  - Simultaneous Read/Write
- FIFO states:
  - Empty
  - Full
- Error conditions:
  - Overflow
  - Underflow
- Data distribution:
  - Low / Mid / High input ranges
- Cross coverage:
  - Operations vs Empty/Full states
  - Overflow only when FIFO is full
  - Underflow only when FIFO is empty

### Coverage Results
- **Total Functional Coverage:** **93.66%**
- All key coverpoints hit
- Remaining uncovered bins correspond to intentionally ignored or non-meaningful scenarios


## ⭐ Key Features
- Full UVM compliance (sequencer, driver, monitor, scoreboard)
- Self-checking scoreboard with reference model
- Corner-case coverage: full, empty, overflow, underflow
- Simultaneous read/write verification
- Clean separation of design and verification
- Robust functional coverage to prevent false confidence