# pnr_placement.tcl
# Performs Pin Placement and Standard Cell Placement.

puts "INFO: === Step: Placement (Pins & Cells) ==="

# --- Check Required Environment Variables ---
if {![info exists env(CLOCK_PORT)]} {
    puts "ERROR: CLOCK_PORT environment variable not set."
    exit 1
}
set clock_port_name $env(CLOCK_PORT)

# --- Pin Placement ---
puts "INFO: Performing Pin Placement..."
# Get all ports excluding the known clock port
set all_ports [dbGet top.terms.name]
set other_ports [list]
foreach port $all_ports {
  # Use string match for robustness if clock name might vary slightly
  if {![string match $clock_port_name $port]} {
     lappend other_ports $port
  }
}

set num_other_ports [llength $other_ports]
set half_other_ports_idx [expr {$num_other_ports / 2}]

# Split non-clock ports for left/right assignment
set pins_left_half [lrange $other_ports 0 [expr {$half_other_ports_idx - 1}]]
set pins_right_half [lrange $other_ports $half_other_ports_idx end]

# Get the actual clock port object(s) matching the name
set clock_port_objs [dbGet top.terms -p name $clock_port_name]

# Place clock port(s) in the center of the left edge
if {[llength $clock_port_objs] > 0} {
     # Add the *name* to the list for editPin
     set pins_left_half [linsert $pins_left_half [expr {[llength $pins_left_half] / 2}] $clock_port_name]
     puts "INFO: Placing clock port '$clock_port_name' on LEFT side."
} else {
     puts "WARNING: Clock port '$clock_port_name' not found in design for pin placement."
}

# Assign pins to sides
set ports_layer M4 ;# Adjust layer if needed
puts "INFO: Assigning pins to LEFT/RIGHT on layer $ports_layer..."
if {[llength $pins_left_half] > 0} {
    editPin -layer $ports_layer -pin $pins_left_half -side LEFT -spreadType SIDE
}
if {[llength $pins_right_half] > 0} {
    editPin -layer $ports_layer -pin $pins_right_half -side RIGHT -spreadType SIDE
}
puts "INFO: Pin Placement Complete."

# --- Standard Cell Placement ---
puts "\nINFO: Performing Standard Cell Placement..."
# Add options like -timing_driven if SDC is loaded and flow requires it
if {[catch {placeDesign} result]} {
     puts "ERROR: placeDesign failed: $result"
     exit 1
}

puts "INFO: === Placement Complete ==="
