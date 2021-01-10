`define RESET 	5'b00000
`define STATE1 	5'b00001
`define STATE2	5'b00010
`define STATE3	5'b00011

module task5(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);
	
	reg en; 
	reg [4:0] curr_state, next_state;
	
	wire rdy, key_valid; 
	wire [7:0] ct_addr, ct_wrdata, ct_rddata;
	wire [23:0] key;
	
	assign LEDR = 10'b0;
	

    ct_mem ct(.address(ct_addr), .clock(CLOCK_50), .data(ct_wrdata), .wren(1'b0), .q(ct_rddata));
	
    doublecrack dc(.clk(CLOCK_50), .rst_n(KEY[3]), .en(en), .rdy(rdy), .key(key), 
				   .key_valid(key_valid), .ct_addr(ct_addr), .ct_rddata(ct_rddata));
				   
	always_ff @ (posedge CLOCK_50, negedge KEY[3]) begin 
		if(~KEY[3]) en = 1;
		else if(en) en = 0;
	end
	
	always_ff @ (posedge CLOCK_50, negedge KEY[3]) begin 
		if(~KEY[3]) 	curr_state = `RESET;
		else 			curr_state = next_state;	
	end	
	
	always_comb begin 
		case(curr_state)
			`RESET: 	next_state = `STATE1;
			`STATE1: 	next_state = `STATE2;
			`STATE2: 	next_state = (rdy && ~en) ? `STATE3 : `STATE2;
			`STATE3: 	next_state = `STATE3;
			default: 	next_state = 5'bx;
		endcase
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	
				begin 
					HEX0 = 7'b1111111;
					HEX1 = 7'b1111111;
					HEX2 = 7'b1111111;
					HEX3 = 7'b1111111;
					HEX4 = 7'b1111111;
					HEX5 = 7'b1111111;
				end
			`STATE1: 
				begin 
					HEX0 = 7'b1111111;
					HEX1 = 7'b1111111;
					HEX2 = 7'b1111111;
					HEX3 = 7'b1111111;
					HEX4 = 7'b1111111;
					HEX5 = 7'b1111111;
				end
			`STATE2: 
				begin 
					HEX0 = 7'b1111111;
					HEX1 = 7'b1111111;
					HEX2 = 7'b1111111;
					HEX3 = 7'b1111111;
					HEX4 = 7'b1111111;
					HEX5 = 7'b1111111;
				end
			`STATE3:
				begin 
					if (key_valid) begin 
						case(key[3:0])
							4'b0000:	HEX0 = 7'b100_0000; //displays '0'
							4'b0001:	HEX0 = 7'b111_1001; //displays '1'
							4'b0010:	HEX0 = 7'b010_0100; //displays '2'
							4'b0011:	HEX0 = 7'b011_0000; //displays '3'
							4'b0100:	HEX0 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX0 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX0 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX0 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX0 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX0 = 7'b001_0000; //displays '9'
							4'b1010:	HEX0 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX0 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX0 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX0 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX0 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX0 = 7'b000_1110; //displays 'F'
							default: 	HEX0 = 7'b111_1111; //display is blank	
						endcase
						case(key[7:4])
							4'b0000:	HEX1 = 7'b100_0000; //displays '0'
							4'b0001:	HEX1 = 7'b111_1001; //displays '1'
							4'b0010:	HEX1 = 7'b010_0100; //displays '2'
							4'b0011:	HEX1 = 7'b011_0000; //displays '3'
							4'b0100:	HEX1 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX1 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX1 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX1 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX1 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX1 = 7'b001_0000; //displays '9'
							4'b1010:	HEX1 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX1 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX1 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX1 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX1 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX1 = 7'b000_1110; //displays 'E'
							default: 	HEX1 = 7'b111_1111; //display is blank	
						endcase
						case(key[11:8])
							4'b0000:	HEX2 = 7'b100_0000; //displays '0'
							4'b0001:	HEX2 = 7'b111_1001; //displays '1'
							4'b0010:	HEX2 = 7'b010_0100; //displays '2'
							4'b0011:	HEX2 = 7'b011_0000; //displays '3'
							4'b0100:	HEX2 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX2 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX2 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX2 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX2 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX2 = 7'b001_0000; //displays '9'
							4'b1010:	HEX2 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX2 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX2 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX2 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX2 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX2 = 7'b000_1110; //displays 'E'
							default: 	HEX2 = 7'b111_1111; //display is blank	
						endcase
						case(key[15:12])
							4'b0000:	HEX3 = 7'b100_0000; //displays '0'
							4'b0001:	HEX3 = 7'b111_1001; //displays '1'
							4'b0010:	HEX3 = 7'b010_0100; //displays '2'
							4'b0011:	HEX3 = 7'b011_0000; //displays '3'
							4'b0100:	HEX3 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX3 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX3 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX3 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX3 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX3 = 7'b001_0000; //displays '9'
							4'b1010:	HEX3 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX3 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX3 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX3 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX3 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX3 = 7'b000_1110; //displays 'E'
							default: 	HEX3 = 7'b111_1111; //display is blank	
						endcase
						case(key[19:16])
							4'b0000:	HEX4 = 7'b100_0000; //displays '0'
							4'b0001:	HEX4 = 7'b111_1001; //displays '1'
							4'b0010:	HEX4 = 7'b010_0100; //displays '2'
							4'b0011:	HEX4 = 7'b011_0000; //displays '3'
							4'b0100:	HEX4 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX4 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX4 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX4 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX4 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX4 = 7'b001_0000; //displays '9'
							4'b1010:	HEX4 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX4 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX4 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX4 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX4 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX4 = 7'b000_1110; //displays 'E'
							default: 	HEX4 = 7'b111_1111; //display is blank	
						endcase
						case(key[23:20])
							4'b0000:	HEX5 = 7'b100_0000; //displays '0'
							4'b0001:	HEX5 = 7'b111_1001; //displays '1'
							4'b0010:	HEX5 = 7'b010_0100; //displays '2'
							4'b0011:	HEX5 = 7'b011_0000; //displays '3'
							4'b0100:	HEX5 = 7'b001_1001; //displays '4'
							4'b0101: 	HEX5 = 7'b001_0010; //displays '5'
							4'b0110: 	HEX5 = 7'b000_0010; //displays '6'
							4'b0111: 	HEX5 = 7'b111_1000; //displays '7'
							4'b1000: 	HEX5 = 7'b000_0000; //displays '8'
							4'b1001: 	HEX5 = 7'b001_0000; //displays '9'
							4'b1010:	HEX5 = 7'b000_1000; //displays 'A'
							4'b1011:	HEX5 = 7'b000_0011; //displays 'b'
							4'b1100:	HEX5 = 7'b100_0110; //displays 'C'
							4'b1101:	HEX5 = 7'b010_0001; //displays 'd'
							4'b1110:	HEX5 = 7'b000_0110; //displays 'E'
							4'b1111:	HEX5 = 7'b000_1110; //displays 'E'
							default: 	HEX5 = 7'b111_1111; //display is blank	
						endcase
					end
				else begin 
					HEX0 = 7'b0111111;
					HEX1 = 7'b0111111;
					HEX2 = 7'b0111111;
					HEX3 = 7'b0111111;
					HEX4 = 7'b0111111;
					HEX5 = 7'b0111111;
				end
			end
			default: 
				begin 
					HEX0 = 7'bx;
					HEX1 = 7'bx;
					HEX2 = 7'bx;
					HEX3 = 7'bx;
					HEX4 = 7'bx;
					HEX5 = 7'bx;
				
				end
		endcase
	end

endmodule: task5










