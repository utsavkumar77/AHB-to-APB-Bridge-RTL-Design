module APB_Controller(hclk,hresetn,valid,hwrite,haddr,hwdata,haddr1,haddr2,hwdata1,hwdata2,hwritereg,tempselx,hreadyout,pwrite,penable,pselx,pwdata,paddr);

input valid, hwritereg, hclk, hresetn, hwrite;
input [31:0] haddr1, haddr2, hwdata1, hwdata2, haddr, hwdata;
input [2:0]  tempselx;
output reg pwrite, penable;
output reg [2:0]  pselx;
output reg hreadyout;
output reg [31:0] pwdata, paddr;

parameter st_idle    = 3'b000,
          st_wait    = 3'b001,
          st_write   = 3'b010,
          st_writep  = 3'b011,
          st_wenablep = 3'b100,
          st_wenable  = 3'b101,
          st_read     = 3'b110,
          st_renable  = 3'b111;

reg [2:0] state, next_state;

reg [31:0] paddr_temp, pwdata_temp;
reg penable_temp, pwrite_temp, hreadyout_temp;
reg [2:0] pselx_temp;

//=======================================================
// BLOCK 1: Present State Logic (Sequential)
//=======================================================
always@(posedge hclk)
begin
    if(!hresetn)
        state <= st_idle;
    else
        state <= next_state;
end

