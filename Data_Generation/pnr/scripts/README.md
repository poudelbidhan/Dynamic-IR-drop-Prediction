
# Automatic Place & Route (PnR) Flow

These scripts implements a  Place & Route (PnR) flow designed to be driven by a Bash script and executed using a Cadence Innovus .
It takes synthesized netlists and constraints as input and performs the complete PnR process, including variations in utilization, power distribution network (PDN) strategies, and decap cell insertion, culminating in power and IR drop analysis.

## Overview

The flow is structured as follows:

1.  **`run_variations.sh` (Bash Orchestrator):**
    *   Identifies synthesized design outputs (netlist, SDC) from a specified input directory (`BASE_SYNDIR`).
    *   Loops through multiple PnR parameter variations:
        *   Target Utilization (`UTILIZATION_FACTORS`)
        *   Power Distribution Network configuration (`PDN_SETTINGS`)
        *   Decoupling Capacitor insertion (`DECAP_OPTIONS`)
    *   Sets up environment variables containing configuration details (file paths, design info, variation settings) for each specific run.
    *   Creates a unique output directory (`OUTPUT_DIR`) for each variation run.
    *   Invokes the chosen PnR tool (`PNR_TOOL_CMD`) to execute the main Tcl flow script.

2.  **`pnr_flow.tcl` (Main Tcl Flow Script):**
    *   Acts as the entry point for the PnR tool.
    *   Verifies essential environment variables.
    *   Sources individual Tcl scripts for each PnR stage in a predefined sequence.
    *   Performs basic error checking after each stage.
    *   Saves final design outputs (DEF, Verilog, tool database).

3.  **Modular Tcl Scripts (`pnr_*.tcl`, `mmmc.tcl`, `pgv_generation.tcl`, `power_ir_analysis.tcl`):**
    *   Each script performs a specific PnR task (e.g., initialization, floorplanning, placement, CTS, routing, analysis).
    *   Reads configuration parameters from environment variables set by `run_variations.sh`.
    *   Executes the relevant PnR tool commands for that stage.

## Features

*   **Modular Design:** PnR steps are separated into individual Tcl scripts for clarity and maintainability.
*   **Parameterizable:** Easily run variations for utilization, PDN, and decaps by modifying arrays in the Bash script.
*   **Automated:** Designed for batch execution across multiple synthesized designs and PnR configurations.
*   **Integrated Input:** Directly consumes outputs (netlist, SDC) from the preceding synthesis flow.
*   **Structured Outputs:** Generates organized output directories for each run, including reports, final design files, and analysis results.
*   **Power/IR Analysis:** Includes steps for generating necessary views (PGV) and performing dynamic power and IR drop analysis, looping through different power pad configurations.

## Prerequisites

1.  **PnR Tool:** Cadence Innovus or Synopsys IC Compiler II (or a similar tool) installed and accessible in the system `PATH`.
2.  **Bash Environment:** A Unix-like environment with Bash shell.
3.  **Synthesis Outputs:** Completed synthesis runs from the previous stage, providing:
    *   Gate-level Verilog netlist (`.v`)
    *   Synopsys Design Constraints file (`.sdc`)
    *   These should reside in subdirectories within the `BASE_SYNDIR` path configured in `run_variations.sh`.
4.  **Technology Files:**
    *   Standard Cell LEF (`.lef`)
    *   Macro LEF (`.lef`) (if applicable)
    *   IO LEF (`.lef`) (if applicable)
    *   Liberty Timing Libraries (`.lib`) for the corners used in MMMC.
    *   QRC Extraction Technology File (`.tech`, `qrc.tech`, etc.) for parasitic extraction and analysis.
    *   Decoupling Capacitor Library Files/Directory (needed if `DECAP_OPTION=yes`).



## Inputs

1.  **Synthesized Design Data (from `BASE_SYNDIR`):**
    *   Verilog Netlist (`.v`)
    *   SDC Constraints File (`.sdc`)
2.  **Technology Files (paths set in `run_variations.sh`):**
    *   `LIBERTY_FILES`: Path(s) to `.lib` timing library files.
    *   `INIT_LEF_FILES`: Path(s) to LEF files (tech, cell, IO).
    *   `EXTRACTION_TECH_FILE`: Path to the QRC technology file. **(User MUST set)**
    *   `DECAP_DIR`: Path to the directory containing decap cell libraries/LEFs. **(User MUST set)**
3.  **Configuration (within `run_variations.sh`):**
    *   `BASE_SYNDIR`: Path to the directory containing synthesis output subdirectories. **(User MUST set)**
    *   `BASE_PNRDIR`: Path where PnR output directories will be created. **(User MUST set)**
    *   `SCRIPT_DIR`: Path to the directory containing the PnR Tcl/Bash scripts. **(User MUST set)**
    *   `LIB_DIR`: Base path for library/tech files (can be absolute). **(User MUST set)**
    *   `PNR_TOOL_CMD`: Command to invoke the PnR tool (e.g., `innovus -nowin`). **(User MUST set)**
    *   `UTILIZATION_FACTORS`, `PDN_SETTINGS`, `DECAP_OPTIONS`: Arrays defining the variations to run.
    *   Design-specific settings (`TOP_MODULE`, `CLOCK_PORT`) within the `case` statement.

