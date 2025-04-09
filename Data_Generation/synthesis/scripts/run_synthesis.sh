#!/bin/bash
# run_synthesis.sh: Script to run synthesis_flow.tcl for each design/period combination
#################################################################################################

######################## Author :Bidhan Poudel ###############################################

######################################################################################################

# Set the top-level project directory
PROJECT_DIR="/path/to/project Dir"
export PROJECT_DIR

# Set the library path (using fast_vdd1v0_basicCells.lib from inputs/lib)
export LIB_PATH="${PROJECT_DIR}/inputs/lib/fast_vdd1v0_basicCells.lib"

# List all designs to be synthesized
designs=(
  "ac97_ctrl" "aes_core" "des_area" "des_perf" "des3_area" "ethernet" 
  "i2c" "mem_ctrl" "pci_bridge32" "pci_spoci_ctrl" "sasc" "simple_spi" 
  "spi" "ss_pcm" "systemcaes" "systemcdes" "tv80" "usb_funct" "usb_phy" 
  "vga_lcd" "wb_conmax" "wb_dma"
)

# Define the clock periods to simulate
periods=("1.0" "2.0" "5.0" "10.0")

# Loop over each design
for DESIGN in "${designs[@]}"; do
    case "$DESIGN" in
        ac97_ctrl)
            export TOP_MODULE="ac97_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/ac97_ctrl"
            export RTL_DIR2=""
            ;;
        aes_core)
            export TOP_MODULE="aes_cipher_top"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/aes_core"
            export RTL_DIR2=""
            ;;
        des_area)
            export TOP_MODULE="des"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/des/area_opt"
            export RTL_DIR2="${PROJECT_DIR}/inputs/rtl/des/common"
            ;;
        des_perf)
            export TOP_MODULE="des3"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/des/perf_opt"
            export RTL_DIR2="${PROJECT_DIR}/inputs/rtl/des/common"
            ;;
        des3_area)
            export TOP_MODULE="des3"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/des/area_opt"
            export RTL_DIR2="${PROJECT_DIR}/inputs/rtl/des/common"
            ;;
        ethernet)
            export TOP_MODULE="eth_top"
            export CLOCK_PORT="wb_clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/ethernet"
            export RTL_DIR2=""
            ;;
        i2c)
            export TOP_MODULE="i2c_master_top"
            export CLOCK_PORT="wb_clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/i2c"
            export RTL_DIR2=""
            ;;
        mem_ctrl)
            export TOP_MODULE="mc_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/mem_ctrl"
            export RTL_DIR2=""
            ;;
        pci_bridge32)
            export TOP_MODULE="pci_bridge32"
            export CLOCK_PORT="wb_clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/pci"
            export RTL_DIR2=""
            ;;
        pci_spoci_ctrl)
            export TOP_MODULE="pci_spoci_ctrl"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/pci"
            export RTL_DIR2=""
            ;;
        sasc)
            export TOP_MODULE="sasc_top"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/sasc"
            export RTL_DIR2=""
            ;;
        simple_spi)
            export TOP_MODULE="simple_spi_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/simple_spi"
            export RTL_DIR2=""
            ;;
        spi)
            export TOP_MODULE="spi_top"
            export CLOCK_PORT="wb_clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/spi"
            export RTL_DIR2=""
            ;;
        ss_pcm)
            export TOP_MODULE="pcm_slv_top"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/ss_pcm"
            export RTL_DIR2=""
            ;;
        systemcaes)
            export TOP_MODULE="aes"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/systemcaes"
            export RTL_DIR2=""
            ;;
        systemcdes)
            export TOP_MODULE="des"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/systemcdes"
            export RTL_DIR2=""
            ;;
        tv80)
            export TOP_MODULE="tv80s"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/tv80"
            export RTL_DIR2=""
            ;;
        usb_funct)
            export TOP_MODULE="usbf_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/usb_funct"
            export RTL_DIR2=""
            ;;
        usb_phy)
            export TOP_MODULE="usb_phy"
            export CLOCK_PORT="clk"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/usb_phy"
            export RTL_DIR2=""
            ;;
        vga_lcd)
            export TOP_MODULE="vga_enh_top"
            export CLOCK_PORT="wb_clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/vga_lcd"
            export RTL_DIR2=""
            ;;
        wb_conmax)
            export TOP_MODULE="wb_conmax_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/wb_conmax"
            export RTL_DIR2=""
            ;;
        wb_dma)
            export TOP_MODULE="wb_dma_top"
            export CLOCK_PORT="clk_i"
            export RTL_DIR="${PROJECT_DIR}/inputs/rtl/wb_dma"
            export RTL_DIR2=""
            ;;
        *)
            echo "Unknown design: $DESIGN"
            continue
            ;;
    esac

    # Combine RTL files from RTL_DIR and RTL_DIR2 if RTL_DIR2 is non-empty
    if [ -n "$RTL_DIR2" ]; then
        export RTL_FILES=$(find "$RTL_DIR" -name "*.v"; find "$RTL_DIR2" -name "*.v" | tr '\n' ' ')
    else
        export RTL_FILES=$(find "$RTL_DIR" -name "*.v" | tr '\n' ' ')
    fi

    for PERIOD in "${periods[@]}"; do
        export DESIGN="$DESIGN"
        export PERIOD="$PERIOD"
        echo "Running synthesis for $DESIGN at period $PERIOD..."
        # Invoke Cadence Genus with the synthesis_flow.tcl 
        genus -abort_on_error -batch -f synthesis_flow.tcl
    done
done
