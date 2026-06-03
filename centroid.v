`timescale 1ns / 1ps

module centroid #(
    parameter IMG_H = 1080,
    parameter IMG_W = 1920
)(
    input clk,
    input ce,
    input rst,
    input de,
    input hsync,
    input vsync,
    input mask,
    
    // Wyjscia srodka ciezkosci (Centroid)
    output [10:0] x,
    output [10:0] y,
    
    // Wyjscia ramki otaczajacej (Bounding Box)
    output [10:0] bb_x_min,
    output [10:0] bb_x_max,
    output [10:0] bb_y_min,
    output [10:0] bb_y_max
);

reg [10:0] x_pos = 0;
reg [10:0] y_pos = 0;

reg prev_vsync = 0;
wire eof;
assign eof = (prev_vsync == 1'b0 & vsync == 1'b1) ? 1'b1 : 1'b0;

// Wewnetrzne rejestry zliczajace dla Bounding Boxa
reg [10:0] x_min = IMG_W - 1;
reg [10:0] x_max = 0;
reg [10:0] y_min = IMG_H - 1;
reg [10:0] y_max = 0;

// Rejestry wyjsciowe (zatrzaskiwane na koniec klatki)
reg [10:0] x_min_reg = 0;
reg [10:0] x_max_reg = 0;
reg [10:0] y_min_reg = 0;
reg [10:0] y_max_reg = 0;

reg [10:0] x_reg = 0;
reg [10:0] y_reg = 0;

reg [20:0] m00 = 0;
reg [31:0] m01 = 0;
reg [31:0] m10 = 0;

always @(posedge clk)
begin
    prev_vsync <= vsync;
    
    // Reset pozycji i Bounding Boxa na poczatku klatki
    if (vsync) begin
        x_pos <= 0;
        y_pos <= 0;
        
        x_min <= IMG_W - 1;
        x_max <= 0;
        y_min <= IMG_H - 1;
        y_max <= 0;
    end
    
    // Aktualizacja pozycji i znajdowanie skrajnych punktow maski
    if (de) begin
        x_pos <= x_pos + 1;
        if (x_pos == IMG_W - 1) begin
            x_pos <= 0;
            y_pos <= y_pos + 1;
            if (y_pos == IMG_H - 1) begin
                y_pos <= 0;
            end
        end
        
        // Aktualizacja Bounding Boxa w "locie" (na podstawie maski)
        if (mask) begin
            if (x_pos < x_min) x_min <= x_pos;
            if (x_pos > x_max) x_max <= x_pos;
            if (y_pos < y_min) y_min <= y_pos;
            if (y_pos > y_max) y_max <= y_pos;
        end
    end
    
    // Zliczanie pikseli maski dla M00
    if (eof) m00 <= 0;
    else if (mask) m00 <= m00 + 1;
    
    // Zatrzaskiwanie wyliczonego centroidu
    if(qv_x) x_reg <= quotient_2[10:0];
    if(qv_y) y_reg <= quotient_1[10:0];
    
    // Zatrzaskiwanie Bounding Boxa na koncu klatki
    if (eof) begin
        x_min_reg <= x_min;
        x_max_reg <= x_max;
        y_min_reg <= y_min;
        y_max_reg <= y_max;
    end
end

wire [32:0] m01_reg;
wire [32:0] m10_reg;

zero_lat_adder zl1 (
    .A(y_pos),
    .B(m01),
    .S(m01_reg)
);

always @(posedge clk)
begin
    if (eof) m01 <= 0;
    else if (mask & de) m01 <= m01_reg[31:0];
end

zero_lat_adder zl2 (
    .A(x_pos),
    .B(m10),
    .S(m10_reg)
);

always @(posedge clk)
begin
    if (eof) m10 <= 0;
    else if (mask & de) m10 <= m10_reg[31:0];
end

wire qv_x, qv_y;
wire [31:0] quotient_1;
wire [31:0] quotient_2;

divider_32_21_0 divider1 (
    .clk(clk),
    .start(eof),
    .dividend(m01),
    .divisor(m00),
    .quotient(quotient_1),
    .qv(qv_y)
);

divider_32_21_0 divider2 (
    .clk(clk),
    .start(eof),
    .dividend(m10),
    .divisor(m00),
    .quotient(quotient_2),
    .qv(qv_x)
);

// Przypisanie rejestr�w do wyj��
assign x = x_reg;
assign y = y_reg;

assign bb_x_min = x_min_reg;
assign bb_x_max = x_max_reg;
assign bb_y_min = y_min_reg;
assign bb_y_max = y_max_reg;

endmodule