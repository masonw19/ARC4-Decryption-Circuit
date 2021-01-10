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
`define WAIT	5'b10001
`define STATE0 	5'b10010
`define STATE00 5'b10011
`define BLANK3 	5'b11111

module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);
	
	wire init_rdy, ksa_rdy, p_rdy, sp_wren, ksa_wren, init_wren;
	wire [7:0] init_addr, ksa_addr, init_wrdata, ksa_wrdata, s_q, sp_addr, sp_wrdata;
	
	reg init_en, ksa_en, p_en, s_wren, go, done;
	reg [7:0] s_addr, s_wrdata;
	reg [4:0] curr_state, next_state;
	
	s_mem s(.address(s_addr), .clock(clk), .data(s_wrdata), .wren(s_wren), .q(s_q));
	
    init i(.clk(clk), .rst_n(rst_n), .en(init_en), .rdy(init_rdy), .addr(init_addr), .wrdata(init_wrdata), .wren(init_wren));
	
    ksa k(.clk(clk), .rst_n(rst_n), .en(ksa_en), .rdy(ksa_rdy), .key(key), .addr(ksa_addr), .rddata(s_q), .wrdata(ksa_wrdata), .wren(ksa_wren));
	
    prga p(.clk(clk), .rst_n(rst_n), .en(p_en), .rdy(p_rdy), .key(key), 
		   .s_addr(sp_addr), .s_rddata(s_q), .s_wrdata(sp_wrdata), .s_wren(sp_wren), 
		   .ct_addr(ct_addr), .ct_rddata(ct_rddata), 
		   .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren));
		   
	always_ff @ (posedge clk, negedge rst_n) begin 
		if (~rst_n) 	curr_state = `RESET;
		else 			curr_state = next_state;
	end
	
	always_comb begin 
		case(curr_state)
			`RESET:		next_state = (en) ? `STATE0 : `RESET;
			`STATE0: 	next_state = `BLANK3;
			`BLANK3: 	next_state = (~init_rdy) ? `STATE1 : `BLANK3;
			`STATE1: 	next_state = (init_rdy && ~init_en) ? `STATE2 : `STATE1;
			`STATE2: 	next_state = `STATE00;
			`STATE00: 	next_state = (~ksa_rdy) ? `STATE3 : `STATE00;
			`STATE3: 	next_state = (ksa_rdy && ~ksa_en) 	? `STATE4 : `STATE3;
			`STATE4: 	next_state = `BLANK2;
			`BLANK2: 	next_state = (~p_rdy) ? `STATE5 : `BLANK2;
			`STATE5: 	next_state = (p_rdy && ~p_en) 		? `RESET   : `STATE5;
			//`WAIT: 		next_state = en ? `REPEAT : `WAIT;
			//`REPEAT: 	next_state = `STATE1;
			default: 	next_state = 4'bxxx;
		endcase
	end
	
	always_comb begin 
		case(curr_state)
			`RESET:		begin init_en = 0;			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = init_wren; 	s_wrdata = init_wrdata; rdy = 1; done = 0; end
			`STATE0:	begin init_en = 1;			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = init_wren; 	s_wrdata = init_wrdata; rdy = 1; done = 0; end
			`BLANK3:	begin init_en = 0;			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = init_wren; 	s_wrdata = init_wrdata; rdy = 0; done = 0; end
			`STATE1:	begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = init_wren; 	s_wrdata = init_wrdata; rdy = 0; done = 0; end
			`STATE2:	begin init_en = 0; 			ksa_en = 1; p_en = 0; s_addr = ksa_addr;	s_wren = ksa_wren; 		s_wrdata = ksa_wrdata; 	rdy = 0; done = 0; end
			`STATE00:	begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = ksa_addr;	s_wren = ksa_wren; 		s_wrdata = ksa_wrdata; 	rdy = 0; done = 0; end
			`STATE3: 	begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = ksa_addr; 	s_wren = ksa_wren;		s_wrdata = ksa_wrdata; 	rdy = 0; done = 0; end
			`STATE4: 	begin init_en = 0; 			ksa_en = 0; p_en = 1; s_addr = sp_addr; 	s_wren = sp_wren; 		s_wrdata = sp_wrdata; 	rdy = 0; done = 0; end
			`BLANK2: 	begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = sp_addr; 	s_wren = sp_wren; 		s_wrdata = sp_wrdata; 	rdy = 0; done = 0; end
			`STATE5: 	begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = sp_addr; 	s_wren = sp_wren; 		s_wrdata = sp_wrdata; 	rdy = 0; done = 0; end
			//`WAIT:		begin init_en = 0; 			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = 1'b0; 			s_wrdata = init_wrdata; rdy = 1; done = 1; end
			//`REPEAT: 	begin init_en = 1;			ksa_en = 0; p_en = 0; s_addr = init_addr; 	s_wren = init_wren; 	s_wrdata = init_wrdata; rdy = 1; done = 0; end
			default: 	begin init_en = 1'bx; ksa_en = 1'bx; p_en = 1'bx; s_addr = 8'bxxxxxxxx; s_wren = 1'bx; 	s_wrdata = 8'bx; rdy = 1'bx; done = 1'bx; end
		endcase
	end
			
endmodule: arc4
