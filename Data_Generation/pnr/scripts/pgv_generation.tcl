# pgv_generation.tcl
# Generates the Power Grid View (PGV) library needed for power/IR analysis.

puts "INFO: === Step: Power Grid View (PGV) Generation ==="

# --- Check Required Environment Variables ---
set required_vars {
    OUTPUT_DIR EXTRACTION_TECH_FILE LIBERTY_FILES DECAP_DIR
}
foreach var $required_vars {
    if {![info exists env($var)]} {
        puts "ERROR: Missing required environment variable for PGV generation: $var"
        exit 1
    }
}

# Define the list of decap cells used (should match pnr_decaps.tcl if used)
set decap_cells_pattern {*DECAP2* *DECAP3* *DECAP4* *DECAP5* *DECAP6* *DECAP7* *DECAP8* *DECAP9* *DECAP10*} ;# Adjust as needed

# Define the output directory for the PGV library
set pgv_output_dir "$env(OUTPUT_DIR)/tech_pgv"
# Directory should have been created by initialize script

puts "INFO: PGV Output Directory: $pgv_output_dir"
puts "INFO: Extraction Tech File: $env(EXTRACTION_TECH_FILE)"
# Use braces for file lists
puts "INFO: Liberty Files: {$env(LIBERTY_FILES)}"
puts "INFO: Decap Cell Files Directory: $env(DECAP_DIR)"
puts "INFO: Decap Cell Name Patterns: $decap_cells_pattern"

# Set the mode for PGV library generation
set_pg_library_mode \
  -celltype techonly \
  -extraction_tech_file "$env(EXTRACTION_TECH_FILE)" \
  -liberty_files "$env(LIBERTY_FILES)" \
  -cell_decap_file "$env(DECAP_DIR)" \
  -decap_cells $decap_cells_pattern \
  -default_area_cap 0.01 \
  -default_power_voltage 1.1 ;# Adjust default voltage if needed

# Generate the PGV library
# Output will be placed in $pgv_output_dir/techonly.cl/
if {[catch {generate_pg_library -output "${pgv_output_dir}/techonly"} result]} {
     puts "ERROR: Failed to generate PGV library: $result"
     exit 1
}

puts "INFO: === PGV Generation Complete ==="
