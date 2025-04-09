# Automatic Synthesis Flow using Cadence Genus

These set of scripts to automate the digital logic synthesis process for multiple hardware designs across various target clock periods using the Cadence Genus synthesis tool.

## Overview

The flow consists of two main scripts:

1.  **`run_synthesis.sh`**: A Bash script that acts as the main driver. It iterates through a predefined list of designs and clock periods, sets up the necessary environment variables for each run (design name, top module, clock port, RTL file paths, period), and invokes the Genus synthesis tool.
2.  **`synthesis_flow.tcl`**: A Tcl script containing the specific commands executed by Genus for a single synthesis run. It reads configuration from environment variables, sets up the Genus environment, reads the design RTL and libraries, applies clock constraints, performs synthesis , and generates output reports and files (netlist, SDC).

## Inputs

The synthesis flow requires the following inputs:

1.  **Configuration (within `run_synthesis.sh`):**
    *   `PROJECT_DIR`: Path to the root project directory. **Must be correctly set.**
    *   `designs`: Array of design identifiers to synthesize.
    *   `periods`: Array of target clock periods (in nanoseconds) to synthesize for.
    *   Design-Specific Settings (in the `case` statement): `TOP_MODULE`, `CLOCK_PORT`, `RTL_DIR`, `RTL_DIR2` (optional).
2.  **Standard Cell Library:**
    *   Specified by `LIB_PATH` in `run_synthesis.sh`. Example: `${PROJECT_DIR}/inputs/lib/fast_vdd1v0_basicCells.lib`. Contains standard cell definitions, timing, and power information.
3.  **RTL Source Code:**
    *   Verilog (`.v`) files located in the directories specified by `RTL_DIR` (and optionally `RTL_DIR2`) for each design.

## Outputs

For each successful synthesis run (`DESIGN` and `PERIOD` combination), the following outputs are generated within a structured directory:

*   **Output Directory:** `${PROJECT_DIR}/synthesis/outputs/work/${DESIGN}_period_${PERIOD}/`

*   **Files Generated:**
    *   `reports/report_timing.rpt`: Timing analysis report.
    *   `reports/report_power.rpt`: Power estimation report.
    *   `reports/report_area.rpt`: Area utilization report.
    *   `reports/report_qor.rpt`: Quality of Result (QoR) summary report.
    *   `outputs/${TOP_MODULE}_netlist.v`: Synthesized gate-level Verilog netlist.
    *   `outputs/${TOP_MODULE}_sdc.sdc`: Synopsys Design Constraints file (contains clock definition).




