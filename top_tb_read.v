module top_tb_sinleread();

    reg hclk, hresetn;

    wire [31:0] haddr, hwdata, hrdata;
    wire [31:0] paddr, pwdata;
    wire [31:0] pwdata_out, paddr_out, prdata;

    wire [1:0] hresp, htrans;
    wire [2:0] pselx, psel_out;

    wire hreadyout, hwrite, hreadyin;
    wire penable, pwrite;
    wire pwrite_out, penable_out;

    // =====================
    // MODULE INSTANTIATIONS
    // =====================

    // AHB MASTER
    AHB_Master ahb (
        hclk,
        hresetn,
        hreadyout,
        hrdata,
        haddr,
        hwdata,
        hwrite,
        hreadyin,
        htrans
    );

    // APB INTERFACE
    APB_Interface apb (
        pwrite,
        penable,
        pselx,
        paddr,
        pwdata,
        pwrite_out,
        penable_out,
        psel_out,
        paddr_out,
        pwdata_out,
        prdata
    );

    // DUT (AHB to APB Bridge)
    Bridge_top bridge (
        hclk,
        hresetn,
        hwrite,
        hreadyin,
        hwdata,
        haddr,
        prdata,
        htrans,
        pwrite,
        penable,
        hreadyout,
        pselx,
        paddr,
        pwdata,
        hrdata,
        hresp
    );

    // =====================
    // CLOCK GENERATION
    // =====================
    initial begin
        hclk = 1'b0;
        forever #10 hclk = ~hclk;
    end

    // =====================
    // RESET TASK
    // =====================
    task reset();
    begin
        @(negedge hclk);
        hresetn = 1'b0;

        @(negedge hclk);
        hresetn = 1'b1;
    end
    endtask

    // =====================
    // TEST SEQUENCE
    // =====================
    initial begin
        #1
        reset();

    

        // ahb.single_write();
           ahb.single_read();
        // ahb.burst_write();

        #200 $finish;
    end

endmodule
