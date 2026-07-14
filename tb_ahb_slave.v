module tb_AHB_Slave;

reg Hclk, Hresetn, Hwrite, Hreadyin;
reg [1:0] Htrans;
reg [31:0] Haddr, Hwdata, Prdata;
wire [1:0] Hresp;
wire [31:0] Hrdata, Haddr1, Haddr2, Hwdata1, Hwdata2;
wire [2:0] tempselx;
wire valid, Hwritereg, Hwritereg1;

AHB_Slave dut (
  .Hclk(Hclk), .Hresetn(Hresetn), .Hwrite(Hwrite),
  .Hreadyin(Hreadyin), .Htrans(Htrans), .Haddr(Haddr),
  .Hwdata(Hwdata), .Prdata(Prdata), .Hresp(Hresp),
  .Hrdata(Hrdata), .valid(valid), .Haddr1(Haddr1),
  .Haddr2(Haddr2), .Hwdata1(Hwdata1), .Hwdata2(Hwdata2),
  .Hwritereg(Hwritereg), .Hwritereg1(Hwritereg1),
  .tempselx(tempselx)
);

always #5 Hclk = ~Hclk;

initial 
begin
  $dumpfile("tb_AHB_Slave.vcd"); 
  $dumpvars(0,tb_AHB_Slave);
end

initial 
begin
  Hclk=0; 
  Hresetn=0; 
  Hwrite=0; 
  Hreadyin=0;
  Htrans=2'b00; 
  Haddr=0; 
  Hwdata=0; 
  Prdata=0;

  @(posedge Hclk); 
  @(posedge Hclk);


  Hresetn=1;
  Hreadyin=1;
  @(posedge Hclk);

  // TEST 1: Slave 1 write ? expect tempselx=001 valid=1
  Haddr=32'h8000_0000; Hwdata=32'hAAAA_AAAA;
  Hwrite=1; 
  Htrans=2'b10;
  @(posedge Hclk); 
  @(posedge Hclk);

  // TEST 2: Slave 2 write ? expect tempselx=010 valid=1
  Haddr=32'h8400_0000; Hwdata=32'hBBBB_BBBB;
  Hwrite=1;
  Htrans=2'b10;
  @(posedge Hclk);
  @(posedge Hclk);

  // TEST 3: Slave 3 write ? expect tempselx=100 valid=1
  Haddr=32'h8800_0000; Hwdata=32'hCCCC_CCCC;
  Hwrite=1;
  Htrans=2'b10;
  @(posedge Hclk);
  @(posedge Hclk);

  // TEST 4: Invalid address ? expect tempselx=000 valid=0
  Haddr=32'h9000_0000;
  Htrans=2'b10;
  @(posedge Hclk);
  @(posedge Hclk);

  // TEST 5: Read ? expect Hrdata = Prdata
  Haddr=32'h8000_0004; Hwrite=0;
  Htrans=2'b10; 
  Prdata=32'hDEAD_BEEF;
  @(posedge Hclk); 
  @(posedge Hclk);

  // TEST 6: IDLE ? valid must be 0
  Haddr=32'h8000_0000;
  Htrans=2'b00;
  @(posedge Hclk);

  #20; $display("Simulation complete"); $finish;
end
endmodule
