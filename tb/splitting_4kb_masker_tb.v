`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2024 03:48:30 PM
// Design Name: 
// Module Name: splitting_4kb_masker_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module splitting_4kb_masker_tb;
    
    
    localparam ADDR_WIDTH    = 32;
    localparam LEN_WIDTH     = 3;
    localparam SIZE_WIDTH    = 3;
    
    logic  [ADDR_WIDTH-1:0]    ADDR_i;
    logic  [LEN_WIDTH-1:0]     LEN_i;
    logic  [SIZE_WIDTH-1:0]    SIZE_i;
    logic                      mask_sel_i; // Mask selection
    logic  [ADDR_WIDTH-1:0]    ADDR_split_o;
    logic  [LEN_WIDTH-1:0]     LEN_split_o;
    logic  [SIZE_WIDTH-1:0]    SIZE_o;
    logic                      crossing_flag;
    
    splitting_4kb_masker #(
    
    ) uut (
        .ADDR_i(ADDR_i),       
        .LEN_i(LEN_i),
        .SIZE_i(SIZE_i),
        .mask_sel_i(mask_sel_i),
        .ADDR_split_o(ADDR_split_o),
        .LEN_split_o(LEN_split_o),
        .SIZE_o(SIZE_o),
        .crossing_flag(crossing_flag)
    );
    
    initial begin
        ADDR_i <= 32'd24;
        LEN_i <= 8'd30;
        SIZE_i <= 3'd2;
        mask_sel_i <= 0;
        
        #100;
        ADDR_i <= 32'd8190;
        LEN_i <= 3'd7;
        SIZE_i <= 3'd0;
        mask_sel_i <= 0;
        
        #50;
        mask_sel_i <= 1;
    end

endmodule
