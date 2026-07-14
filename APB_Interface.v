module APB_Interface(
    input pwrite,
    input penable,
    input [2:0] pselx,
    input [31:0] paddr,
    input [31:0] pwdata,

    output pwrite_out,
    output penable_out,
    output [2:0] psel_out,
    output [31:0] paddr_out,
    output [31:0] pwdata_out,
    output reg [31:0] prdata
);

    assign pwrite_out  = pwrite;
    assign psel_out    = pselx;
    assign paddr_out   = paddr;
    assign pwdata_out  = pwdata;
    assign penable_out = penable;

    always@(*)
begin
    if(!pwrite && penable)
        prdata = 32'd25;
    else
        prdata = 32'd0;  // explicit default ? no latch
end

endmodule
