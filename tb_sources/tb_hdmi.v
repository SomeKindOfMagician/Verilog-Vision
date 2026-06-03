`timescale 1ns / 1ps

module tb_hdmi();

// Sygna³y z pliku wejœciowego
wire rx_pclk;
wire rx_de;
wire rx_hsync;
wire rx_vsync;
wire [3:0] sw;
wire [7:0] rx_red;
wire [7:0] rx_green;
wire [7:0] rx_blue;

// Sygna³y po przetworzeniu przez vision_system
wire tx_de;
wire tx_hsync;
wire tx_vsync;
wire [23:0] tx_pixel; // Ca³y wektor RGB/YCbCr

// 1. Instancja wejœcia (czyta obraz .ppm)
hdmi_in file_input (
    .hdmi_clk(rx_pclk), 
    .hdmi_de(rx_de), 
    .hdmi_hs(rx_hsync), 
    .hdmi_vs(rx_vsync), 
    .hdmi_r(rx_red), 
    .hdmi_g(rx_green), 
    .hdmi_b(rx_blue)
);

// 2. KLUCZOWY KROK: Instancja Twojego modu³u vision_system
// £¹czymy wyjœcia z file_input do wejœæ vision_system
vision_system uut (
    .clk(rx_pclk),
    .de_in(rx_de),
    .hsync_in(rx_hsync),
    .vsync_in(rx_vsync),
    .sw(sw),
    .pixel_in({rx_red, rx_green, rx_blue}), // Sk³adamy 3x8 w 24 bity
    
    .de_out(tx_de),
    .hsync_out(tx_hsync),
    .vsync_out(tx_vsync),
    .pixel_out(tx_pixel)
);


// 3. Instancja wyjœcia (zapisuje obraz .ppm)
// Teraz hdmi_out dostaje sygna³y opóŸnione przez vision_system
hdmi_out file_output (
    .hdmi_clk(rx_pclk), 
    .hdmi_vs(tx_vsync), 
    .hdmi_de(tx_de), 
    .hdmi_data({8'b0, tx_pixel}) // Modu³ hdmi_out oczekuje 32 bitów (8 bit zero + 24 bit dane)
);

endmodule