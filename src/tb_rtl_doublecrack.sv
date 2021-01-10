`timescale 1ps/1ps
module tb_rtl_doublecrack();
	
	reg clk, rst_n, en;
	reg [7:0] ct_rddata;
	
	wire [23:0] key;
	wire key_valid, rdy;
	wire [7:0] ct_addr;

	
	
	doublecrack DUT(.*);
	ct_mem ct(.address(ct_addr), .clock(clk), .data(8'b0), .wren(1'b0), .q(ct_rddata));
	
	
	initial begin 
		clk = 0; #1;
		forever begin
		clk = ~clk; #1;
		end
	end
	
	
	initial begin 
		rst_n = 0; 
		en = 0;
		
		$readmemh("test2.memh", ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
		
	
	
		
	#2
		en = 1;
		rst_n = 1;
		
	#2
	
	en = 0;
	
	
	#163531
	$stop;
	
	end

endmodule: tb_rtl_doublecrack
