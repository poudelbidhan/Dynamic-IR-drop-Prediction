# pnr_pdn.tcl
# Creates the Power Distribution Network (PDN) based on the PDN_SETTING env variable.
# **Also generates the corresponding power pad (.pp) files** into $env(OUTPUT_DIR)/power_pads/

puts "INFO: === Step: PDN Generation & Power Pad File Creation ==="

# --- Check Required Environment Variables ---
if {![info exists env(PDN_SETTING)] || ![info exists env(OUTPUT_DIR)]} {
    puts "ERROR: Missing required environment variables: PDN_SETTING, OUTPUT_DIR"
    exit 1
}
set pdn_setting $env(PDN_SETTING)
set output_dir  $env(OUTPUT_DIR)
set pp_output_dir "${output_dir}/power_pads" # Define path for .pp files

puts "INFO: Configuring PDN based on setting: $pdn_setting"
puts "INFO: Power Pad files will be generated in: $pp_output_dir"

# --- PDN Generation ---
# Define PDN structure AND set internal Tcl variables for dimensions/layers
if {[string equal $pdn_setting "pdn1"]} {
    puts "INFO: Applying PDN Setting: pdn1 (High Density)"
    addRing -nets {VDD VSS} -follow core -layer {bottom Metal11 top Metal11 right Metal10 left Metal10} -width 5 -spacing 2 -offset 4
    addStripe -nets {VSS VDD} -direction {vertical} -layer Metal11 -width 5 -spacing 3 -set_to_set_distance 120 -xleft_offset 20 -xright_offset 20
    addStripe -nets {VSS VDD} -direction {horizontal} -layer Metal10 -width 5 -spacing 3 -set_to_set_distance 120 -ytop_offset 50 -ybottom_offset 50
    # Set Tcl vars for this PDN type (used below for power pads)
    set vdd_offset 4.0; set vdd_width 5.0; set spacing_between_vdd_vss 2.0
    set vss_offset [expr {$vdd_offset + $vdd_width + $spacing_between_vdd_vss}] ; set vss_width 5.0
    set vdd_layer_left_right "Metal10"; set vdd_layer_top_bottom "Metal11"
    set vss_layer_left_right "Metal10"; set vss_layer_top_bottom "Metal11"

} elseif {[string equal $pdn_setting "pdn2"]} {
    puts "INFO: Applying PDN Setting: pdn2 (Medium Density)"
    addRing -nets {VDD VSS} -width 1.28 -spacing 0.75 -layer [list top Metal8 bottom Metal8 left Metal9 right Metal9] -type core_rings -snap_wire_center_to_grid Grid
    addStripe -nets {VSS VDD} -layer Metal9 -direction vertical -width 1.28 -spacing 0.75 -set_to_set_distance 8 -merge_stripes_value 5 -snap_wire_center_to_grid Grid
    addStripe -nets {VSS VDD} -layer Metal8 -direction horizontal -width 1.28 -spacing 0.75 -set_to_set_distance 8 -merge_stripes_value 5 -snap_wire_center_to_grid Grid
    # Set Tcl vars for this PDN type
    set vdd_offset 0.75; set vdd_width 1.28; set spacing_between_vdd_vss 0.75
    set vss_offset [expr {$vdd_offset + $vdd_width + $spacing_between_vdd_vss}]; set vss_width 1.28
    set vdd_layer_left_right "Metal9"; set vdd_layer_top_bottom "Metal8"
    set vss_layer_left_right "Metal9"; set vss_layer_top_bottom "Metal8"

} elseif {[string equal $pdn_setting "pdn3"]} {
    puts "INFO: Applying PDN Setting: pdn3 (Specified Density)"
    addRing -nets {VDD VSS} -width 1.28 -spacing 0.96 -layer [list top Metal10 bottom Metal10 left Metal11 right Metal11] -type core_rings -snap_wire_center_to_grid Grid
    addStripe -nets {VSS VDD} -layer Metal10 -direction vertical -width 1.28 -spacing 0.96 -set_to_set_distance 8 -merge_stripes_value 5 -snap_wire_center_to_grid Grid
    addStripe -nets {VSS VDD} -layer Metal11 -direction horizontal -width 1.28 -spacing 0.96 -set_to_set_distance 8 -merge_stripes_value 5 -snap_wire_center_to_grid Grid
    # Set Tcl vars for this PDN type
    set vdd_offset 0.96; set vdd_width 1.28; set spacing_between_vdd_vss 0.96
    set vss_offset [expr {$vdd_offset + $vdd_width + $spacing_between_vdd_vss}]; set vss_width 1.28
    set vdd_layer_left_right "Metal11"; set vdd_layer_top_bottom "Metal10"
    set vss_layer_left_right "Metal11"; set vss_layer_top_bottom "Metal10"

} else {
    puts "ERROR: Unknown PDN_SETTING: $pdn_setting."
    exit 1
}

# Connect the power grid components
puts "INFO: Routing PDN connections (sroute)..."
# Note: sroute options might vary; ensure connectivity needed
sroute -nets {VDD VSS} -allowJogging 1 -allowLayerChange 1 #-connect { ring stripe }

