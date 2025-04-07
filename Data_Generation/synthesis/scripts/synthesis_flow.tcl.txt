# synthesis_flow.tcl

# Check required environment variables
if {![info exists env(DESIGN)] || ![info exists env(TOP_MODULE)] || \
    ![info exists env(CLOCK_PORT)] || ![info exists env(PERIOD)] || \
    ![info exists env(PROJECT_DIR)] || ![info exists env(LIB_PATH)] || \
    ![info exists env(RTL_FILES)]} {
    puts "Missing required environment variables. Please set DESIGN, TOP_MODULE, CLOCK_PORT, PERIOD, PROJECT_DIR, LIB_PATH, and RTL_FILES."
    exit 1
}

# Assign variables from the environment
set design         $env(DESIGN)
set top_module     $env(TOP_MODULE)
set clock_port     $env(CLOCK_PORT)
set period         $env(PERIOD)
set project_dir    $env(PROJECT_DIR)
set lib_path       $env(LIB_PATH)
set rtl_files      $env(RTL_FILES)  ;# A space-separated list of RTL file paths

# Define input directory (contains rtl, lib, lef, qrctech, etc.)
set input_dir "${project_dir}/inputs"
# Define synthesis outputs directory
set synth_out_dir "${project_dir}/synthesis/outputs"

# Set up design output directory under synthesis outputs
set out_dir "${synth_out_dir}/work/${design}_period_${period}"
file mkdir "${out_dir}/reports"
file mkdir "${out_dir}/outputs"

# Set up design environment using inputs
set_db init_lib_search_path "${input_dir}/lib/"
set_db init_hdl_search_path "[file dirname [lindex [split $rtl_files] 0]]"
read_libs "${lib_path}"

# Read design RTL files (assumes RTL_FILES is space-separated)
foreach file [split $rtl_files] {
    read_hdl "$file"
}

elaborate
current_design $top_module

# Check that the clock port exists
if {[llength [get_ports "$clock_port"]] == 0} {
    puts "Error: Clock port '$clock_port' not found in design '$top_module'"
    exit 1
}

# Create clock constraints
set half_period [expr {$period / 2.0}]
create_clock -name clk -period $period -waveform {0 $half_period} [get_ports "$clock_port"]

# Synthesis steps
syn_generic
syn_map
syn_opt

# Generate reports and outputs
report_timing > "${out_dir}/reports/report_timing.rpt"
report_power  > "${out_dir}/reports/report_power.rpt"
report_area   > "${out_dir}/reports/report_area.rpt"
report_qor    > "${out_dir}/reports/report_qor.rpt"

write_hdl > "${out_dir}/outputs/${top_module}_netlist.v"
write_sdc > "${out_dir}/outputs/${top_module}_sdc.sdc"
