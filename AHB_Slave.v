module AHB_Slave(Hclk,Hresetn,Hwrite,Hreadyin,Htrans,Haddr,Hwdata,Prdata,Hresp,Hrdata,valid,Haddr1,Haddr2,Hwdata1,Hwdata2,Hwritereg,Hwritereg1,tempselx);

input Hclk,Hresetn,Hwrite,Hreadyin;
input [1:0]Htrans;
input [31:0]Haddr,Hwdata,Prdata;
output [1:0]Hresp;
output reg [31:0] Haddr1,Haddr2,Hwdata1,Hwdata2;
output reg [2:0]tempselx;
output reg valid,Hwritereg,Hwritereg1;
output [31:0]Hrdata;

//Pipeline Logic for the Address
always@(posedge Hclk)
begin
        if(!Hresetn)
                begin
                        Haddr1 <= 0;
                        Haddr2 <= 0;
                end
        else
                begin
                        Haddr1 <= Haddr;
                        Haddr2 <= Haddr1;
                end
end

//Pipeline Logic for the Data
always@(posedge Hclk)
begin
        if(!Hresetn)
                begin
                        Hwdata1 <= 0;
                        Hwdata2 <= 0;
                end
        else
                begin
                        Hwdata1 <= Hwdata;
                        Hwdata2 <= Hwdata1;
                end
end

//Pipeline Logic for the Write Signal
always@(posedge Hclk)
begin
        if(!Hresetn)
                begin
                        Hwritereg  <= 0;
                        Hwritereg1 <= 0;
                end
        else
                begin
                        Hwritereg  <= Hwrite;
                        Hwritereg1 <= Hwritereg;
                end
end

// Select the Peripheral
always@(*)
begin
        if(Haddr >= 32'h8000_0000 && Haddr < 32'h8400_0000)
                tempselx = 3'b001;
        else if(Haddr >= 32'h8400_0000 && Haddr < 32'h8800_0000)
                tempselx = 3'b010;
        else if(Haddr >= 32'h8800_0000 && Haddr < 32'h8c00_0000)
                tempselx = 3'b100;
        else
                tempselx = 3'b000;
end

//Logic for the valid signal
always@(*)
begin
        if((Haddr >= 32'h8000_0000 && Haddr < 32'h8c00_0000 ) && ( Hreadyin == 1 ) && (Htrans != 2'b00))
                valid = 1'b1;
        else
                valid = 1'b0;
end

assign Hresp  = 2'd0;
assign Hrdata = Prdata ;

endmodule
