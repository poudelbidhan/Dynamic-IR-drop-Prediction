# pnr_clock.tcl
# Performs Clock Tree Synthesis (CTS).

puts "INFO: === Step: Clock Tree Synthesis ==="

# Create a default CTS specification (customize if needed)
create_ccopt_clock_tree_spec
puts "INFO: Created default ccopt spec."

# Run Clock Concurrent Optimization (includes CTS and optimization)
puts "INFO: Running ccopt_design..."
if {[catch {ccopt_design} result]} {
     puts "ERROR: ccopt_design failed: $result"
     exit 1
}

puts "INFO: === CTS Complete ==="
