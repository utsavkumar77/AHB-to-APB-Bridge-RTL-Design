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

// BLOCK 1: Present State Logic (Sequential)
always@(posedge hclk)
begin
    if(!hresetn)
        state <= st_idle;
    else
        state <= next_state;
end
          
// BLOCK 2: Next State Logic (Combinational)
always@(*)
begin
    case(state)

        st_idle : begin
            if(valid==1'b1 && hwrite==1'b1)       
                next_state = st_wait;
            else if(valid==1'b1 && hwrite==1'b0)   
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


// BLOCK 3: Temp Output Logic (Combinational)

always@(*)
begin
    
    paddr_temp     = 32'd0;
    pwdata_temp    = 32'd0;
    pwrite_temp    = 1'b0;
    pselx_temp     = 3'b000;
    penable_temp   = 1'b0;
    hreadyout_temp = 1'b1;

    case(state)

        
        st_idle : begin
            if(valid==1'b1 && hwrite==1'b0)        
            begin
                paddr_temp     = haddr;
                pwrite_temp    = 1'b0;
                pselx_temp     = tempselx;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;  
                pwdata_temp    = 32'd0;
            end
            else if(valid==1'b1 && hwrite==1'b1)   
            begin
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b1;  
                pwdata_temp    = 32'd0; 
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

        
        st_wait : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  
            penable_temp   = 1'b0;      
            hreadyout_temp = 1'b0;      
        end

        
        st_writep : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  
            penable_temp   = 1'b1;      
            hreadyout_temp = 1'b1;      
        end

        st_wenablep : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  
            penable_temp   = 1'b0;      
            hreadyout_temp = 1'b0;      
        end

        
        st_write : begin
            paddr_temp     = haddr1;
            pwdata_temp    = hwdata1;
            pwrite_temp    = hwritereg;
            pselx_temp     = tempselx;  
            penable_temp   = 1'b1;      
            hreadyout_temp = 1'b1;      
        end

        
        st_wenable : begin
            paddr_temp     = 32'd0;
            pwdata_temp    = 32'd0;
            pwrite_temp    = 1'b0;
            pselx_temp     = 3'b000;    
            penable_temp   = 1'b0;      
            hreadyout_temp = 1'b1;      
        end

        
        st_read : begin
            paddr_temp     = haddr;
            pwdata_temp    = 32'd0;
            pwrite_temp    = 1'b0;
            pselx_temp     = tempselx;  
            penable_temp   = 1'b1;      
            hreadyout_temp = 1'b1;      
        end

        st_renable : begin
            if(valid==1'b1 && hwritereg==1'b0)
            begin
                
                paddr_temp     = haddr;
                pwrite_temp    = 1'b0;
                pselx_temp     = tempselx;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;
                pwdata_temp    = 32'd0;
            end
            else if(valid==1'b1 && hwritereg==1'b1)
            begin
                
                paddr_temp     = 32'd0;
                pwrite_temp    = 1'b0;
                pselx_temp     = 3'b000;
                penable_temp   = 1'b0;
                hreadyout_temp = 1'b0;
                pwdata_temp    = 32'd0;
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

    endcase
end


// BLOCK 4: Output Logic (Sequential)

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
