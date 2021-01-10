`timescale 1ps/1ps
module tb_syn_task5();

// Your testbench goes here.
	reg CLOCK_50;
	reg [3:0] KEY;
	reg [9:0] SW;
	
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	wire [9:0] LEDR;
	
	reg err;
	
	wire altera_reserved_tms, altera_reserved_tck, altera_reserved_tdi, altera_reserved_tdo;
	task5 DUT (.*, .altera_reserved_tms(altera_reserved_tms), .altera_reserved_tck(altera_reserved_tck), .altera_reserved_tdi(altera_reserved_tdi), .altera_reserved_tdo(altera_reserved_tdo));
	
	
	
	
 
	initial begin 
		CLOCK_50 = 0; #1;
		forever begin
		CLOCK_50 = ~CLOCK_50; #1;
		end
	end

	initial begin 
		err = 0; 
		KEY = 4'b1111;
		$readmemh("test2.memh", DUT.\ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem);
	#2
		KEY = 4'b0111;
	#2
		KEY = 4'b1111;
	
#163531	
	//#515
//	$stop;
	//#3500
	//$stop;
	//#200000
	$stop;
	end 

endmodule: tb_syn_task5
