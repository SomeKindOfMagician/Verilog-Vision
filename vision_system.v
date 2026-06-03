module vision_system(
    input wire clk,
    input wire de_in,
    input wire hsync_in,
    input wire vsync_in,
    input wire [23:0] pixel_in,
    input  wire [3:0]  sw, // Wej�cie dla prze��cznik�w do sterowania muxem

    output wire de_out,
    output wire hsync_out,
    output wire vsync_out,
    output wire [23:0] pixel_out
);


///MUX
wire [23:0]rgb_mux[15:0];
wire de_mux[15:0];
wire hsync_mux[15:0];
wire vsync_mux[15:0];



    ///RGB2YCBCR
    wire [8:0]y;
    wire [8:0]cb;
    wire [8:0]cr;

    assign de_mux[0] = de_in;
    assign de_mux[1] = de_mux[0];
    assign hsync_mux[0] = hsync_in;
    assign hsync_mux[1] = hsync_mux[0];
    assign vsync_mux[0] = vsync_in;
    assign vsync_mux[1] = vsync_mux[0];


    rgb2ycbcr_1 rgb2ycbcr(
        .clk(clk),
        .de_in(de_mux[0]),
        .hsync_in(hsync_mux[0]),
        .vsync_in(vsync_mux[0]),
        .rgb(pixel_in),

        .de_out(de_mux[2]),        
        .hsync_out(hsync_mux[2]),     
        .vsync_out(vsync_mux[2]),    
        .ycbcr_out({y, cb, cr})

    );
    

    assign de_mux[3] = de_mux[2];
    assign de_mux[4] = de_mux[2];
    assign hsync_mux[3] = hsync_mux[2];
    assign hsync_mux[4] = hsync_mux[2];
    assign vsync_mux[3] = vsync_mux[2];
    assign vsync_mux[4] = vsync_mux[2];


    // PROGOWANIE YCBCR

    localparam Ta = 75; //110, 80

    localparam Tb = 120; //130, 120

    localparam Tc = 130; //140,130

    localparam Td = 175; //160,170

    
    //binaryzacja
    
    wire [7:0]bin;
    assign bin = (cb > Ta && cb < Tb && cr > Tc && cr < Td) ? 8'd255 : 0;
    
    //mediana

    
    wire [7:0]filtered_bin;
    
    context #(
        .H_SIZE(2200) //2200
    ) median (
        .clk(clk),
        .de_in(de_mux[2]),
        .vsync_in(vsync_mux[2]),
        .hsync_in(hsync_mux[2]),
        .mask(bin[0]),
        
        .pixel_out(filtered_bin),
        .de_out(de_mux[7]),
        .vsync_out(vsync_mux[7]),
        .hsync_out(hsync_mux[7])
    );
    
    // CENTROID I WIZUALIZACJA

    wire [10:0]c_x;
    wire [10:0]c_y;
    wire [10:0]x_min_bb;
    wire [10:0]x_max_bb;
    wire [10:0]y_min_bb;
    wire [10:0]y_max_bb;

    localparam IMG_W = 1920;
    //localparam IMG_W = 1920;
    localparam IMG_H = 1080;
    //localparam IMG_H = 1080;
    
    
    //środek ciężkości
    
    centroid #(
        .IMG_H(IMG_H),
        .IMG_W(IMG_W)

    ) cent (
        .clk(clk),
        .ce(1),
        .rst(1),
        .de(de_mux[7]), //2
        .hsync(hsync_mux[7]), //2 
        .vsync(vsync_mux[7]), //2

        .mask(filtered_bin[0]),
        .x(c_x), //1920
        .y(c_y), //1080
        .bb_x_min(x_min_bb),
        .bb_x_max(x_max_bb),
        .bb_y_min(y_min_bb),
        .bb_y_max(y_max_bb)

    );

    wire [23:0]cross_viz;
    
    
    //wizualizacja krzyżyka w środku ciężkosci
    
    vis_cross #(
        .IMG_H(IMG_H),
        .IMG_W(IMG_W)
    )cross(
        .x(c_x),
        .y(c_y),
        .clk(clk),
        .de_in(de_mux[7]),
        .hsync_in(hsync_mux[7]),
        .vsync_in(vsync_mux[7]),
        .pixel_in({filtered_bin,filtered_bin,filtered_bin}),
        .de_out(de_mux[5]),
        .hsync_out(hsync_mux[5]),
        .vsync_out(vsync_mux[5]),
        .pixel_out(cross_viz)
    
    );
   
    //wizualizacja koła i bounding box
    
    wire [23:0]monochrome_red;
   
    vis_centroid #(
        .IMG_H(IMG_H),
        .IMG_W(IMG_W)
    ) vis_cent (

        .clk(clk),
        .x(c_x),
        .y(c_y),
        .de(de_mux[7]),
        .vsync(vsync_mux[7]),
        .hsync(hsync_mux[7]),
        .bb_x_min(x_min_bb),
        .bb_x_max(x_max_bb),
        .bb_y_min(y_min_bb),
        .bb_y_max(y_max_bb),
        .in_pixel({filtered_bin, filtered_bin, filtered_bin}),
        .out_pixel(monochrome_red),
        .de_out(de_mux[6]),
        .vsync_out(vsync_mux[6]),
        .hsync_out(hsync_mux[6])
    );    


    


    // oryginal
    assign rgb_mux[0] = pixel_in;
    // ycbcr
    assign rgb_mux[3] = {y[7:0], cb[7:0], cr[7:0]};
    // progowanie
    assign rgb_mux[4] = {bin, bin, bin};
    // centroid
    assign rgb_mux[5] = cross_viz;
    // vis_centroid
    assign rgb_mux[6] = monochrome_red;
    // filtracja medianowa
    assign rgb_mux[7] = {filtered_bin,filtered_bin,filtered_bin};

    assign pixel_out = rgb_mux[sw];
    
    assign de_out = de_mux[sw];
    
    assign hsync_out = hsync_mux[sw];
    
    assign vsync_out = vsync_mux[sw];


endmodule