`define RESET 	5'b00000
`define STATE1 	5'b00001
`define STATE2	5'b00010
`define STATE3 	5'b00011
`define STATE4	5'b00100
`define STATE5 	5'b00101
`define STATE6	5'b00110
`define STATE7 	5'b00111
`define STATE8 	5'b01000
`define STATE9 	5'b01001
`define BLANK 	5'b01111
`define BLANK2 	5'b10000
//why the hell does rtl work and not syn
module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
			
		reg [7:0] i, j, tmp1, tmp2, tmp3, size, ct_addr_val;
		reg [8:0] k;
		reg [4:0] curr_state, next_state;		
		reg set_i, set_j, set_k, set_s_wrdata, set_pt_wrdata, set_size, set_tmp1, set_tmp2, set_tmp3;
		reg [2:0] set_tmps, set_counters;
		
		wire [7:0] next_j, new_addr;
		
//--------------datapath-------------------------------//		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if(~rst_n) 			i = 1; 
			else if(en)			i = 1; 
			else if(set_i)		i = (i + 1) % 256; 		
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if(~rst_n) 		j = 0; 
			else if(en)	 	j = 0; 
			else if(set_j)	j = next_j;	
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if(~rst_n) 		k = 1; 
			else if(en) 	k = 1; 
			else if(set_k)	k = k + 1;	
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin
			if (~rst_n) 	 	tmp1 = 0; 
			else if(set_tmp1) 	tmp1 = s_rddata;
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if (~rst_n) 	 	tmp2 = 0;
			else if(set_tmp2)	tmp2 = s_rddata;
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if (~rst_n) 	 	tmp3 = 0;
			else if(set_tmp3)	tmp3 = s_rddata;
		end
		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if (~rst_n) 	 	size = 255;
			else if (en) 	 	size = 255;
			else if(set_size)	size = ct_rddata;
		end
		
		always_ff @ (posedge clk) begin 
			if (~set_s_wrdata ) 	s_wrdata = tmp1; 
			else if(set_s_wrdata) s_wrdata = s_rddata;
		end
		
		always_ff @ (posedge clk) begin 
			if (~set_pt_wrdata ) 	pt_wrdata = ct_rddata; 
			else if(set_pt_wrdata) 	pt_wrdata = ct_rddata ^ tmp3;
		end
		
		assign next_j = (j + s_rddata) % 256;
		assign new_addr = (tmp1 + tmp2) % 256;
		assign done = ((k > size) && ~en) ? 1 : 0; 
		assign ct_addr = ct_addr_val;
		
		
//--------------------stateamchine-------------------------//		
		always_ff @ (posedge clk, negedge rst_n) begin 
			if (~rst_n) 	 curr_state = `RESET;
			else if (done) 	 curr_state = `RESET; 
			else 			 curr_state = next_state;
		end
		
		always_comb begin 
			case(curr_state)
				`RESET: 	next_state = (en) ? `STATE1 : `RESET; 
				`STATE1: 	next_state = `BLANK;
				`BLANK: 	next_state = `STATE2;
				`STATE2: 	next_state = `BLANK2;
				`BLANK2: 	next_state = `STATE3;
				`STATE3: 	next_state = `STATE4;
				`STATE4: 	next_state = `STATE5; 
				`STATE5: 	next_state = `STATE6;
				`STATE6: 	next_state = `STATE7;
				`STATE7: 	next_state = `STATE8;
				`STATE8: 	next_state = `STATE9;
				`STATE9: 	next_state = `STATE1;
				default: 	next_state = 4'bxxxx;
			endcase
		end
		
		always_comb begin 
			case(curr_state)
				`RESET: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b0; s_addr = 8'd1; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b1; end //request an s[1]
				`STATE1:	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b0; s_addr = i; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end 
				`BLANK: 	begin set_counters = 3'b010; set_tmps = 3'b100; s_wren = 1'b0; set_s_wrdata = 1'b0; s_addr = i; 		pt_wren = 1'b1; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b1; rdy = 1'b0; end //assign j and tmp1 & set size
				`STATE2: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b0; s_addr = j; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //request s[j] 
				`BLANK2: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b0; s_addr = j; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //wrtite s[j] = s[i], (s[j] = tmp1)
				`STATE3: 	begin set_counters = 3'b000; set_tmps = 3'b010; s_wren = 1'b1; set_s_wrdata = 1'b1; s_addr = j; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //wrtite s[j] = s[i], (s[j] = tmp1)
				`STATE4: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b1; set_s_wrdata = 1'b0; s_addr = i; 		pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //s[j] from state2 is ready, tmp2 = s[j],s[i] = s[j]
				`STATE5: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b1; s_addr = new_addr;	pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //s[(tmp1 + tmp2) % 256]
				`STATE6: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b1; s_addr = new_addr;	pt_wren = 1'b0; set_pt_wrdata = 1'b0; pt_addr = 8'b0; 		ct_addr_val = k[7:0]; 	set_size = 1'b0; rdy = 1'b0; end //get c[k]
				`STATE7: 	begin set_counters = 3'b000; set_tmps = 3'b001; s_wren = 1'b0; set_s_wrdata = 1'b1; s_addr = i;			pt_wren = 1'b0; set_pt_wrdata = 1'b1; pt_addr = 8'b0; 		ct_addr_val = k[7:0]; 	set_size = 1'b0; rdy = 1'b0; end //data requested in state 5 is now available, assign to tmp3
				`STATE8: 	begin set_counters = 3'b000; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b1; s_addr = i;			pt_wren = 1'b1; set_pt_wrdata = 1'b1; pt_addr = k[7:0]; 	ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //write to pt wrdata
				`STATE9: 	begin set_counters = 3'b101; set_tmps = 3'b000; s_wren = 1'b0; set_s_wrdata = 1'b1; s_addr = i;			pt_wren = 1'b1; set_pt_wrdata = 1'b0; pt_addr = k[7:0];		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //increment i and k
				default: 	begin set_counters = 3'bxxx; set_tmps = 3'bxxx; s_wren = 1'bx; set_s_wrdata = 1'bx; s_addr = i;			pt_wren = 1'bx; set_pt_wrdata = 1'b1; pt_addr = 8'b0; 		ct_addr_val = 8'b0; 	set_size = 1'b0; rdy = 1'b0; end //increment i and k
			endcase
			 {set_tmp1, set_tmp2, set_tmp3 } = set_tmps;
			 {set_i, set_j, set_k} = set_counters;
		end
endmodule: prga

