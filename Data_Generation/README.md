# Automated Synthesis and Place & Route (PnR) Flow for ML Data Generation

This project provides a set of scripts to automate a significant portion of the digital ASIC backend flow, specifically designed for **generating diverse datasets suitable for machine learning applications** . The flow starts from RTL source code, proceeds through synthesis using **Cadence Genus**, and performs Place & Route (PnR) using **Cadence Innovus**, culminating in post-route analysis results.

## Overview

The workflow is divided into two main stages, orchestrated by Bash scripts, with the overarching goal of generating varied design metrics and physical layouts for ML training:

1.  **Synthesis Stage (`run_synthesis.sh` + `synthesis_flow.tcl`):**
    *   Takes RTL Verilog code for multiple base designs as input.
    *   Runs synthesis using **Cadence Genus** for each design across a specified range of target clock periods (frequencies), introducing initial design variations.
    *   Generates synthesized gate-level Verilog netlists (`.v`) and corresponding timing constraints (`.sdc`) for each design/period combination.
    *   Produces basic synthesis reports (timing, area, power, QoR) – potential features for ML models.
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

## Directory Structure Expectation
