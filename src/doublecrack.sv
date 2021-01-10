`define RESET 	5'b00000
`define STATE1 	5'b00001
`define STATE2 	5'b00010
`define STATE3 	5'b00011
`define STATE4 	5'b00100
`define STATE5 	5'b00101
`define FOUND 	5'b01110
`define DONE 	5'b01111
`define STATE0 	5'b10010
`define STATE00 5'b10011

module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

    // your code here
    reg [4:0] curr_state, next_state;
	reg c1_en, c2_en, mem_en, pt_wren, found;
	reg [7:0] pt_wrdata, pt_addr;
	reg [23:0] key1, key2;
	
	reg fake_valid, set_fake_valid, set_valid, set_found;
	
	wire [7:0] final_wrdata2, final_wrdata1, final_addr1, final_addr2, ct_addr2, pt_rddata;
	wire resume, checked1, checked2;
	wire [27:0] initKey1, initKey2;
	
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));

    // for this task only, you may ADD ports to crack
    crack c1(.clk(clk), .rst_n(rst_n), .en(c1_en), .rdy(c1_rdy), .key(key1), .key_valid(c1_key_valid), .ct_addr(ct_addr), .ct_rddata(ct_rddata), .resume(resume), 
			 .initKey(initKey1), .final_wrdata(final_wrdata1), .final_wren(final_wren1), .final_addr(final_addr1), .mem_en(mem_en), .found(found), .checked(checked1));
	
    crack c2(.clk(clk), .rst_n(rst_n), .en(c2_en), .rdy(c2_rdy), .key(key2), .key_valid(c2_key_valid), .ct_addr(ct_addr2), .ct_rddata(ct_rddata), .resume(resume),
			 .initKey(initKey2), .final_wrdata(final_wrdata2), .final_wren(final_wren2), .final_addr(final_addr2), .mem_en(mem_en), .found(found), .checked(checked2));
    
   
//--------------------datapath--------------------------//
	always_ff @(posedge clk, negedge rst_n) begin
		if(~rst_n) 				fake_valid = 0;
		else if(en) 			fake_valid = 0; 
		else if(set_fake_valid)	fake_valid = (c1_key_valid || c2_key_valid) ? 1 : 0;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin 
		if(~rst_n) 			key_valid = 0; 
		else if(en) 		key_valid = 0; 
		else if(set_valid) 	key_valid = fake_valid; 	
	end
	
	always_ff @(posedge clk, negedge rst_n) begin 
		if(~rst_n) 			found = 0; 
		else if(en) 		found = 0;
		else if(set_found) 	found = 1; 	
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(~rst_n) 				key = 24'b0;
		else if(en) 			key = 24'b0;
		else if(c1_key_valid)	key = key1; 
		else if(c2_key_valid) 	key = key2; 	
	end
	
	always_ff @(posedge clk, negedge rst_n) begin 
		if(~rst_n) 				begin pt_wrdata = 8'b0; pt_addr = 8'b0; end
		else if(en) 			begin pt_wrdata = 8'b0; pt_addr = 8'b0; end
		else if(c1_key_valid) 	begin pt_wrdata = final_wrdata1; pt_addr = final_addr1; end
		else if(c2_key_valid) 	begin pt_wrdata = final_wrdata2; pt_addr = final_addr2; end		
	end
	
	assign initKey1 = 28'd1; 
	assign initKey2 = 28'd0; 
	assign resume = (checked1 && checked2);
	
//------------------statemachine------------------------//
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		curr_state = `RESET;
		else			curr_state = next_state;
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	next_state = en ? `STATE0 : `RESET;
			`STATE0: 	next_state = `STATE00; 
			`STATE00: 	next_state = (~c2_rdy && ~c1_rdy) ? `STATE1 : `STATE00;
			`STATE1: 	next_state =  ( ((c1_rdy && ~c1_en ) && (c2_rdy && ~c2_en)) || fake_valid) ? `STATE2 : `STATE1;
			`STATE2: 	next_state = fake_valid ? `FOUND : `RESET;
			`FOUND: 	next_state = c1_key_valid ? `STATE3 : `STATE4;
			
			`STATE3: 	next_state = (c1_rdy && ~c1_en) ? `STATE5 : `STATE3;
			`STATE4: 	next_state = (c2_rdy && ~c2_en) ? `STATE5 : `STATE4;
			`STATE5: 	next_state = `RESET; 
			default: 	next_state = 5'bx;
		endcase
	
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = 0; rdy = 1; end
			`STATE0: 	begin c1_en = 1; c2_en = 1; mem_en = 0; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = 0; rdy = 1; end 	//set the cracks to start
			`STATE00: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = 0; rdy = 0; end 	//blank state
			`STATE1: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 1; set_valid = 0; set_found = 0; pt_wren = 0; rdy = 0; end		//let the cracks run
			`STATE2: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = 0; rdy = 0; end		//this state will check if we found a key
			`FOUND: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 0; set_valid = 0; set_found = 1; pt_wren = 0; rdy = 0; end		//this state will pick which crack has valid key
			
			`STATE3:	begin c1_en = 0; c2_en = 0; mem_en = 1; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = final_wren1; rdy = 0; end	//this state will save the memory in crack1
			`STATE4:	begin c1_en = 0; c2_en = 0; mem_en = 1; set_fake_valid = 0; set_valid = 0; set_found = 0; pt_wren = final_wren2; rdy = 0; end	//this state will save the memory in crack2
			`STATE5: 	begin c1_en = 0; c2_en = 0; mem_en = 0; set_fake_valid = 0; set_valid = 1; set_found = 0; pt_wren = 0; 			 rdy = 0; end	//this state sets the final key
			default: 	begin c1_en = 1'bx; c2_en = 1'bx; mem_en = 1'bx; set_fake_valid = 1'bx; set_valid = 1'bx; set_found = 1'bx; pt_wren = 1'bx; rdy = 1'bx; end
		endcase
	end
	
endmodule: doublecrack

