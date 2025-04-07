# pnr_decaps.tcl
# Optionally adds decoupling capacitor filler cells.

puts "INFO: === Step: Decap Filler Addition (Optional) ==="

# --- Check Required Environment Variables ---
if {![info exists env(DECAP_OPTION)]} {
    puts "ERROR: DECAP_OPTION environment variable not set (should be 'yes' or 'no')."
    exit 1
}

puts "INFO: Checking DECAP_OPTION: $env(DECAP_OPTION)"
if {[string equal -nocase $env(DECAP_OPTION) "yes"]} {
    puts "INFO: Adding decap filler cells..."
    # Adjust list of decap cells available in your library
    set decap_cell_list {DECAP2 DECAP3 DECAP4 DECAP5 DECAP6 DECAP7 DECAP8 DECAP9 DECAP10}
    if {[llength $decap_cell_list] > 0} {
        setFillerMode -core $decap_cell_list -add_fillers_with_drc false
        if {[catch {addFiller} result]} {
             puts "WARNING: Failed to add decap fillers: $result"
        } else {
             puts "INFO: Decap fillers added."
        }
    } else {
        puts "WARNING: Decap cell list is empty in script. Skipping decap addition."
    }
} else {
    puts "INFO: Skipping decap filler addition."
}

puts "INFO: === Decap Step Complete ==="
