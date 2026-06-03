`timescale 1ns / 1ps

module vis_centroid #(
    parameter IMG_H = 1080,
    parameter IMG_W = 1920,
    parameter RADIUS = 10 
)(
    input clk,
    input [10:0] x,
    input [10:0] y,
    input de,
    input vsync,
    input hsync,
    
    
    input [10:0] bb_x_min,
    input [10:0] bb_x_max,
    input [10:0] bb_y_min,
    input [10:0] bb_y_max,
    
    input [23:0] in_pixel,
    output [23:0] out_pixel,
    output de_out,
    output vsync_out,
    output hsync_out
);

// Kwadrat promienia (sta�a dla kompilatora)
localparam RADIUS_SQ = RADIUS * RADIUS;
    
reg [10:0] x_pos;
reg [10:0] y_pos;

reg prev_vsync = 0;
    
always @(posedge clk)
begin
    prev_vsync <= vsync;
    if (vsync) begin
        x_pos <= 0;
        y_pos <= 0;
    end else if (de) begin
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

// Srodek ciezkosci - kolo
wire signed [11:0] dx = x_pos - x;
wire signed [11:0] dy = y_pos - y;

wire [21:0] dx_2 = dx * dx;
wire [21:0] dy_2 = dy * dy;

wire is_circle = ((dx_2 + dy_2) < RADIUS_SQ);

// Bounding box - sprawdzamy czy piksel lezy na krawedzi ramki
// grubosc linii = 2 piksele, zeby ramka byla dobrze widoczna
wire is_bb_edge_x = (x_pos >= bb_x_min && x_pos <= bb_x_max) && (y_pos == bb_y_min || y_pos == bb_y_min + 1 || y_pos == bb_y_max || y_pos == bb_y_max - 1);
wire is_bb_edge_y = (y_pos >= bb_y_min && y_pos <= bb_y_max) && (x_pos == bb_x_min || x_pos == bb_x_min + 1 || x_pos == bb_x_max || x_pos == bb_x_max - 1);

wire is_bounding_box = is_bb_edge_x || is_bb_edge_y;


assign {de_out, vsync_out, hsync_out} = {de, vsync, hsync};

//wyjscie z modulu, polaczenie wynikow
assign out_pixel = is_circle       ? 24'hff0000 : 
                 is_bounding_box ? 24'h00ff00 : 
                                   in_pixel;

endmodule