# Automated Synthesis and Place & Route (PnR) Flow for ML Data Generation

This project provides a set of scripts to automate a significant portion of the digital ASIC backend flow, specifically designed for **generating diverse datasets suitable for machine learning applications** . The flow starts from RTL source code, proceeds through synthesis using **Cadence Genus**, and performs Place & Route (PnR) using **Cadence Innovus**, culminating in post-route analysis results.

## Overview

The workflow is divided into two main stages, orchestrated by Bash scripts, with the overarching goal of generating varied design metrics and physical layouts for ML training:

1.  **Synthesis Stage (`run_synthesis.sh` + `synthesis_flow.tcl`):**
    *   Takes RTL Verilog code for multiple base designs as input.
    *   Runs synthesis using **Cadence Genus** for each design across a specified range of target clock periods (frequencies), introducing initial design variations.
    *   Generates synthesized gate-level Verilog netlists (`.v`) and corresponding timing constraints (`.sdc`) for each design/period combination.
    *   Produces basic synthesis reports (timing, area, power, QoR).
    *   Outputs are organized into a structured directory (`synthesis/outputs/work/`).

2.  **Place & Route Stage (`run_variations.sh` + `pnr_flow.tcl` + modules):**
    *   Takes the synthesized netlists and SDC files produced by the Synthesis Stage as input.
    *   Runs the PnR flow using **Cadence Innovus**.
    *   Iterates through multiple PnR parameter variations for each synthesized design to create diverse physical implementations:
        *   Target Core Utilization (`UTILIZATION_FACTORS`)
        *   Power Distribution Network (PDN) configuration (`PDN_SETTINGS`)
        *   Optional Decoupling Capacitor insertion (`DECAP_OPTIONS`)
    *   Performs standard PnR steps: Initialization, Floorplanning, PDN Generation (including power pad file creation), Placement, Clock Tree Synthesis (CTS), Optional Decap Insertion, and Routing.
    *   Includes Power Grid View (PGV) library generation and subsequent dynamic Power/IR Drop analysis, testing multiple power pad configurations to generate varied power grid performance data.
    *   Generates final PnR database (`.inn`), DEF files, final netlists, PnR logs, and detailed analysis reports (IR drop, timing, power, area metrics) – crucial data points for ML datasets. Outputs are organized by variation (`pnr_modular/`).

This combined flow systematically generates a rich dataset capturing the relationship between design characteristics (RTL, timing constraints), PnR parameters, and resulting physical implementation metrics (area, timing, power, routability, IR drop).

## Features

*   **ML Data Generation Focused:** Designed to efficiently generate diverse data points by varying synthesis and PnR parameters.
*   **End-to-End Automation:** Scripts automate the flow from RTL to post-PnR analysis-ready outputs.
*   **Industry Standard Tools:** Utilizes Cadence Genus and Cadence Innovus.
*   **Modular Design:** Both synthesis and PnR flows use modular Tcl scripts for clarity and maintainability.
*   **Parameterizable & Batch Capable:** Easily run synthesis for multiple designs/periods and PnR for multiple variations (utilization, PDN, decaps) across all synthesized results.
*   **Integrated Workflow:** The PnR stage automatically finds and uses the outputs from the synthesis stage.
*   **Structured Outputs:** Consistent directory structures for inputs and outputs, facilitating data collection.
*   **Comprehensive PnR & Analysis:** Includes core PnR steps plus power grid generation and power/IR analysis across different scenarios.

## Prerequisites

1.  **Synthesis Tool:** Cadence Genus installed and accessible.
2.  **PnR Tool:** **Cadence Innovus** installed and accessible.
3.  **Bash Environment:** A Unix-like environment with Bash shell.
4.  **Technology Files:**
    *   RTL Source Code (`.v`) for the designs.
    *   Standard Cell Liberty Timing Libraries (`.lib`).
    *   Standard Cell LEF (`.lef`).
    *   Macro LEF (`.lef`) (if applicable).
    *   IO LEF (`.lef`) (if applicable).
    *   QRC Extraction Technology File (`.tech`, `qrc.tech`, etc.) for PnR parasitic extraction and analysis.
    *   Decoupling Capacitor Library Files/Directory (for PnR decap insertion and analysis).


*(Note: Ensure the script files have the correct `.sh` and `.tcl` extensions, not `.txt` as in the original input listing).*

## Inputs

