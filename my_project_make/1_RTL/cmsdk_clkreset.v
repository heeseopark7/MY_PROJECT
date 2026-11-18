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
// Abstract : Simple clock and power on reset generator
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module cmsdk_clkreset(
  output wire CLK,
// 20241203 SMKCOW :: no use of Fifo Clocks
// BACK TO ORIGINAL 
//  output wire fifo_CLK_50, // making 50MHz for fifo in which Cortex-M0 system
  output wire NRST);
//  input  wire Rom_select); // smkcow added for simulation

  reg clock_q;
// 20241203 SMKCOW :: no use of Fifo Clocks
// BACK TO ORIGINAL 
//  reg fifo_clock_q;
  reg reset_n_q;
  reg Rom_select_reset_n_q;

  initial
    begin
      clock_q <= 1'b0;
      Rom_select_reset_n_q <= 1'b1;

      reset_n_q <= 1'b0;
      #100 reset_n_q <= 1'b1;
    end


// 7ns
  always begin
      #3.5 clock_q <= ~clock_q;
  end

// 50MHZ ROM code dumping channel 
// 20ns
// 20241203 SMKCOW :: no use of Fifo Clocks
// BACK TO ORIGINAL 
//  always begin
//      #10 fifo_clock_q <= ~fifo_clock_q;
//  end

  assign CLK = clock_q;
// 20241203 SMKCOW :: no use of Fifo Clocks
// BACK TO ORIGINAL 
//  assign fifo_CLK_50 = fifo_clock_q;
  //assign NRST = reset_n_q & Rom_select_reset_n_q;
  assign NRST = reset_n_q;

endmodule



