`define RESET 	5'b00000
`define STATE1 	5'b00001
`define STATE2	5'b00010
`define STATE3	5'b00011
`define STATE4 	5'b00100
`define STATE5 	5'b00101
`define STATE6 	5'b00110
`define STATE7 	5'b00111
`define STATE8 	5'b01000
`define DONE 	5'b01111
`define STATE0 	5'b10010

module fill_mem(input logic clk, input logic rst_n, input logic en, output logic pt_wren, output logic fill_wren, output logic [7:0] write_to_addr, 
				input logic [7:0] pt_rddata, output logic [7:0] fill_wrdata, output logic [7:0] read_from_addr, output logic rdy);
	
	reg [4:0] curr_state, next_state;
	reg [8:0] i;
	reg [7:0] size;
	
	reg set_ia, set_write_to_addr, set_fill_wrdata, set_size; 
	wire done;	
	
//----------------------------datapath---------------------------------//
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 			begin i = 0; read_from_addr = 8'b0; end
		else if(en) 		begin i = 0; read_from_addr = 8'b0; end
		else if (set_ia) 	begin i = i + 1; read_from_addr = read_from_addr + 1; end
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n)			size = 8'd255;
		else if(en) 		size = 8'd255; 
		else if(set_size)	size = pt_rddata;
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n)					write_to_addr = 8'b0; 
		else if(en) 				write_to_addr = 8'b0; 
		else if(set_write_to_addr)	write_to_addr = write_to_addr + 1;	
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 				fill_wrdata = 8'b0; 
		else if(en) 			fill_wrdata = 8'b0;
		else if(set_fill_wrdata) fill_wrdata = pt_rddata;
	end
	
	assign done = (i > size + 1) ? 1 : 0;
	assign pt_wren = 0; 
 	
//--------------------------statemachine-------------------------------//
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		 	curr_state = `RESET;
		else if (done) 		curr_state = `RESET;
		else 				curr_state = next_state;
	end	
	
	always_comb begin
		case(curr_state)
			`RESET: 	next_state = en ? `STATE0 : `RESET;
			`STATE0: 	next_state = `STATE1;
			`STATE1: 	next_state = `STATE2;
			`STATE2: 	next_state = `STATE3;
			`STATE3: 	next_state = `STATE4; 
			`STATE4: 	next_state = `STATE5;	
			`STATE5: 	next_state = `STATE2;	
		endcase
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	begin set_ia = 0; set_size = 0; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 0; rdy = 1; end  //request the size
			`STATE0: 	begin set_ia = 0; set_size = 1; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 1; rdy = 0; end  //nothing
			`STATE1: 	begin set_ia = 1; set_size = 0; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 0; rdy = 0; end  //set the size
			
			`STATE2: 	begin set_ia = 0; set_size = 0; fill_wren = 1; set_write_to_addr = 0; set_fill_wrdata = 0; rdy = 0; end  //request the data to copy
			`STATE3: 	begin set_ia = 0; set_size = 0; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 1; rdy = 0; end  //data will appear next state so prepare for it
			`STATE4: 	begin set_ia = 1; set_size = 0; fill_wren = 0; set_write_to_addr = 1; set_fill_wrdata = 0; rdy = 0; end  //prepare to increment the addresss, write the data requested in state2 
			`STATE5: 	begin set_ia = 0; set_size = 0; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 0; rdy = 0; end  //prepare to increment the addresss, write the data requested in state2 
			
			//`DONE: 		begin set_ia = 0; set_size = 0; fill_wren = 0; set_write_to_addr = 0; set_fill_wrdata = 0; rdy = 0; end
			default: 	begin set_ia = 1'bx; set_size = 1'bx; fill_wren = 1'bx; set_write_to_addr = 0; set_fill_wrdata = 1'bx; rdy = 0; end
		endcase
	end
	
endmodule: fill_mem