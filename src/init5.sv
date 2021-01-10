`define RESET 	5'b00000
`define STATE1 	5'b00001

module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

	reg update;
	reg [9:0] i;
	reg [4:0] curr_state, next_state;
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n)  		begin addr = 8'b0; 		i = 9'b0; 	end
		else if(en)  		begin addr = 8'b0; 		i = 9'b0; 	end
		else if(update) 	begin addr = addr + 1; 	i = i + 1;  end
	end		
	
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) curr_state = `RESET;
		else 		curr_state = next_state;	
	end
	
	always_comb begin
		case(curr_state)
			`RESET:  next_state = (en) 			? 	`STATE1 : `RESET;
			`STATE1: next_state = (i > 255) 	? 	`RESET : `STATE1;
			default: next_state = 5'bxxxx;
		endcase
	end
	
	
	//state outputs
	always_comb begin 
		case(curr_state)
			`RESET: 	begin update = 0; wren = 0; wrdata = 0; rdy = 1; end
			`STATE1: 	begin update = 1; wren = 1; wrdata = i; rdy = 0; end
			default: 	begin update = 1'bx; wren = 1'bx; wrdata = 8'bx; rdy = 1'bx; end
		endcase
	end	

endmodule: init


