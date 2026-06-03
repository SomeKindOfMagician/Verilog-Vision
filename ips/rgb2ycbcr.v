`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2026 03:11:50
// Design Name: 
// Module Name: rgb2ycbcr
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


module rgb2ycbcr(
    input  wire        clk,
    input  wire        de_in,
    input  wire        hsync_in,
    input  wire        vsync_in,
    input  wire [23:0] rgb,
    
    output wire        de_out,
    output wire        hsync_out,
    output wire        vsync_out,
    output wire [26:0] ycbcr_out

    );
    
// 1. Przygotowanie sygna��w R, G, B jako 18-bitowe warto�ci signed
// Dodajemy 10 zer na pocz�tku, aby zachowa� warto�� dodatni� w formacie signed
wire signed [17:0] R_ext = {10'd0, rgb[23:16]};
wire signed [17:0] G_ext = {10'd0, rgb[15:8]};
wire signed [17:0] B_ext = {10'd0, rgb[7:0]};

// 2. Definicja sta�ych (wsp�czynniki z Matlaba - przyk�adowe warto�ci)
localparam signed [17:0] C11 = 18'b001001100100010110; // Przyk�ad dla Y
localparam signed [17:0] C12 = 18'b010010110010001011; 
localparam signed [17:0] C13 = 18'b000011101001011110;
localparam signed [17:0] C21 = 18'b111010100110011011; // Przyk�ad dla Cb
localparam signed [17:0] C22 = 18'b110101011001100100;
localparam signed [17:0] C23 = 18'b010000000000000000;
localparam signed [17:0] C31 = 18'b010000000000000000;  // Przyk�ad dla Cr
localparam signed [17:0] C32 = 18'b110010100110100001;
localparam signed [17:0] C33 = 18'b111101011001011110;

// 3. Przewody na wyniki mno�enia (18-bit * 18-bit = 36-bit)
wire signed [35:0] prod_y_r, prod_y_g, prod_y_b;
wire signed [35:0] prod_cb_r, prod_cb_g, prod_cb_b;
wire signed [35:0] prod_cr_r, prod_cr_g, prod_cr_b;

// 4. Instancje mno�arek (9 sztuk)
// Porty: CLK, A (18-bit), B (18-bit), P (36-bit)

// Rz�d dla luminancji (Y)
mult_gen_0 m_y_r (.CLK(clk), .A(R_ext), .B(C11), .P(prod_y_r));
mult_gen_0 m_y_g (.CLK(clk), .A(G_ext), .B(C12), .P(prod_y_g));
mult_gen_0 m_y_b (.CLK(clk), .A(B_ext), .B(C13), .P(prod_y_b));

// Rz�d dla Chrominancji Cb
mult_gen_0 m_cb_r (.CLK(clk), .A(R_ext), .B(C21), .P(prod_cb_r));
mult_gen_0 m_cb_g (.CLK(clk), .A(G_ext), .B(C22), .P(prod_cb_g));
mult_gen_0 m_cb_b (.CLK(clk), .A(B_ext), .B(C23), .P(prod_cb_b));

// Rz�d dla Chrominancji Cr
mult_gen_0 m_cr_r (.CLK(clk), .A(R_ext), .B(C31), .P(prod_cr_r));
mult_gen_0 m_cr_g (.CLK(clk), .A(G_ext), .B(C32), .P(prod_cr_g));
mult_gen_0 m_cr_b (.CLK(clk), .A(B_ext), .B(C33), .P(prod_cr_b));    


// --- SEKCJA SUMOWANIA ---

// Sta�e steruj�ce dla linii op�niaj�cych
wire ce = 1'b1; // Aktywacja op�nie� na sta�e

// 1. Wyci�cie cz�ci ca�kowitej (bity 25:17 daj� nam 9-bit�w Signed)
wire signed [8:0] y_r_int = prod_y_r[25:17];
wire signed [8:0] y_g_int = prod_y_g[25:17];
wire signed [8:0] y_b_int = prod_y_b[25:17];

wire signed [8:0] cb_r_int = prod_cb_r[25:17];
wire signed [8:0] cb_g_int = prod_cb_g[25:17];
wire signed [8:0] cb_b_int = prod_cb_b[25:17];

wire signed [8:0] cr_r_int = prod_cr_r[25:17];
wire signed [8:0] cr_g_int = prod_cr_g[25:17];
wire signed [8:0] cr_b_int = prod_cr_b[25:17];

// 2. Sumowanie dla Y (Luminancja)
wire signed [8:0] sum_y_1;
wire signed [8:0] y_b_delayed;
wire signed [8:0] y_final;

// Pierwszy stopie�: R + G (latencja = 1)
c_addsub_0 add_y_1 (.CLK(clk), .A(y_r_int), .B(y_g_int), .S(sum_y_1), .CE(ce));

// Op�nienie sk�adowej B o 1 takt, aby spotka�a si� z wynikiem (R+G)
delayline #(
    .N(9), 
    .DELAY(1)
) del_y_b (
    .clk(clk),
    .idata(y_b_int),
    .odata(y_b_delayed)
);

// Drugi stopie�: (R+G) + B
c_addsub_0 add_y_2 (.CLK(clk), .A(sum_y_1), .B(y_b_delayed), .S(y_final), .CE(ce));

// 3. Sumowanie dla Cb (Chrominancja Blue) + Offset 128
wire signed [8:0] sum_cb_1;
wire signed [8:0] sum_cb_2;
wire signed [8:0] cb_final;

c_addsub_0 add_cb_1 (.CLK(clk), .A(cb_r_int), .B(cb_g_int), .S(sum_cb_1), .CE(ce));
c_addsub_0 add_cb_2 (.CLK(clk), .A(cb_b_int), .B(9'sd128), .S(sum_cb_2), .CE(ce));
c_addsub_0 add_cb_3 (.CLK(clk), .A(sum_cb_1), .B(sum_cb_2), .S(cb_final), .CE(ce));

// 4. Sumowanie dla Cr (Chrominancja Red) + Offset 128
wire signed [8:0] sum_cr_1;
wire signed [8:0] sum_cr_2;
wire signed [8:0] cr_final;

c_addsub_0 add_cr_1 (.CLK(clk), .A(cr_r_int), .B(cr_g_int), .S(sum_cr_1), .CE(ce));
c_addsub_0 add_cr_2 (.CLK(clk), .A(cr_b_int), .B(9'sd128), .S(sum_cr_2), .CE(ce));
c_addsub_0 add_cr_3 (.CLK(clk), .A(sum_cr_1), .B(sum_cr_2), .S(cr_final), .CE(ce));

// --- SYNCHRONIZACJA SYGNA��W STERUJ�CYCH ---

// Globalna latencja: Mno�arki (3) + Sumatory (2)
localparam GLOBAL_LATENCY =5; 

// Konkatenacja sygna��w wej�ciowych w jeden wektor 3-bitowy
wire [2:0] sync_in  = {de_in, hsync_in, vsync_in};
wire [2:0] sync_out;

// Jeden modu� op�niaj�cy dla wszystkich sygna��w steruj�cych
delayline #(
    .N(3),              // Szeroko�� 3 bity
    .DELAY(GLOBAL_LATENCY)
) sync_delay_inst (
    .clk(clk),        // ce zdefiniowane wcze�niej jako 1'b1
    .idata(sync_in),
    .odata(sync_out)
);

// Rozbicie wektora wyj�ciowego na poszczeg�lne porty
assign {de_out, hsync_out, vsync_out} = sync_out;

// --- FINALNE WYJ�CIE DANYCH ---
assign ycbcr_out = {y_final, cb_final, cr_final};

endmodule
