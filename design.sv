module clk_gen(
input clk, rst,
input [16:0] baud,
output  tx_clk
);
  
  
reg  t_clk = 0;
int  tx_max = 0;
int  tx_count = 0;
  //tx_max = (System Clock Frequency) / (Baud Rate)   ////    Clk  T=tx_max -->  I/tx_max= Freq
/*

4800	50,000,000 / 4,800 ≈ 10416.67 → 10416	10416
9600	50,000,000 / 9,600 ≈ 5208.33 → 5208	5208
19200	50,000,000 / 19,200 ≈ 2604.17 → 2604	2604
38400	50,000,000 / 38,400 ≈ 1302.08 → 1302	1302
57600	50,000,000 / 57,600 ≈ 868.06 → 868	868

*/
always@(posedge clk) begin
		if(rst)begin
			tx_max <= 0;	
			end
		else begin 		
			case(baud)
				4800 :	begin
						  tx_max <=14'd10416;	//10418
			            end
				9600  : begin
						  tx_max <=14'd5208;
				    	end
				14400 : begin 
						  tx_max <=14'd3472;
						 end
				19200 : begin 
						  tx_max <=14'd2604;
						end
				38400: begin
						  tx_max <=14'd1302;
						end
				57600 : begin 
						  tx_max <=14'd868;	
						end 						
				 default: begin 
						  tx_max <=14'd5208;	
						 end
			endcase
		end
	end



always@(posedge clk)
begin
 if(rst) 
   begin
     tx_count <= 0;
     t_clk    <= 0;
   end
 else 
 begin
   if(tx_count < tx_max/2)
       begin
         tx_count <= tx_count + 1;
       end
    else 
       begin
        t_clk   <= ~t_clk;
        tx_count <= 0;
       end
 end
end


  assign tx_clk = t_clk;
endmodule


//  Interface 

interface clk_if;
logic clk, rst;
logic [16:0] baud;
logic tx_clk;
endinterface

  
