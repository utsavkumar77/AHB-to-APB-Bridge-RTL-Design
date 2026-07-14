module AHB_Master(
    input hclk, hresetn, hreadyout,
    input [31:0] hrdata,
    output reg [31:0] haddr, hwdata,
    output reg hwrite, hreadyin,
    output reg [1:0] htrans
);

    reg [2:0] hburst;   
    reg [2:0] hsize;    
    integer i, j;

    
    // SINGLE WRITE
    
    task single_write();
begin
    // Address phase
    @(posedge hclk);
    #1;
    begin
        hwrite   = 1;
        htrans   = 2'd2;           
        hsize    = 0;
        hburst   = 0;
        hreadyin = 1;
        haddr    = 32'h8000_0000;
    end

    // Data phase
    @(posedge hclk);
    #1;
    begin
        hwdata = 32'h00000080;    
        htrans = 2'd0;             
    end
end
endtask

    // SINGLE READ
    
    task single_read();
    begin
        @(posedge hclk)
        begin
            hwrite  = 0;
            htrans  = 2'd2;
            hsize   = 0;
            hburst  = 0;
            hreadyin = 1;
            haddr   = 32'h8000_0000;
        end

        @(posedge hclk);
        #1;
        begin
            htrans = 2'd0;
        end
    end
    endtask

    
    // BURST WRITE
   
    task burst_write();
    begin
        @(posedge hclk);
        #1;
        begin
            hwrite  = 1'b1;
            htrans  = 2'd2;
            hsize   = 0;
            hburst  = 3'd3;
            hreadyin = 1;
            haddr   = 32'h8000_0000;
        end

        @(posedge hclk);
        #1;
        begin
            haddr  = haddr + 1'b1;
            hwdata = ($random) % 256;
            htrans = 2'd3;
        end

        for (i = 0; i < 2; i = i + 1)
        begin
            @(posedge hclk);
            #1;
            haddr  = haddr + 1;
            hwdata = ($random) % 256;
            htrans = 2'd3;
        end

        @(posedge hclk);
        #1;
        begin
            hwdata = ($random) % 256;
            htrans = 2'd0;
        end
    end
    endtask

endmodule
