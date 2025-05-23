


# Defines the Multi-Mode Multi-Corner setup using environment variables

#### Author : Bidhan Poudel 


puts "INFO: Setting up MMMC View 'typical'..."

# --- Check Required Environment Variables ---
if {![info exists env(LIBERTY_FILES)]} {
    puts "ERROR: [mmmc.tcl] Environment variable LIBERTY_FILES not set."
    return -code error "LIBERTY_FILES not set" ;# Return error to caller
}
if {![info exists env(EXTRACTION_TECH_FILE)]} {
    # Note: We renamed QRC_FILE to EXTRACTION_TECH_FILE in the bash script for consistency
    puts "ERROR: [mmmc.tcl] Environment variable EXTRACTION_TECH_FILE (for QRC) not set."
    return -code error "EXTRACTION_TECH_FILE not set"
}
if {![info exists env(SDC_FILE)]} {
    puts "ERROR: [mmmc.tcl] Environment variable SDC_FILE not set."
    # If SDC can be optional, change this to a warning and handle below
    return -code error "SDC_FILE not set"
}

# --- Define Library Set ---
# Use braces {} around file list environment variables in case they contain spaces
set lib_files $env(LIBERTY_FILES)
puts "INFO: [mmmc.tcl] Using libs: {$lib_files}"
create_library_set -name libs_typical -timing $lib_files

# --- Define RC Corner ---
set qrc_file $env(EXTRACTION_TECH_FILE)
puts "INFO: [mmmc.tcl] Using QRC tech file: $qrc_file"
create_rc_corner -name typical \
    -qx_tech_file $qrc_file \


# --- Define Delay Corner ---
create_delay_corner -name typical \
    -library_set libs_typical \
    -rc_corner typical

# --- Define Constraint Mode ---
set sdc_file $env(SDC_FILE)
# Handle optional SDC: If the env var is set but empty, create mode without SDC.
if {$sdc_file != ""} {
    puts "INFO: [mmmc.tcl] Using SDC file: $sdc_file"
    create_constraint_mode -name typical \
        -sdc_files $sdc_file
} else {
    puts "WARNING: [mmmc.tcl] SDC_FILE env var is empty. Creating constraint mode 'typical' without SDC."
    create_constraint_mode -name typical
}

# --- Define Analysis View ---
create_analysis_view -name typical \
    -constraint_mode typical \
    -delay_corner typical

puts "INFO: [mmmc.tcl] MMMC View 'typical' setup complete."

# Set the default analysis view (optional but good practice)
set_analysis_view -setup {typical} -hold {typical}