1.  **RTL Source Code:** Verilog (`.v`) files located under `inputs/rtl/`.
2.  **Technology Files:** Liberty (`.lib`), LEF (`.lef`), QRC Tech file, Decap library files located under `inputs/` or paths specified in the scripts.
3.  **Configuration (within Bash scripts):**
    *   **`run_synthesis.sh`:**
        *   `PROJECT_DIR`: Path to the root project directory (containing `inputs`, `scripts`, etc.). **(User MUST set)**
        *   `designs`, `periods`: Arrays defining designs and clock periods for synthesis.
        *   `LIB_PATH`: Path to the standard cell `.lib` file for synthesis.
        *   Design-specific settings (`TOP_MODULE`, `CLOCK_PORT`, `RTL_DIR`) in the `case` statement.
    *   **`run_variations.sh`:**
        *   `BASE_SYNDIR`: Path to the synthesis output directory (`<project_root>/synthesis/outputs/work`). **(User MUST set)**
        *   `BASE_PNRDIR`: Path where PnR output directories will be created (e.g., `<project_root>/pnr_modular`). **(User MUST set)**
        *   `SCRIPT_DIR`: Path to the directory containing the PnR Tcl/Bash scripts (e.g., `<project_root>/scripts`). **(User MUST set)**
        *   `LIB_DIR`: Base path for library/tech files (e.g., `<project_root>/inputs`). **(User MUST set)**
        *   `LIBERTY_FILES`, `INIT_LEF_FILES`: Paths to Lib/LEF files for PnR.
        *   `EXTRACTION_TECH_FILE`, `DECAP_DIR`: Paths to QRC tech file and decap library. **(User MUST set placeholders)**
        *   `PNR_TOOL_CMD`: Command to invoke **Innovus** (e.g., `innovus -nowin`). **(User MUST set)**
        *   `UTILIZATION_FACTORS`, `PDN_SETTINGS`, `DECAP_OPTIONS`: Arrays defining PnR variations for data diversity.
        *   Design-specific settings (`TOP_MODULE`, `CLOCK_PORT`) in the `case` statement (for PnR steps like pin placement).

## Outputs (Potential ML Data Features)

1.  **Synthesis Stage (within `${BASE_SYNDIR}/${DESIGN}_period_${PERIOD}/`):**
    *   Synthesized Verilog Netlist (`outputs/*_netlist.v`)
    *   Timing Constraints (`outputs/*_sdc.sdc`)
    *   Synthesis Reports (`reports/*.rpt`): Timing (WNS, TNS), Area (Cell Count, Std Cell Area), Power (Leakage, Dynamic).
2.  **PnR Stage (within `${BASE_PNRDIR}/${RUN_NAME}/`):**
    *   Final Placed & Routed DEF file (`outputs/*_final.def.gz`): Layout geometry features.
    *   Final Verilog Netlist (`outputs/*_final.v`): Post-PnR netlist changes (buffers).
    *   PnR Run Log (`pnr_flow_*.log`): Tool messages, warnings, runtime.
    *   Innovus Database (`*.inn`): Full design state.
    *   Power Pad files (`power_pads/*.pp`): Configuration used for IR analysis.
    *   Power Grid View library (`tech_pgv/`).
    *   Power & IR Drop Analysis Results (`Data/${RUN_NAME}_PP<N>/route_dynamic_ir.rpt`): Worst IR drop, average IR drop metrics for different pad configs.
    *   *Additional PnR Reports (Can be added to scripts):* Post-Route Timing, Area, DRC violations, Antenna violations, Congestion maps.

## Customization

*   **Designs/Parameters:** Modify the arrays and `case` statements in the `.sh` scripts to add/remove designs, change clock periods, or alter PnR variations to enrich the dataset.
*   **Flow Steps:** Edit the individual `.tcl` scripts to adjust tool options, change strategies (e.g., different placement effort, CTS targets), or add commands to extract specific metrics/reports needed for ML features. Update `run_pnr_flow.tcl` if the PnR sequence changes significantly.
*   **MMMC:** Enhance `mmmc.tcl` for multi-corner/multi-mode PnR optimization if needed to add more dimensions to the data.

## Notes

*   **Placeholders:** Remember to replace placeholder paths in `run_variations.sh` with actual paths to your technology files.
*   **Technology Tuning:** PnR parameters within the Tcl scripts (PDN dimensions, layers, placement/routing options) likely require tuning for your specific PDK and design goals, which itself can be a source of variation for data generation.
*   **Error Handling:** The scripts include basic error checking. Detailed debugging often requires inspecting the tool's log files (Genus logs, Innovus `pnr_flow_*.log`). Robustness might be needed for large-scale data generation.
