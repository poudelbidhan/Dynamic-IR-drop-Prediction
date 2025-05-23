# pnr_floorplan.tcl
# Performs initial floorplanning based on utilization factor.

puts "INFO: === Step: Floorplanning ==="

# --- Check Required Environment Variables ---
if {![info exists env(UTILIZATION_FACTOR)]} {
    puts "ERROR: UTILIZATION_FACTOR environment variable not set."
    exit 1
}
set util $env(UTILIZATION_FACTOR)
puts "INFO: Target Utilization Factor: $util"

# --- Perform Floorplan Commands ---
# Adjust aspect ratio and core margins as needed
floorPlan -su 1.0 $util 20 20 20 20
add_tracks -honor_pitch
snapFPlan -all

puts "INFO: === Floorplanning Complete ==="
