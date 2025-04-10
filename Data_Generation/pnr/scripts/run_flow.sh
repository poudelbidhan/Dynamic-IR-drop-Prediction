#!/bin/bash

# run_variations.sh
# Sets environment variables and runs the MODULAR PnR flow for different designs and variations.

# --- Configuration - MODIFY THESE ---
# Base directory where SYNTHESIS results (netlist, sdc in subdirs) are stored
export BASE_SYNDIR="/home/grads/b/bidhanpoudel/Design-files/BENCHMARK_DIR/work"
# Base directory for all PNR output
export BASE_PNRDIR="/home/grads/b/bidhanpoudel/Design-files/BENCHMARK_DIR/pnr_modular" # Use a new dir
# Directory containing the modular Tcl scripts AND the run_pnr_flow.tcl script
export SCRIPT_DIR="/home/grads/b/bidhanpoudel/Design-files/scripts" # Adjust if needed
# Base directory containing lib, lef, tech.tcl, mmmc.tcl etc.
export LIB_DIR="/home/grads/b/bidhanpoudel/Design-files"

# Library and Tech File Paths (relative to LIB_DIR or absolute)
export LIBERTY_FILES="${LIB_DIR}/lib/fast_vdd1v0_basicCells.lib" # Adjust if corners needed
export INIT_LEF_FILES="${LIB_DIR}/lef/gsclib045_tech.lef ${LIB_DIR}/lef/gsclib045_macro.lef ${LIB_DIR}/lef/giolib045.lef"
export TECH_TCL="${SCRIPT_DIR}/tech.tcl" # Common tech setup Tcl script
export MMMC_TCL="${SCRIPT_DIR}/mmmc.tcl" # Common MMMC setup Tcl script
export EXTRACTION_TECH_FILE="/path/to/your/qrc.tech" # !!! IMPORTANT: SET ACTUAL PATH !!!
export DECAP_DIR="/path/to/your/decap_lib_dir"     # !!! IMPORTANT: SET ACTUAL PATH !!!

# --- PnR Tool Command (MODIFY THIS) ---
# Example for Innovus:
PNR_TOOL_CMD="innovus -nowin" # Log file name will be constructed below
# Example for IC Compiler 2:
# PNR_TOOL_CMD="icc2_shell -no_log" # Log file name will be constructed below

# --- Variation Parameters ---
UTILIZATION_FACTORS=("0.5" "0.6" "0.7" "0.8")
PDN_SETTINGS=("pdn1" "pdn2" "pdn3")
DECAP_OPTIONS=("yes" "no")

# --- Main Script Logic ---
echo "Starting Modular PnR Variations Script..."
echo "Synthesis Dir: ${BASE_SYNDIR}"
echo "Output Dir:    ${BASE_PNRDIR}"
echo "Script Dir:    ${SCRIPT_DIR}"

# Ensure base PnR directory exists
mkdir -p ${BASE_PNRDIR}

