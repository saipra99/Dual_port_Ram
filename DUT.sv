module dual_port 
  # (
     parameter ADDR_WIDTH 	= 8,
     parameter DATA_WIDTH 	= 16,
     parameter DEPTH 		= 256,
     parameter RESET_VAL  	= 16'h2567
  )
  ( input 	clk,
     input 	rstn,
   input [ADDR_WIDTH-1:0]   addrA,
   input [ADDR_WIDTH-1:0]   addrB,
   input sel,
   input wr,
   input [DATA_WIDTH-1:0] wdataA,
   input[DATA_WIDTH-1:0]  wdataB,
   output reg [DATA_WIDTH-1:0] rdataA,
   output reg[DATA_WIDTH-1:0] rdataB,
   output reg	ready);
  
  	// memory element to store data for each addr
   reg [DATA_WIDTH-1:0] ctrl [DEPTH];
  
  reg  ready_dly;
  wire ready_pe;
  
  // If reset is asserted, clear the memory element
  // Else store data to addr for valid writes
  // For reads, provide read data back
  always @ (posedge clk) begin
    if (!rstn) begin
      for (int i = 0; i < DEPTH; i += 1) begin
        ctrl[i] <= RESET_VAL;
      end
    end else begin
    	if (sel & ready & wr) begin
          ctrl[addrA] <= wdataA;
    	end
 
    	if (sel & ready & !wr) begin
          rdataA <= ctrl[addrA];
  		end else begin
          rdataA <= 0;
        end
    end
  end
  
  
   always @ (posedge clk) begin
    if (!rstn) begin
      for (int i = 0; i < DEPTH; i += 1) begin
        ctrl[i] <= RESET_VAL;
      end
    end else begin
      if (sel & ready & wr) begin
          ctrl[addrB] <= wdataB;
    	end
 
      if (sel & ready & !wr) begin
          rdataB <= ctrl[addrB];
  		end else begin
          rdataB <= 0;
        end
    end
  end
  // Ready is driven using this always block
  // During reset, drive ready as 1
  // Else drive ready low for a clock low
  // for a read until the data is given back
  always @ (posedge clk) begin
    if (!rstn) begin
      ready <= 1;
    end else begin
      if (sel & ready_pe) begin
      	ready <= 1;
      end
	 if (sel & ready & !wr) begin
       ready <= 0;
     end
    end
  end
  
  // Drive internal signal accordingly
  always @ (posedge clk) begin
    if (!rstn) ready_dly <= 1;
   		else ready_dly <= ready;
  end
  
   assign ready_pe = ~ready & ready_dly;
endmodule
