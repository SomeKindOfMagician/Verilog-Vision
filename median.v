`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 07:24:10 AM
// Design Name: 
// Module Name: context
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


module context
#(
    parameter H_SIZE = 83
)(
    input clk,
    input de_in,
    input hsync_in,
    input vsync_in,
    input mask,
    output de_out,
    output vsync_out,
    output hsync_out,
    output [23:0]pixel_out
);

reg [3:0] D11;
reg [3:0] D12;
reg [3:0] D13;
reg [3:0] D14;
reg [3:0] D15;
reg [3:0] D21;
reg [3:0] D22;
reg [3:0] D23;
reg [3:0] D24;
reg [3:0] D25;
reg [3:0] D31;
reg [3:0] D32;
reg [3:0] D33;
reg [3:0] D34;
reg [3:0] D35;
reg [3:0] D41;
reg [3:0] D42;
reg [3:0] D43;
reg [3:0] D44;
reg [3:0] D45;
reg [3:0] D51;
reg [3:0] D52;
reg [3:0] D53;
reg [3:0] D54;
reg [3:0] D55;

wire [15:0] delay_line_data_out;

delayLineBRAM_WP long_line (
    .clk(clk),
    .rst(0),
    .ce(1),
    .din({D15, D25, D35, D45}),
    .dout(delay_line_data_out),
    .h_size(H_SIZE - 5)
);

reg [2:0] sum_1;
reg [2:0] sum_2;
reg [2:0] sum_3;
reg [2:0] sum_4;
reg [2:0] sum_5;
reg [4:0] sum_all;

always @ (posedge clk)
begin
    D11 <= {mask, de_in, hsync_in, vsync_in};
    D12 <= D11;
    D13 <= D12;
    D14 <= D13;
    D15 <= D14;
    D21 <= delay_line_data_out[15:12];
    D22 <= D21;
    D23 <= D22;
    D24 <= D23;
    D25 <= D24;
    D31 <= delay_line_data_out[11:8];
    D32 <= D31;
    D33 <= D32;
    D34 <= D33;
    D35 <= D34;
    D41 <= delay_line_data_out[7:4];
    D42 <= D41;
    D43 <= D42;
    D44 <= D43;
    D45 <= D44;
    D51 <= delay_line_data_out[3:0];
    D52 <= D51;
    D53 <= D52;
    D54 <= D53;
    D55 <= D54;
    
    sum_1 = D11[3] + D12[3] + D13[3] + D14[3] + D15[3];
    sum_2 = D21[3] + D22[3] + D23[3] + D24[3] + D25[3];
    sum_3 = D31[3] + D32[3] + D33[3] + D34[3] + D35[3];
    sum_4 = D41[3] + D42[3] + D43[3] + D44[3] + D45[3];
    sum_5 = D51[3] + D52[3] + D53[3] + D54[3] + D55[3];
    sum_all = sum_1 + sum_2 + sum_3 + sum_4 + sum_5;
end

wire context_valid;
assign context_valid = D11[2] & D12[2] & D13[2] & D14[2] & D15[2] & D21[2] & D22[2] & D23[2] & D24[2] & D25[2] & D31[2] & D32[2] & D33[2] & D34[2] & D35[2] & D41[2] & D42[2] & D43[2] & D44[2] & D45[2] & D51[2] & D52[2] & D53[2] & D54[2] & D55[2];

wire [3:0] centr_pixel;
assign centr_pixel = {context_valid, D33[2], D33[1], D33[0]};
wire [3:0] centr_pixel_delay;

delayline #(
    .N(4),
    .DELAY(2)
)  delay_pix (
    .clk(clk),
    .idata(centr_pixel),
    .odata(centr_pixel_delay)
);
    
wire [23:0] mask_new;
assign mask_new = (sum_all > 5'd12 ? 255 : 0);
    
assign pixel_out = centr_pixel_delay[3] == 1 ? mask_new : 0;

assign de_out = centr_pixel_delay[2];
assign hsync_out = centr_pixel_delay[1];
assign vsync_out = centr_pixel_delay[0];


endmodule