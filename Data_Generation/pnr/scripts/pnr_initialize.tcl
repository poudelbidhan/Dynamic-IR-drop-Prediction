
####### Author : Bidhan Poudel 
# Initializes the PnR environment, checks variables, creates directories,
# loads LEF/Netlist, sets up MMMC, and initializes the design.

puts "INFO: === Step: Initialization  ==="

# --- Check Required Environment Variables ---
set required_vars {
    DESIGN TOP_MODULE OUTPUT_DIR
    LIBERTY_FILES INIT_LEF_FILES VERILOG_FILE SDC_FILE
    MMMC_TCL EXTRACTION_TECH_FILE 
}
foreach var $required_vars {
    if {![info exists env($var)]} {
        puts "ERROR: Missing required environment variable: $var"
        exit 1
    }
}

# Check if SDC file path is empty (set by bash script if file not found)
if {$env(SDC_FILE) == ""} {
     puts "WARNING: SDC_FILE environment variable is set but empty. MMMC setup will proceed without SDC."
}


# --- Assign Tcl Variables  ---
set design          $env(DESIGN)
set top_module      $env(TOP_MODULE)
set output_dir      $env(OUTPUT_DIR)
set init_verilog    $env(VERILOG_FILE)
# SDC path is now handled via env(SDC_FILE) within mmmc.tcl
set init_lef_file   $env(INIT_LEF_FILES)
set mmmc_tcl_script $env(MMMC_TCL)

set init_top_cell   $top_module
set init_gnd_net    "VSS"
set init_pwr_net    "VDD"

# --- Create Output Subdirectories ---
puts "INFO: Creating output directories in: $output_dir"
file mkdir "${output_dir}/reports"
file mkdir "${output_dir}/outputs"
file mkdir "${output_dir}/power_pads"
file mkdir "${output_dir}/tech_pgv"
file mkdir "${output_dir}/Data"


# --- Load Physical/Logical Data ---
puts "INFO: Loading LEF files..."
# Use braces {} in case paths have spaces/special chars
if {[catch {read_physical -lef $init_lef_file} result]} {
     puts "ERROR: Failed to read LEF files ($init_lef_file): $result"
     exit 1
}

puts "INFO: Loading Verilog netlist: $init_verilog"
if {[catch {read_netlist $init_verilog -top $init_top_cell} result]} {
     puts "ERROR: Failed to read Verilog netlist: $result"
     exit 1
}

# --- Source MMMC Setup Script ---
# This script now defines the views, corners, modes, including SDC association
puts "INFO: Sourcing MMMC script: $mmmc_tcl_script"
if {[file exists $mmmc_tcl_script]} {
    # Source the MMMC script. It should return non-zero on error.
    if {[catch {source $mmmc_tcl_script} result]} {
        puts "ERROR: Failed during MMMC script execution: $result"
        exit 1
    }
    puts "INFO: MMMC setup sourced successfully."
} else {
    puts "ERROR: MMMC script not found: $mmmc_tcl_script. Cannot proceed."
    exit 1
}

# --- Initialize Design Database ---
# init_design should now pick up the views defined by the sourced MMMC script
puts "INFO: Initializing design database..."
if {[catch {init_design} result]} {
     puts "ERROR: init_design failed: $result"
     exit 1
}

# --- Set Design Mode ---
# Adjust process node as needed
setDesignMode -process 45 -powerEffort low
puts "INFO: Design Mode Set (Process 45, Power Effort Low)."

# --- Connect Global Nets ---
# Connect power/ground pins first
puts "INFO: Connecting Global Nets (VDD/VSS)..."
globalNetConnect $init_pwr_net -type pgpin -pin VDD -all
globalNetConnect $init_gnd_net -type pgpin -pin VSS -all


puts "INFO: === Initialization Complete (Revised) ==="
