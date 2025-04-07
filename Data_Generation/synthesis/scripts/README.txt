Synthesis Automation Flow with Cadence Genus
This repository contains an automated synthesis flow for digital designs using Cadence Genus. The flow is designed to process multiple designs under various clock period constraints, reading source files from a centralized inputs folder and generating synthesis outputs (netlists, SDC files, and reports) in a dedicated outputs directory.

Overview
The synthesis flow is divided into two main components:

synthesis_flow.tcl
A parameterized TCL script that performs the entire synthesis process for a given design. It:

Reads design-specific environment variables (such as DESIGN, TOP_MODULE, CLOCK_PORT, PERIOD, LIB_PATH, and RTL_FILES).

Sets up the synthesis environment by configuring library and RTL search paths.

Reads in all Verilog source files.

Elaborates the design and applies clock constraints based on the specified period.

Executes the synthesis steps (syn_generic, syn_map, and syn_opt).

Generates synthesis reports (timing, power, area, QOR) and writes out the final synthesized netlist and SDC file.

run_synthesis.sh
A Bash script that drives the synthesis flow across multiple designs and clock periods. It:

Iterates over an array of design names (e.g., ac97_ctrl, aes_core, des_area, etc.) and clock periods.

Sets design-specific environment variables (e.g., top module name, clock port, RTL directories) based on the current design.

Collects RTL files from one or more directories as needed.

Exports necessary variables such as PROJECT_DIR (the top-level project directory), LIB_PATH, and RTL_FILES.

Invokes Cadence Genus in batch mode with the common TCL script (synthesis_flow.tcl) for each design and period combination.

Stores all synthesis outputs (reports, netlists, SDC files) under a dedicated directory structure within the project.

Directory Structure
The repository follows this structure:

perl
Copy
project_dir/
├── inputs/
│   ├── rtl/                    
│   │   ├── ac97_ctrl/          # RTL source files (one folder per design)
│   │   ├── aes_core/
│   │   └── ... (other designs)
│   ├── lib/                    
│   │   ├── fast_vdd1v0_basicCells.lib
│   │   └── slow_vdd1v0_basicCells.lib
│   ├── lef/                    
│   │   ├── gsclib045_tech.lef
│   │   ├── gsclib045_macro.lef
│   │   └── giolib045.lef
│   └── qrctech/
│       └── qrc_tech.tcl        # QRC technology file
├── synthesis/
│   ├── scripts/                # Contains synthesis_flow.tcl and run_synthesis.sh
│   └── outputs/
│       └── work/               # Synthesis outputs stored here
│           └── <design>_period_<period>/
│               ├── reports/    # Synthesis reports (timing, power, area, QOR)
│               └── outputs/    # Synthesized netlist and SDC files
└── (other folders, e.g., pnr/, README.md, etc.)
Usage
Prepare Inputs:
Ensure that all required design sources (RTL files), libraries, LEF, and QRC technology files are placed under the inputs/ folder.

Configure the Project Directory:
In run_synthesis.sh, set the PROJECT_DIR variable to point to your project's root directory.

Run Synthesis:
Navigate to the synthesis/scripts/ directory and execute:

bash
Copy
./run_synthesis.sh
This script will:

Loop through all specified designs and clock periods.

Set up the environment for each run.

Invoke Cadence Genus with the synthesis_flow.tcl script.

Save the outputs under synthesis/outputs/work/<design>_period_<period>.