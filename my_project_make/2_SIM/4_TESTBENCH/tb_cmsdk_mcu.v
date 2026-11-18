//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from ARM Limited.
//
//            (C) COPYRIGHT 2010-2015  ARM Limited or its affiliates.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from ARM Limited.
//
//  Version and Release Control Information:
//
//  File Revision       : $Revision: 275084 $
//  File Date           : $Date: 2014-03-27 15:09:11 +0000 (Thu, 27 Mar 2014) $
//
//  Release Information : Cortex-M0 DesignStart-r1p0-00rel0
//------------------------------------------------------------------------------
// Verilog-2001 (IEEE Std 1364-2001)
//------------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
// Abstract : Testbench for the Cortex-M0 example system
//-----------------------------------------------------------------------------
//
`timescale 1ns/1ps
`include "cmsdk_mcu_defs.v"

module tb_cmsdk_mcu;

  wire        XTAL1;   // crystal pin 1
  wire        XTAL2;   // crystal pin 2
  wire        IN_fifo_CLK_50;   // making 50MHz for fifo in which Cortex-M0 system
  wire        OUT_fifo_CLK_50;  // This is the output clock from Cortex-M0 system
  wire        NRST;    // active low reset

  wire [15:0] P0;      // Port 0
  wire [15:0] P1;      // Port 1 for USART RX


  //Debug tester signals
  wire        nTRST;
  wire        TDI;
  wire        SWDIOTMS;
  wire        SWCLKTCK;
  wire        TDO;

  wire        PCLK;          // Clock for UART capture device
  wire [5:0]  debug_command; // used to drive debug tester
  wire        debug_running; // indicate debug test is running
  wire        debug_err;     // indicate debug test has error

  wire        debug_test_en; // To enable the debug tester connection to MCU GPIO P0
                             // This signal is controlled by software,
                             // Use "UartPutc((char) 0x1B)" to send ESCAPE code to start
                             // the command, use "UartPutc((char) 0x11)" to send debug test
                             // enable command, use "UartPutc((char) 0x12)" to send debug test
                             // disable command. Refer to tb_uart_capture.v file for detail

  parameter BE              = 0;   // Big or little endian

  parameter BKPT            = 4;   // Number of breakpoint comparators
  parameter DBG             = 1;   // Debug configuration
  parameter NUMIRQ          = 32;  // NUM of IRQ
  parameter SMUL            = 0;   // Multiplier configuration
  parameter SYST            = 1;   // SysTick
  parameter WIC             = 1;   // Wake-up interrupt controller support
  parameter WICLINES        = 34;  // Supported WIC lines
  parameter WPT             = 2;   // Number of DWT comparators

//----------------------------------------
// Flash memory
//----------------------------------------
// Have to assign memory CEN with along to sram_CEN_o 

  wire          HCLKSYS;    // Clock
  wire          HRESETn; // Reset wire		
  wire		flash_hsel; 

  wire          out_NRST; 	// smkcow added, External reset input active low

  wire [15:0]   HADDR;  // Transfer control
  wire [1:0]    HTRANS;  // Transfer control
  wire [2:0]    HSIZE;   // Transfer size
  wire          HWRITE;  // Write control
  wire [31:0]   HWDATA;  // Write data
  wire          HREADY;  // Transfer phase done

  wire          flash_hreadyout; // Device ready
  wire [31:0]   flash_hrdata;  // Read data output
  wire          flash_hresp;    // Device response (always OKAY)
  //input  wire 	        Rom_select, // smkcow Rom select signal
  wire 	        Rom_select; // smkcow Rom select signal
  wire		out_stx;	// smkcow fifo uart channel
  wire		in_srx; // smkcow fifo uart channel