# Check if the internal Tcl variables were set (should be true if no error above)
if {![info exists vdd_offset] || ![info exists vdd_layer_left_right]} {
     puts "ERROR: Internal error - PDN parameters (vdd_offset, layers) were not set."
     exit 1
}
puts "INFO: PDN Generation Complete."

# --- Power Pad File Generation ---
# This block uses the vdd_offset, vdd_width, vss_*, vdd/vss_layer_* Tcl variables
# set within the if/elseif block above.
puts "\nINFO: Generating Power Pad Files..."
if {![file isdirectory $pp_output_dir]} {
     puts "ERROR: Power pad output directory '$pp_output_dir' does not exist (should have been created by initialize script)."
     exit 1
}

# Get core boundary coordinates
set core_bbox [get_db current_design .core_bbox]
if {$core_bbox == ""} { puts "ERROR: Could not get core_bbox for power pad generation."; exit 1 }
set core_llx [get_db $core_bbox .ll.x]; set core_lly [get_db $core_bbox .ll.y]
set core_urx [get_db $core_bbox .ur.x]; set core_ury [get_db $core_bbox .ur.y]

# Loop through 4 different power pad configurations
for {set num_pads_per_edge 1} {$num_pads_per_edge <= 4} {incr num_pads_per_edge} {
    set vdd_file "${pp_output_dir}/VDD${num_pads_per_edge}.pp"
    set vss_file "${pp_output_dir}/VSS${num_pads_per_edge}.pp"
    if {[catch {open $vdd_file w} vdd_fp]} { puts "ERROR: Cannot open VDD PP file '$vdd_file': $vdd_fp"; exit 1 }
    if {[catch {open $vss_file w} vss_fp]} { puts "ERROR: Cannot open VSS PP file '$vss_file': $vss_fp"; close $vdd_fp; exit 1 }

    puts $vdd_fp "*vsrc_name\tx\ty\tlayer_name"
    puts $vss_fp "*vsrc_name\tx\ty\tlayer_name"

    # Use float division for spacing
    set pad_spacing_vertical   [expr {($core_ury - $core_lly) / ($num_pads_per_edge + 1.0)}]
    set pad_spacing_horizontal [expr {($core_urx - $core_llx) / ($num_pads_per_edge + 1.0)}]
    # Calculate center offset from core edge based on PDN vars set above
    set vdd_center_offset_x [expr {$vdd_offset + ($vdd_width / 2.0)}]
    set vdd_center_offset_y [expr {$vdd_offset + ($vdd_width / 2.0)}]
    set vss_center_offset_x [expr {$vss_offset + ($vss_width / 2.0)}]
    set vss_center_offset_y [expr {$vss_offset + ($vss_width / 2.0)}]

    # VDD Pads
    set y_coord [expr {$core_lly + $pad_spacing_vertical}]
    for {set i 1} {$i <= $num_pads_per_edge} {incr i} {
        puts $vdd_fp "VDDvsrcL$i\t[expr {$core_llx - $vdd_center_offset_x}]\t$y_coord\t$vdd_layer_left_right"
        puts $vdd_fp "VDDvsrcR$i\t[expr {$core_urx + $vdd_center_offset_x}]\t$y_coord\t$vdd_layer_left_right"
        set y_coord [expr {$y_coord + $pad_spacing_vertical}]
    }
    set x_coord [expr {$core_llx + $pad_spacing_horizontal}]
    for {set i 1} {$i <= $num_pads_per_edge} {incr i} {
        puts $vdd_fp "VDDvsrcB$i\t$x_coord\t[expr {$core_lly - $vdd_center_offset_y}]\t$vdd_layer_top_bottom"
        puts $vdd_fp "VDDvsrcT$i\t$x_coord\t[expr {$core_ury + $vdd_center_offset_y}]\t$vdd_layer_top_bottom"
        set x_coord [expr {$x_coord + $pad_spacing_horizontal}]
    }
    # VSS Pads
    set y_coord [expr {$core_lly + $pad_spacing_vertical}]
    for {set i 1} {$i <= $num_pads_per_edge} {incr i} {
        puts $vss_fp "VSSvsrcL$i\t[expr {$core_llx - $vss_center_offset_x}]\t$y_coord\t$vss_layer_left_right"
        puts $vss_fp "VSSvsrcR$i\t[expr {$core_urx + $vss_center_offset_x}]\t$y_coord\t$vss_layer_left_right"
        set y_coord [expr {$y_coord + $pad_spacing_vertical}]
    }
    set x_coord [expr {$core_llx + $pad_spacing_horizontal}]
    for {set i 1} {$i <= $num_pads_per_edge} {incr i} {
        puts $vss_fp "VSSvsrcB$i\t$x_coord\t[expr {$core_lly - $vss_center_offset_y}]\t$vss_layer_top_bottom"
        puts $vss_fp "VSSvsrcT$i\t$x_coord\t[expr {$core_ury + $vss_center_offset_y}]\t$vss_layer_top_bottom"
        set x_coord [expr {$x_coord + $pad_spacing_horizontal}]
    }
    # Close files safely
    catch {close $vdd_fp}
    catch {close $vss_fp}
    puts "INFO: Generated PP files: $vdd_file, $vss_file"
}
puts "INFO: Power Pad File Generation Complete."

puts "INFO: === PDN & Power Pad Generation Complete ==="