## Outputs

For *each* variation run (combination of design, synthesis period, utilization, pdn setting, decap option), a unique directory is created: `${BASE_PNRDIR}/${RUN_NAME}/` (e.g., `pnr_modular/aes_core_period_2.0_util0.6_pdn2_dcapno/`). This directory contains:

*   `pnr_flow_${RUN_NAME}.log`: Log file for the PnR tool run.
*   `reports/`: Directory for potential intermediate reports (if added).
*   `outputs/`: Directory containing final design files:
    *   `${DESIGN}_${RUN_NAME}_final.def.gz`: Final placed and routed DEF file.
    *   `${DESIGN}_${RUN_NAME}_final.v`: Final Verilog netlist after PnR.
*   `${DESIGN}.inn` (or similar): PnR tool's saved database (tool-dependent name).
*   `power_pads/`: Contains the generated `.pp` files (VDD1.pp, VSS1.pp ... VDD4.pp, VSS4.pp) used for IR analysis.
*   `tech_pgv/`: Contains the generated Power Grid View library (`techonly.cl/`).
*   `Data/`: Contains results from the power/IR analysis stage, organized by power pad configuration:
    *   `Data/${RUN_NAME}_PP<N>/`: Subdirectory for each power pad config (N=1 to 4).
        *   `route_dynamic_ir.rpt`: IR drop report for this configuration.
        *   `detailed_route.def.gz`: DEF snapshot used for this analysis.
        *   `cts.twf`: Timing window file snapshot.
        *   `dyn_power_summary.rpt`: Copied overall dynamic power report.
        *   `VDDN.pp`, `VSSN.pp`: Copied power pad files used for this analysis run.

## Configuration (Mandatory Steps)

Before running, **you MUST configure** `run_variations.sh`:

1.  **Set Base Directories:** Update `BASE_SYNDIR`, `BASE_PNRDIR`, `SCRIPT_DIR`, and `LIB_DIR` to the correct absolute paths for your environment.
2.  **Set Technology File Paths:**
    *   Update `LIBERTY_FILES` and `INIT_LEF_FILES` to point to your specific `.lib` and `.lef` files.
    *   **Critically, replace the placeholder paths** for `EXTRACTION_TECH_FILE` and `DECAP_DIR` with the actual paths to your QRC tech file and decap library directory.
3.  **Set PnR Tool Command:** Modify `PNR_TOOL_CMD` to the correct command for launching your PnR tool (e.g., `innovus -nowin -log ...` or `icc2_shell -f ...`). The script attempts basic log file handling for Innovus/ICC2.
4.  **Verify/Adjust Variations:** Review the `UTILIZATION_FACTORS`, `PDN_SETTINGS`, and `DECAP_OPTIONS` arrays.
5.  **Verify Design Settings:** Ensure the `case` statement correctly maps `DESIGN` names (from synthesis directories) to the appropriate `TOP_MODULE` and `CLOCK_PORT`.

## PnR Flow Steps (Executed by `pnr_flow.tcl`)

1.  **Initialization (`pnr_initialize.tcl`):** Checks environment, creates directories, loads LEF/Verilog, sources MMMC Tcl, initializes design database.
2.  **Floorplanning (`pnr_floorplan.tcl`):** Creates initial floorplan based on target utilization.
3.  **PDN Generation (`pnr_pdn.tcl`):** Creates power rings and stripes based on `PDN_SETTING`, connects them (`sroute`), and generates `.pp` files for different pad counts.
4.  **Placement (`pnr_placement.tcl`):** Performs pin placement and standard cell placement (`placeDesign`).
5.  **Clock Tree Synthesis (`pnr_clock.tcl`):** Creates CTS spec and runs clock tree synthesis/optimization (`ccopt_design`).
6.  **Decap Insertion (`pnr_decaps.tcl`):** Optionally adds decap filler cells based on `DECAP_OPTION`.
7.  **Routing (`pnr_routing.tcl`):** Performs detailed signal routing (`routeDesign`).
8.  **PGV Generation (`pgv_generation.tcl`):** Creates the Power Grid View library required for power analysis.
9.  **Power/IR Analysis (`power_ir_analysis.tcl`):** Runs dynamic power analysis (once) and then loops through the 4 generated power pad configurations (`.pp` files) to run dynamic rail (IR drop) analysis, saving results for each configuration.
10. **Final Save:** Saves the final DEF, Verilog netlist, and tool database.

## Customization

*   **Add Designs:** Add new design names to the `case` statement in `run_variations.sh` with their corresponding `TOP_MODULE` and `CLOCK_PORT`. Ensure synthesis outputs exist in `BASE_SYNDIR`.
*   **Change Variations:** Modify the parameter arrays (`UTILIZATION_FACTORS`, etc.) in `run_variations.sh`.
*   **Modify PnR Steps:** Edit the individual `pnr_*.tcl` scripts to change tool options, strategies, or add/remove steps. Update `pnr_flow.tcl` if the sequence changes.
*   **Modify MMMC:** Edit `mmmc.tcl` to add more corners, modes, or change analysis views. Ensure corresponding libraries are provided via `LIBERTY_FILES`.