# Find design directories in the synthesis base directory
shopt -s nullglob # Prevent loop from running if no matches
design_syndirs=("${BASE_SYNDIR}"/*/)
shopt -u nullglob

if [ ${#design_syndirs[@]} -eq 0 ]; then
    echo "ERROR: No design directories found in ${BASE_SYNDIR}"
    exit 1
fi

# Loop through each found synthesis design directory
for design_syndir_path in "${design_syndirs[@]}"; do
    # Get the directory name (e.g., ac97_ctrl_period_...)
    export ORIGINAL_DIR_NAME=$(basename "${design_syndir_path%/}")
    # Extract the base design name (e.g., ac97_ctrl)
    export DESIGN=$(echo "$ORIGINAL_DIR_NAME" | sed 's/_period.*//')

    echo "====================================================="
    echo "Processing Design: ${DESIGN} (from ${ORIGINAL_DIR_NAME})"
    echo "====================================================="

    # --- Set Design-Specific Variables ---
    case "$DESIGN" in
        ac97_ctrl)      export CLOCK_PORT="clk_i"; export TOP_MODULE="ac97_top" ;;
        aes_core)       export CLOCK_PORT="clk"; export TOP_MODULE="aes_cipher_top" ;;
        des_area)       export CLOCK_PORT="clk"; export TOP_MODULE="des" ;;
        des_perf)       export CLOCK_PORT="clk"; export TOP_MODULE="des3" ;;
        des3_area)      export CLOCK_PORT="clk"; export TOP_MODULE="des3" ;;
        ethernet)       export CLOCK_PORT="wb_clk_i"; export TOP_MODULE="eth_top" ;;
        i2c)            export CLOCK_PORT="wb_clk_i"; export TOP_MODULE="i2c_master_top" ;;
        mem_ctrl)       export CLOCK_PORT="clk_i"; export TOP_MODULE="mc_top" ;;
        pci_bridge32)   export CLOCK_PORT="wb_clk_i"; export TOP_MODULE="pci_bridge32" ;;
        pci_spoci_ctrl) export CLOCK_PORT="clk_i"; export TOP_MODULE="pci_spoci_ctrl" ;;
        sasc)           export CLOCK_PORT="clk"; export TOP_MODULE="sasc_top" ;;
        simple_spi)     export CLOCK_PORT="clk_i"; export TOP_MODULE="simple_spi_top" ;;
        spi)            export CLOCK_PORT="wb_clk_i"; export TOP_MODULE="spi_top" ;;
        ss_pcm)         export CLOCK_PORT="clk"; export TOP_MODULE="pcm_slv_top" ;;
        systemcaes)     export CLOCK_PORT="clk"; export TOP_MODULE="aes" ;;
        systemcdes)     export CLOCK_PORT="clk"; export TOP_MODULE="des" ;;
        tv80)           export CLOCK_PORT="clk"; export TOP_MODULE="tv80s" ;;
        usb_funct)      export CLOCK_PORT="clk_i"; export TOP_MODULE="usbf_top" ;;
        usb_phy)        export CLOCK_PORT="clk"; export TOP_MODULE="usb_phy" ;;
        vga_lcd)        export CLOCK_PORT="wb_clk_i"; export TOP_MODULE="vga_enh_top" ;;
        wb_conmax)      export CLOCK_PORT="clk_i"; export TOP_MODULE="wb_conmax_top" ;;
        wb_dma)         export CLOCK_PORT="clk_i"; export TOP_MODULE="wb_dma_top" ;;
        *)
            echo "ERROR: Unknown design base name: ${DESIGN}. Skipping..."
            continue # Skip to the next design directory
            ;;
    esac

    # --- Find Input Files for this specific synthesis run ---
    export VERILOG_FILE=$(find "${design_syndir_path}/outputs/" -maxdepth 1 -name '*.v' -print -quit)
    export SDC_FILE=$(find "${design_syndir_path}/outputs/" -maxdepth 1 -name '*.sdc' -print -quit)

    if [ -z "$VERILOG_FILE" ]; then
        echo "ERROR: Could not find Verilog file for ${DESIGN}. Skipping..."
        continue
    fi
     if [ -z "$SDC_FILE" ]; then
        echo "WARNING: Could not find SDC file for ${DESIGN}. Setting SDC_FILE env var to empty."
        export SDC_FILE="" # Explicitly set to empty for Tcl check
    fi

    # --- Loop through PnR Variations for the current design ---
    for util in "${UTILIZATION_FACTORS[@]}"; do
      export UTILIZATION_FACTOR=${util}
      for pdn in "${PDN_SETTINGS[@]}"; do
        export PDN_SETTING=${pdn}
        for decap in "${DECAP_OPTIONS[@]}"; do
          export DECAP_OPTION=${decap}

          # --- Define Unique Output Directory for this run ---
          # Use ORIGINAL_DIR_NAME for uniqueness related to synthesis run
          export RUN_NAME="${ORIGINAL_DIR_NAME}_util${util}_pdn${pdn}_dcap${decap}"
          export OUTPUT_DIR="${BASE_PNRDIR}/${RUN_NAME}"

          echo "-----------------------------------------------------"
          echo "Running Variation: ${RUN_NAME}"
          echo "  Design:          ${DESIGN} (${TOP_MODULE})"
          echo "  Clock Port:      ${CLOCK_PORT}"
          echo "  Utilization:     ${UTILIZATION_FACTOR}"
          echo "  PDN Setting:     ${PDN_SETTING}"
          echo "  Decap Option:    ${DECAP_OPTION}"
          echo "  Verilog:         ${VERILOG_FILE}"
          echo "  SDC:             ${SDC_FILE:-None}"
          echo "  Output Dir:      ${OUTPUT_DIR}"
          echo "-----------------------------------------------------"

          # Create the output directory
          mkdir -p "${OUTPUT_DIR}"
          if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create output directory: ${OUTPUT_DIR}. Skipping..."
            continue # Skip to the next variation
          fi

          # Define Log file path
          local LOG_FILE="${OUTPUT_DIR}/pnr_flow_${RUN_NAME}.log"

          # --- Construct and Execute the PnR Tool Command ---
          # Add log file option based on tool
          local TOOL_RUN_CMD=""
          if [[ "$PNR_TOOL_CMD" == *"innovus"* ]]; then
              TOOL_RUN_CMD="${PNR_TOOL_CMD} -log ${LOG_FILE} -files ${SCRIPT_DIR}/run_pnr_flow.tcl"
          elif [[ "$PNR_TOOL_CMD" == *"icc2_shell"* ]]; then
              TOOL_RUN_CMD="${PNR_TOOL_CMD} -f ${SCRIPT_DIR}/run_pnr_flow.tcl -output_log_file ${LOG_FILE}"
          else
               echo "WARNING: PNR_TOOL_CMD format not recognized for log file handling. Using basic command."
               TOOL_RUN_CMD="${PNR_TOOL_CMD} ${SCRIPT_DIR}/run_pnr_flow.tcl" # May need adjustment
          fi

          echo "Executing: ${TOOL_RUN_CMD}"
          # Run the PnR tool
          ${TOOL_RUN_CMD}

          # Check exit status
          if [ $? -ne 0 ]; then
            echo "ERROR: PnR tool failed for ${RUN_NAME}. Check log: ${LOG_FILE}"
            # Decide whether to stop or continue
            # exit 1 # Stop on first error
          else
            echo "SUCCESS: PnR tool completed for ${RUN_NAME}."
          fi
          echo "-----------------------------------------------------"
          echo ""

        done # decap loop
      done # pdn loop
    done # util loop
done # design loop

echo "====================================================="
echo "All PnR Variations Completed."
echo "Results are in subdirectories under: ${BASE_PNRDIR}"
echo "====================================================="
exit 0
