# run_pnr_flow.tcl
# Main script executed by the PnR tool (e.g., Innovus) to run the modular flow.
# Sources individual step scripts in the correct sequence.
# Relies on environment variables set by the calling shell script (run_variations.sh).

puts "#####################################################"
puts "# Starting  PnR Flow Execution               #"
puts "#####################################################"
set start_time [clock seconds]

# --- Verify Essential Env Var ---
if {![info exists env(OUTPUT_DIR)] || ![info exists env(DESIGN)] || ![info exists env(ORIGINAL_DIR_NAME)]} {
    puts "ERROR: Essential environment variables (OUTPUT_DIR, DESIGN, ORIGINAL_DIR_NAME) are not set. Cannot proceed."
    exit 1
}
set output_dir $env(OUTPUT_DIR)
set design_name $env(DESIGN)
set run_name $env(ORIGINAL_DIR_NAME) ; # Contains design_util_pdn_dcap info

puts "INFO: Design: $design_name"
puts "INFO: Run Name: $run_name"
puts "INFO: Output Directory: $output_dir"

# --- Execute PnR Steps Sequentially ---
# Use 'catch' to detect errors in each step

if {[catch {source pnr_initialize.tcl} result]} {
    puts "ERROR: Failed during Initialization: $result"
    exit 1
}

if {[catch {source pnr_floorplan.tcl} result]} {
    puts "ERROR: Failed during Floorplanning: $result"
    exit 1
}

if {[catch {source pnr_pdn.tcl} result]} {
    puts "ERROR: Failed during PDN & Power Pad Generation: $result"
    exit 1
}

if {[catch {source pnr_placement.tcl} result]} {
    puts "ERROR: Failed during Placement: $result"
    exit 1
}

if {[catch {source pnr_clock.tcl} result]} {
    puts "ERROR: Failed during Clock Tree Synthesis: $result"
    exit 1
}

if {[catch {source pnr_decaps.tcl} result]} {
    # Decap failure might be non-critical depending on flow
    puts "WARNING: Issue during Decap Insertion: $result"
    # exit 1 # Uncomment if decap failure should stop the flow
}

if {[catch {source pnr_routing.tcl} result]} {
    puts "ERROR: Failed during Routing: $result"
    exit 1
}

if {[catch {source pgv_generation.tcl} result]} {
    puts "ERROR: Failed during PGV Generation: $result"
    # Analysis will likely fail, decide whether to exit now
    exit 1
}

if {[catch {source power_ir_analysis.tcl} result]} {
    puts "ERROR: Failed during Power/IR Analysis: $result"
    # Allow flow to finish saving results even if analysis fails
}

# --- Save Final Design Outputs ---
puts "\nINFO: === Step: Saving Final Outputs ==="
set final_output_base "${output_dir}/outputs/${design_name}_${run_name}" # Use run_name for uniqueness

# Save DEF
if {[catch {defOut "${final_output_base}_final.def.gz"} result]} {
    puts "WARNING: Failed to save final DEF: $result"
} else {
    puts "INFO: Saved final DEF: ${final_output_base}_final.def.gz"
}

# Save Verilog Netlist
if {[catch {saveNetlist "${final_output_base}_final.v"} result]} {
    puts "WARNING: Failed to save final Verilog: $result"
} else {
    puts "INFO: Saved final Verilog: ${final_output_base}_final.v"
}

# Save Design Database (Tool specific - Innovus example)
if {[catch {saveDesign "${output_dir}/${design_name}.inn"} result]} {
     puts "WARNING: Failed to save design database: $result"
} else {
     puts "INFO: Saved design database: ${output_dir}/${design_name}.inn"
}
puts "INFO: === Saving Complete ==="


# --- Flow Completion ---
set end_time [clock seconds]
set elapsed_time [expr {$end_time - $start_time}]
puts "#####################################################"
puts "# Modular PnR Flow Execution Completed              #"
puts "# Total Time: $elapsed_time seconds"
puts "# Final Results and Reports in: $output_dir"
puts "#####################################################"

# Exit the PnR tool
exit
