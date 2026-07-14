module Bridge_top(hclk,hresetn,hwrite,hreadyin,hwdata,haddr,prdata,htrans,
                  pwrite,penable,hreadyout,pselx,paddr,pwdata,hrdata,hresp);
 
input  hclk,hresetn,hwrite,hreadyin;
input  [31:0] hwdata,haddr,prdata;
input  [1:0]  htrans;
 
output        pwrite,penable,hreadyout;
output [2:0]  pselx;
output [31:0] paddr,pwdata,hrdata;
output [1:0]  hresp;
 
// Internal wires connecting AHB_Slave to APB_Controller
wire        valid;
wire        hwritereg, hwritereg1;
wire [31:0] haddr1, haddr2;
wire [31:0] hwdata1, hwdata2;
wire [2:0]  tempselx;

// AHB Slave instantiation

AHB_Slave ahb_slave (
    .Hclk      (hclk),
    .Hresetn   (hresetn),
    .Hwrite    (hwrite),
    .Hreadyin  (hreadyout),   
    .Htrans    (htrans),
    .Haddr     (haddr),
    .Hwdata    (hwdata),
    .Prdata    (prdata),
    .Hresp     (hresp),
    .Hrdata    (hrdata),
    .valid     (valid),
    .Haddr1    (haddr1),
    .Haddr2    (haddr2),
    .Hwdata1   (hwdata1),
    .Hwdata2   (hwdata2),
    .Hwritereg (hwritereg),
    .Hwritereg1(hwritereg1),
    .tempselx  (tempselx)
);
 

// APB Controller instantiation

APB_Controller apb_ctrl (
    .hclk      (hclk),
    .hresetn   (hresetn),
    .valid     (valid),
    .hwrite    (hwrite),
    .haddr     (haddr),
    .hwdata    (hwdata),
    .haddr1    (haddr1),
    .haddr2    (haddr2),
    .hwdata1   (hwdata1),
    .hwdata2   (hwdata2),
    .hwritereg (hwritereg),
    .tempselx  (tempselx),
    .hreadyout (hreadyout),
    .pwrite    (pwrite),
    .penable   (penable),
    .pselx     (pselx),
    .pwdata    (pwdata),
    .paddr     (paddr)
);
 
endmodule
 
