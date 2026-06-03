`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2018 20:51:53
// Design Name: 
// Module Name: cross
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


module vis_cross
#(
    parameter IMG_H = 64,
    parameter IMG_W = 64
)(
input [10:0] x,
input [10:0] y,
input clk,

input de_in,
input hsync_in,
input vsync_in,
input [23:0] pixel_in,

output de_out,
output hsync_out,
output vsync_out,
output [23:0] pixel_out
);
    
reg [10:0] x_pos;
reg [10:0] y_pos;
wire test;
reg prev_vsync = 0;
    
always @(posedge clk)
begin
    prev_vsync <= vsync_in;
    if (vsync_in) begin
        x_pos <= 0;
        y_pos <= 0;
    end else if (de_in) begin
        x_pos <= x_pos + 1;
        if (x_pos == IMG_W - 1) begin
            x_pos <= 0;
            y_pos <= y_pos + 1;
            if (y_pos == IMG_H - 1) begin
                y_pos <= 0;
            end
        end
    end
end

assign pixel_out = (x_pos == x || y_pos== y) ? 23'hFF0000 : pixel_in;

assign de_out = de_in;
assign hsync_out=hsync_in;
assign vsync_out=vsync_in;


endmodule