//----------------------------------------
// SRAM memory
//----------------------------------------
  wire		sram_hsel; 
  wire          sram_hreadyout; // Device ready
  wire [31:0]   sram_hrdata;  // Read data output
  wire          sram_hresp;    // Device response (always OKAY)

 // --------------------------------------------------------------------------------
 // Cortex-M0/Cortex-M0+ Microcontroller
 // --------------------------------------------------------------------------------

  cmsdk_mcu
	`ifdef function_sim
   #(.BE               (BE),
     .BKPT             (BKPT),          // Number of breakpoint comparators
     .DBG              (DBG),           // Debug configuration
     .NUMIRQ           (NUMIRQ),        // NUMIRQ
     .SMUL             (SMUL),          // Multiplier configuration
     .SYST             (SYST),          // SysTick
     .WIC              (WIC),           // Wake-up interrupt controller support
     .WICLINES         (WICLINES),      // Supported WIC lines
     .WPT              (WPT)            // Number of DWT comparators 
   )
	`endif
   u_cmsdk_mcu (
  .XTAL1      (XTAL1),			// input to Cortex-M0
  .XTAL2      (XTAL2),			// output from Cortex-M0
  .NRST       (NRST),   		// active low reset
  .P1         (P1),
  .nTRST      (nTRST),			// Not needed if serial-wire debug is used
  .TDI        (TDI),			// Not needed if serial-wire debug is used
  .TDO        (TDO),			// Not needed if serial-wire debug is used
  .SWDIOTMS   (SWDIOTMS),
  .SWCLKTCK   (SWCLKTCK),

// FLASH rom interface 
  .HCLKSYS(HCLKSYS), // System clock for memory
  .HRESETn(HRESETn), // AHB reset
  .HADDR(HADDR),
  .HTRANS(HTRANS),
  .HSIZE(HSIZE),
  .HWRITE(HWRITE),
  .HWDATA(HWDATA),
  .HREADY(HREADY),
  .flash_hsel(flash_hsel),
  .flash_hreadyout(flash_hreadyout),
  .flash_hrdata(flash_hrdata),
  .flash_hresp(flash_hresp),
  .sram_hsel(sram_hsel),
  .sram_hreadyout(sram_hreadyout),
  .sram_hrdata(sram_hrdata),
  .sram_hresp(sram_hresp)
  );

 // --------------------------------------------------------------------------------
 // This module is for simulation 
 // Source for clock and reset
 // --------------------------------------------------------------------------------
  cmsdk_clkreset u_cmsdk_clkreset(
  .CLK  (XTAL1),
  .NRST (NRST)
  );

cmsdk_ahb_rom
  #(.MEM_TYPE(1'b1),
    .AW(16),  // 64K bytes flash ROM
    .filename("hello.hex"),
    .WS_N(`ARM_CMSDK_ROM_MEM_WS_N),
    .WS_S(`ARM_CMSDK_ROM_MEM_WS_S),
    .BE  (BE))
   u_ahb_rom (
    .HRESETn          (HRESETn),
    .HCLK             (HCLKSYS),
    .HSEL             (flash_hsel),  // AHB inputs

    // HADDR is 32bit but [15:0] is only assigned because of lack of IO cells 
    .HADDR            (HADDR), // originally [15:0] 
    .HTRANS           (HTRANS),
    .HSIZE            (HSIZE),
    .HWRITE           (HWRITE),
    .HWDATA           (HWDATA),
    .HREADY           (HREADY),

    .HREADYOUT        (flash_hreadyout), // Outputs
    .HRDATA           (flash_hrdata),
    .HRESP            (flash_hresp)
  );

