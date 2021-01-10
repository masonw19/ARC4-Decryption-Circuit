`timescale 1ps/1ps
module tb_rtl_crack();
			
	reg clk, rst_n, en, mem_en, found, resume;
	reg [7:0] ct_rddata;
	reg [27:0] initKey;
	
	wire rdy, key_valid, checked, final_wren;
	wire [23:0] key;
	wire [7:0] ct_addr, final_wrdata, final_addr;
	
	crack DUT(.*);
	
	ct_mem ct(.address(ct_addr), .clock(clk), .data(8'b0), .wren(1'b0), .q(ct_rddata)); //this is always reading
	
	initial begin 
		clk = 0; #1;
		forever begin
		clk = ~clk; #1;
		end
	end
	
	initial begin 
		
		$readmemh("test2.memh", ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
//		$stop;
	#2
	
		rst_n = 0;
		en = 0;
		initKey = 28'd24;
	#2
		en = 1;
		rst_n = 1;
		resume = 0;
		mem_en = 0;
		found = 0;
	#2
		en = 0;
	
	#515
	
//	$stop; //finished init
	
	#2565
	#515
//	$stop; //finished ksa
	#1700
	resume = 1;
	mem_en = 1;
	
//	$stop;
	
	#4730
//	$stop;
	
	#10000
	
//	$stop;
		initKey = 28'd22;
		rst_n = 0;
		en = 0;
		resume = 1;
		mem_en = 0;
		found = 0;
		
	#10
	
		rst_n = 1;
		
	#2
	
		en = 1;
		
	#2 
		en = 0;
		
	#515 //finished init 
//	$stop;
	#2565
	#515
//	$stop; //finished ksa
	
	#1700
	resume = 1;
	found = 0; 
	#515 //finished init
	found = 0; //just set this now
	mem_en = 1; //just set this now
	#2565
	#515
//	$stop; //finished ksa
	#6470
//	$stop;
	#1700
	rst_n = 0;
	en = 0;
	initKey = 28'd21;
	#2
	en = 1;
	rst_n = 1;
	#2
	en = 0;
	#2
	found = 1;
	resume = 1;
	mem_en = 0;
	#20000
	
	
	$stop;
	
	
	
	
	end

endmodule: tb_rtl_crack