//=======================================================
// BLOCK 2: Next State Logic (Combinational)
//
// BUG FIX in st_idle: Changed hwritereg ? hwrite.
// Reason: valid fires at the same clock cycle that hwrite
// is presented (cycle 1 of address phase). hwritereg is
// hwrite delayed by 1 register ? it is still 0 in cycle 1.
// So checking hwritereg in IDLE always gave wrong direction.
// All other states (wait, wenablep, wenable, renable) are
// past the address phase, so hwritereg is correct there.
//=======================================================
always@(*)
begin
    case(state)

        st_idle : begin
            if(valid==1'b1 && hwrite==1'b1)       // use hwrite not hwritereg
                next_state = st_wait;
            else if(valid==1'b1 && hwrite==1'b0)   // use hwrite not hwritereg
                next_state = st_read;
            else
                next_state = st_idle;
        end

        st_wait : begin
            if(valid==1'b1 && hwritereg==1'b1)
                next_state = st_writep;
            else if(valid==1'b1 && hwritereg==1'b0)
                next_state = st_read;
            else
                next_state = st_idle;
        end

        st_writep : begin
            next_state = st_wenablep;
        end

        st_write : begin
            if(valid==1'b1)
                next_state = st_wenablep;
            else
                next_state = st_wenable;
        end

        st_wenablep : begin
            if(valid==1'b1 && hwritereg==1'b1)
                next_state = st_writep;
            else if(valid==1'b1 && hwritereg==1'b0)
                next_state = st_read;
            else if(valid==1'b0)
                next_state = st_write;
            else
                next_state = st_wenablep;
        end

        st_wenable : begin
            if(valid==1'b1 && ~hwritereg)
                next_state = st_read;
            else if(~valid)
                next_state = st_idle;
            else
                next_state = st_wenable;
        end

        st_read : begin
            next_state = st_renable;
        end

        st_renable : begin
            if(valid==1'b1 && hwritereg==1'b0)
                next_state = st_read;
            else if(valid==1'b1 && hwritereg==1'b1)
                next_state = st_wait;
            else if(~valid)
                next_state = st_idle;
            else
                next_state = st_renable;
        end

        default : next_state = st_idle;

    endcase
end

//=======================================================
// BLOCK 3: Temp Output Logic (Combinational)
//
// KEY PRINCIPLE: outputs are registered (1 cycle delay).
// Temp in state X = what appears as output in state X+1.
//
// WAVEFORM TARGET:
//   IDLE     : PSEL=0 PENABLE=0 HREADY=1
//   WAIT     : PSEL=0 PENABLE=0 HREADY=0  ? stall
//   WRITEP   : PSEL=1 PENABLE=0 HREADY=0  ? setup
//   WENABLEP : PSEL=1 PENABLE=1 HREADY=1  ? transfer
//   WRITE    : PSEL=1 PENABLE=0 HREADY=0  ? single setup
//   WENABLE  : PSEL=1 PENABLE=1 HREADY=1  ? single transfer
//   READ     : PSEL=1 PENABLE=0 HREADY=0  ? read setup
//   RENABLE  : PSEL=1 PENABLE=1 HREADY=1  ? read transfer
//
// BUG FIX in st_idle: use hwrite not hwritereg (same reason as Block 2)
//=======================================================
always@(*)
begin
    // Safe default ? prevents latches
    paddr_temp     = 32'd0;
    pwdata_temp    = 32'd0;
    pwrite_temp    = 1'b0;
    pselx_temp     = 3'b000;
    penable_temp   = 1'b0;
    hreadyout_temp = 1'b1;

    case(state)

        // Target for WAIT:  PSEL=0, PENABLE=0, HREADY=1 (write)
        // Target for READ:  PSEL=1, PENABLE=0, HREADY=0 (read)
        st_idle : begin
            if(valid==1'b1 && hwrite==1'b0)        // use hwrite not hwritereg
            begin
                paddr_temp     = haddr;
                pwrite_temp    = 1'b0;
                pselx_temp     = tempselx;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;  // READ: stall starts at READ state
                pwdata_temp    = 32'd0;
            end
            else if(valid==1'b1 && hwrite==1'b1)   // use hwrite not hwritereg
            begin
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b1;  // WRITE: HREADY=1 in WAIT so valid stays alive
                pwdata_temp    = 32'd0; // Stall happens in WRITEP (via WAIT temp below)
            end
            else
            begin
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b1;
                pwdata_temp    = 32'd0;
            end
        end

        // Target for WRITEP: PSEL=1, PENABLE=0, HREADY=0
        st_wait : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  // PSEL=1 in WRITEP
            penable_temp   = 1'b0;      // PENABLE=0 in WRITEP
            hreadyout_temp = 1'b0;      // HREADY=0 in WRITEP (stall)
        end

        // Target for WENABLEP: PSEL=1, PENABLE=1, HREADY=1
        st_writep : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  // PSEL=1 in WENABLEP
            penable_temp   = 1'b1;      // PENABLE=1 in WENABLEP (transfer!)
            hreadyout_temp = 1'b1;      // HREADY=1 in WENABLEP (release)
        end

        // Target for next WRITEP: PSEL=1, PENABLE=0, HREADY=0
        st_wenablep : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  // PSEL=1 in next WRITEP
            penable_temp   = 1'b0;      // PENABLE=0 in next WRITEP
            hreadyout_temp = 1'b0;      // HREADY=0 in next WRITEP
        end

        // Target for WENABLE: PSEL=1, PENABLE=1, HREADY=1
        st_write : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  // PSEL=1 in WENABLE
            penable_temp   = 1'b1;      // PENABLE=1 in WENABLE (transfer!)
            hreadyout_temp = 1'b1;      // HREADY=1 in WENABLE (release)
        end

        // Target for IDLE: PSEL=0, PENABLE=0, HREADY=1
        st_wenable : begin
            paddr_temp     = 32'd0;
            pwdata_temp    = 32'd0;
            pwrite_temp    = 1'b0;
            pselx_temp     = 3'b000;    // PSEL=0 in IDLE
            penable_temp   = 1'b0;      // PENABLE=0 in IDLE
            hreadyout_temp = 1'b1;      // HREADY=1 in IDLE
        end

        // Target for RENABLE: PSEL=1, PENABLE=1, HREADY=1
        st_read : begin
            paddr_temp     = haddr;
            pwdata_temp    = 32'd0;
            pwrite_temp    = 1'b0;
            pselx_temp     = tempselx;  // PSEL=1 in RENABLE
            penable_temp   = 1'b1;      // PENABLE=1 in RENABLE (read transfer!)
            hreadyout_temp = 1'b1;      // HREADY=1 in RENABLE (release)
        end

        st_renable : begin
            if(valid==1'b1 && hwritereg==1'b0)
            begin
                // Next READ: target READ needs PSEL=1, PENABLE=0, HREADY=0
                paddr_temp     = haddr;
                pwrite_temp    = 1'b0;
                pselx_temp     = tempselx;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;
                pwdata_temp    = 32'd0;
            end
            else if(valid==1'b1 && hwritereg==1'b1)
            begin
                // Next WRITE: target WAIT needs PSEL=0, PENABLE=0, HREADY=0
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;
                pwdata_temp    = 32'd0;
            end
            else
            begin
                // No valid: target IDLE needs PSEL=0, PENABLE=0, HREADY=1
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b1;
                pwdata_temp    = 32'd0;
            end
        end

    endcase
end

//=======================================================
// BLOCK 4: Output Logic (Sequential)
// Registers temp onto actual outputs at posedge hclk.
//=======================================================
always@(posedge hclk or negedge hresetn)
begin
    if(!hresetn)
    begin
        paddr     <= 32'd0;
        pwdata    <= 32'd0;
        pwrite    <= 1'b0;
        pselx     <= 3'b000;
        penable   <= 1'b0;
        hreadyout <= 1'b1;
    end
    else
    begin
        paddr     <= paddr_temp;
        pwdata    <= pwdata_temp;
        pwrite    <= pwrite_temp;
        pselx     <= pselx_temp;
        penable   <= penable_temp;
        hreadyout <= hreadyout_temp;
    end
end

endmodule
