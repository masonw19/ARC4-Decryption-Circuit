`timescale 1ps/1ps
module tb_rtl_task5(); //i changed this from 'tb_task5' to 'tb_rtl_task5' 
	reg CLOCK_50;
	reg [3:0] KEY;
	reg [9:0] SW;
	
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	wire [9:0] LEDR;
	
	reg err;
	
	task5 DUT(.*);
	
	reg [7:0] ct_addr, ct_wrdata;
	wire [7:0] ct_rddata;
	reg wren;
	
	
	
 
	initial begin 
		CLOCK_50 = 0; #1;
		forever begin
		CLOCK_50 = ~CLOCK_50; #1;
		end
	end

	initial begin 
		err = 0; 
		KEY = 4'b1111;
		$readmemh("test2.memh", DUT.ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
	#2
		KEY = 4'b0111;
	#2
		KEY = 4'b1111;
	
#163531	
	//#515
	//#3500
	//#200000
	$stop;
	end 
endmodule: tb_rtl_task5