cmsdk_ahb_ram
  #(.MEM_TYPE(1'b1),
    .AW(16),  // 64K bytes SRAM
    .WS_N(`ARM_CMSDK_RAM_MEM_WS_N),
    .WS_S(`ARM_CMSDK_RAM_MEM_WS_S))
   u_ahb_ram (
    .HCLK             (HCLKSYS),
    .HRESETn          (HRESETn),
    .HSEL             (sram_hsel),  // AHB inputs
    .HADDR            (HADDR), // originally [15:0] 
    .HTRANS           (HTRANS),
    .HSIZE            (HSIZE),
    .HWRITE           (HWRITE),
    .HWDATA           (HWDATA),
    .HREADY           (HREADY),

    .HREADYOUT        (sram_hreadyout), // Outputs
    .HRDATA           (sram_hrdata),
    .HRESP            (sram_hresp)
  );

 // --------------------------------------------------------------------------------
 // UART output capture
 // --------------------------------------------------------------------------------
  assign PCLK = XTAL2;

  cmsdk_uart_capture   u_cmsdk_uart_capture(
    .RESETn               (NRST),
    .CLK                  (PCLK),
    .RXD                  (P1[5]), // UART 2 use for StdOut
    .DEBUG_TESTER_ENABLE  (debug_test_en),
    .SIMULATIONEND        (),      // This signal set to 1 at the end of simulation.
    .AUXCTRL              ()
  );

  // UART connection cross over for UART test
  assign P1[0] = P1[3];  // UART 0 RXD = UART 1 TXD
  assign P1[2] = P1[1];  // UART 1 RXD = UART 0 TXD

 // --------------------------------------------------------------------------------
 // Debug tester connection -
 // --------------------------------------------------------------------------------

 // No debug connection for Cortex-M0 DesignStart
 assign nTRST    = NRST;
 assign TDI      = 1'b1;
 assign SWDIOTMS = 1'b1;
 assign SWCLKTCK = 1'b1;

 bufif1 (P0[31-16], debug_running, debug_test_en);
 bufif1 (P0[30-16], debug_err, debug_test_en);

 pullup (debug_running);
 pullup (debug_err);

 // --------------------------------------------------------------------------------
 // Misc
 // --------------------------------------------------------------------------------

  // Format for time reporting
  initial    $timeformat(-9, 0, " ns", 0);
  
  initial begin

	#32700 $stop;
  end

  initial begin
//dumpfile open
	`ifdef function_sim
		$shm_open("./dump/tb_cmsdk_mcu");
		$shm_probe(tb_cmsdk_mcu, "AC");
	`endif

// MAXIMUM means it annotes the maximum delay value
	`ifdef sdf_gate
		 //$sdf_annotate("./cmsdk_mcu_gate.sdf", tb_cmsdk_mcu.u_cmsdk_mcu,"sdf_gate.log","MAXIMUM");
		 $sdf_annotate("./cmsdk_mcu_delays.sdf", tb_cmsdk_mcu.u_cmsdk_mcu);
                 $shm_open("./dump/tb_cmsdk_mcu_sdf_gate");
                 $shm_probe(tb_cmsdk_mcu, "AC");

	`endif

// MAXIMUM means it annotes the maximum delay value
	`ifdef sdf_post_wst
		 //$sdf_annotate("./cmsdk_mcu.sdf", tb_cmsdk_mcu.u_cmsdk_mcu,,"sdf_post_wst.log","MAXIMUM");
		 $sdf_annotate("./cmsdk_mcu_post_wst.sdf", tb_cmsdk_mcu.u_cmsdk_mcu);
                 $shm_open("./dump/tb_cmsdk_mcu_sdf_post_wst");
                 $shm_probe(tb_cmsdk_mcu, "AC");
	`endif

// MINIMUM means it annotes the minimum delay value
	`ifdef sdf_post_bst
		 //$sdf_annotate("./cmsdk_mcu.sdf", tb_cmsdk_mcu.u_cmsdk_mcu,,"sdf_post_bst.log","MINIMUM");
		 $sdf_annotate("./cmsdk_mcu_post_bst.sdf", tb_cmsdk_mcu.u_cmsdk_mcu);
                 $shm_open("./dump/tb_cmsdk_mcu_sdf_post_bst");
                 $shm_probe(tb_cmsdk_mcu, "AC");
	`endif
  end

endmodule
