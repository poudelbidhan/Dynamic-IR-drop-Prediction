# pnr_routing.tcl
# Performs detailed routing of signal nets.

puts "INFO: === Step: Detailed Routing ==="

# Add options if needed (e.g., -timingDriven, -effortLevel high)
if {[catch {routeDesign} result]} {
    puts "ERROR: routeDesign failed: $result"
    exit 1
}

puts "INFO: === Routing Complete ==="
