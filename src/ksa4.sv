`define RESET 	5'b00000
`define STATE1 	5'b00001
`define STATE2	5'b00010
`define STATE3 	5'b00011
`define STATE4 	5'b00100
`define STATE5 	5'b00101
`define BLANK 	5'b01111
`define STATE0 	5'b10010

module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    // your code here
	reg [8:0] i, j, tmp;
	reg [4:0] curr_state, next_state;

	
	wire done;
	wire [8:0] k;
	wire [7:0] myKey [2:0];
	
	reg set_wrdata, set_tmp, set_j, set_i;
	
	assign myKey[0] = key[23:16];
	assign myKey[1] = key[15:8];
	assign myKey[2] = key[7:0];


	//state transition
	always_ff @(posedge clk, negedge rst_n) begin 
		if(~rst_n)		curr_state = `RESET;
		else if (done)  curr_state = `RESET;
		else 			curr_state = next_state;
	end
	
	//state logic
	always_comb begin 
		case(curr_state)
			`RESET: 	next_state = (en) ? `STATE0 : `RESET;
			`STATE0: 	next_state = `STATE1;
			`STATE1: 	next_state = `BLANK;
			`BLANK: 	next_state = `STATE2;
			`STATE2: 	next_state = `STATE3;
			`STATE3: 	next_state = `STATE4; 
			`STATE4: 	next_state = `STATE5;
			`STATE5: 	next_state = `STATE1;
			default: 	next_state = 4'bxxxx;
		endcase	
	end
	
	//state outputs - combine tmp register with these outputs so need  posedge clk in the sensitivity list instead of _comb
	always_comb begin
		case(curr_state)
			`RESET: 	begin set_i = 0; 	set_j = 0;	 set_tmp = 0; 		wren = 0; set_wrdata = 0; 				addr = 0; rdy = 1; end //request the value of s[i] 
			`STATE0: 	begin set_i = 0; 	set_j = 0;	 set_tmp = 0; 		wren = 0; set_wrdata = 0; 				addr = 0; rdy = 1; end //request the value of s[i] 
			`STATE1: 	begin set_i = 0; 	set_j = 0; 	 set_tmp = 0; 		wren = 0; set_wrdata = 0;	 			addr = i; rdy = 0; end //request the value of s[i] - this state seems to be useless 
			`BLANK: 	begin set_i = 0; 	set_j = 1; 	 set_tmp = 1; 		wren = 0; set_wrdata = 0; 				addr = i; rdy = 0; end //here we will assign j and tmp
			`STATE2: 	begin set_i = 0; 	set_j = 0; 	 set_tmp = 0; 		wren = 0; set_wrdata = 0; 				addr = j; rdy = 0; end //request the value of s[j] 
			`STATE3: 	begin set_i = 0; 	set_j =	0;   set_tmp = 0; 		wren = 1; set_wrdata = 1; 				addr = j; rdy = 0; end //set instruction to write s[j] = tmp
			`STATE4: 	begin set_i = 0; 	set_j = 0;   set_tmp = 0; 		wren = 1; set_wrdata = 0; 				addr = i; rdy = 0; end //value of s[j] requested in state2 is now ready, assign it to s[i]
			`STATE5: 	begin set_i = 1;	set_j = 0;	 set_tmp = 0; 		wren = 0; set_wrdata = 0; 				addr = i; rdy = 0; end //update i to i = i + 1, request s[i]
			default: 	begin set_i = 1'bx; set_j = 1'bx;set_tmp = 1'bx; 	wren = 1'bx; set_wrdata = 8'bx; addr = 8'bx;  rdy = 0; end
		endcase	
	end	
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		i = 0; 
		else if(en) 	i = 0;
		else if(set_i)	i = i + 1; 
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		j = 0; 
		else if (en) 	j = 0;
		else if(set_j)	j = k;	
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin
		if (~rst_n) 	 tmp = 0; 
		else if(set_tmp) tmp = rddata;
	end
	
	always_ff @ (posedge clk) begin 
		if (set_wrdata == 0)
			wrdata = tmp;
		else if (set_wrdata == 1)
			wrdata = rddata;
	end
	
	assign k = ((j + rddata + myKey[i % 3]) % 256);
	assign done = (i > 255) && ~en ? 1 : 0;
endmodule: ksa
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
	
	