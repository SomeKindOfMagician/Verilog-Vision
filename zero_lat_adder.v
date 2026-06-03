module zero_lat_adder (
    input [10:0] A,     
    input [31:0] B,      
    output [32:0] S      
);
    assign S = A + B;
endmodule