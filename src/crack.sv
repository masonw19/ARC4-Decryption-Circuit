`define RESET 	5'b00000
`define STATE1	5'b00001
`define STATE2	5'b00010
`define STATE3	5'b00011
`define STATE4	5'b00100
`define STATE5	5'b00101
`define STATE6	5'b00110
`define STATE7 	5'b00111
`define STATE8 	5'b01000
`define STATE9 	5'b01001
`define WRONG	5'b10100
`define FOUND 	5'b10101
`define DONE 	5'b01111
`define STATE0 	5'b10010
`define BLANK 	5'b01111
`define STATE00 5'b10011
`define BLANK2 	5'b10000

module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata
			 /* any other ports you need to add */
			 , output logic [7:0] final_wrdata, input logic mem_en, output logic checked, 
			output logic final_wren, output logic [7:0] final_addr, input logic [27:0] initKey, input logic found, input logic resume);
	
	
    reg [4:0] curr_state, next_state;
	reg pt_wren, check_en, check_rdy, arc_en, arc_rdy;
	reg [7:0] pt_addr, pt_wrdata;
	reg [27:0] myKey;
	
	wire [7:0] check_addr, pt_rddata, arc_pt_addr, arc_pt_wrdata, fill_addr;
	wire valid, check_wren, arc_pt_wren;
	wire [27:0] noKey;
	
	reg set_valid, set_key, fill_en;
	
    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(pt_addr), .clock(clk), .data(pt_wrdata), .wren(pt_wren), .q(pt_rddata));
	
    arc4 a4(.clk(clk), .rst_n(rst_n), .en(arc_en), .rdy(arc_rdy), .key(myKey[23:0]), .ct_addr(ct_addr), .ct_rddata(ct_rddata), 
			.pt_addr(arc_pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(arc_pt_wrdata), .pt_wren(arc_pt_wren));

	check ch(.addr(check_addr), .clk(clk), .rst_n(rst_n), .wren(check_wren), .rddata(pt_rddata), .key_valid(valid), .rdy(check_rdy), .en(check_en), .checked(checked)); //this was not part of the skeleton
	
	fill_mem fm(.clk(clk), .rst_n(rst_n), .en(fill_en), .pt_wren(fill_wren), .fill_wren(final_wren), .write_to_addr(final_addr), 
				.fill_wrdata(final_wrdata), .pt_rddata(pt_rddata), .read_from_addr(fill_addr), .rdy(fill_rdy)); //this was not in the skeleton
    
	
//------------------datapath-----------------------------------//

	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 			key_valid = 0; 
		else if(en) 		key_valid = 0; 
		else if(set_valid)	key_valid = valid; 
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 			begin key = initKey[23:0]; 	myKey = initKey;   end 
		else if (en) 		begin key = initKey[23:0]; 	myKey = initKey;   end
		else if (set_key) 	begin key = key + 2;		myKey = myKey + 2; end
	end
	
	assign noKey = (myKey > 28'h0FFFFFF);
//------------------statemachine-------------------------------//
	
	always_ff @(posedge clk, negedge rst_n) begin 
		if(~rst_n) 		curr_state = `RESET;
		else if(noKey)	curr_state = `RESET;
		else			curr_state = next_state;
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	next_state = en ? `STATE0 : `RESET;
			`STATE0: 	next_state = `STATE00;
			`STATE00: 	next_state = ~arc_rdy ? `STATE1 : `STATE00;
			`STATE1:	next_state = (arc_rdy && ~arc_en) ? `STATE2 : `STATE1;
			`STATE2: 	next_state = `STATE3;
			`STATE3: 	next_state = (resume && ~check_en && check_rdy) ? `STATE4 : `STATE3;
			`STATE4: 	next_state = key_valid ? `FOUND : `STATE5; //going to reset here means that u have a valid key 
			`STATE5: 	next_state = found ? `RESET : `STATE6;
			`STATE6: 	next_state = `STATE7;
			`STATE7: 	next_state = ~arc_rdy ? `STATE7 : `STATE1;
			`FOUND: 	next_state = mem_en ? `STATE8 : `FOUND;
			`STATE8: 	next_state = `STATE9;
			`STATE9: 	next_state = (fill_rdy && ~fill_en) ? `RESET : `STATE9;			
			default: 	next_state = 5'bx; 
		endcase
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 1; set_key = 0; end //reset state. rdy = 1
			`STATE0: 	begin arc_en = 1; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 1; set_key = 0; end //set arc en and rdy
			`STATE00: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //arc en is low, so is rdy, let arc run
			`STATE1: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //arc en is low, so is rdy, let arc run
			`STATE2: 	begin arc_en = 0; check_en = 1; fill_en = 0; set_valid = 0; pt_addr = check_addr;  pt_wrdata = 8'b0; 		  pt_wren = check_wren;  rdy = 0; set_key = 0; end //set check en
			`STATE3: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 1; pt_addr = check_addr;  pt_wrdata = 8'b0; 		  pt_wren = check_wren;  rdy = 0; set_key = 0; end //let check run and make key_valid = valid
			`STATE4: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //have a state transition to check key_valid ... blank state basically
			`STATE5: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 1; end //incrememnt key
			`STATE6: 	begin arc_en = 1; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //set arc enable 	
			`STATE7: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //arc en is low, so is rdy, let arc run
			`FOUND: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = arc_pt_addr; pt_wrdata = arc_pt_wrdata; pt_wren = arc_pt_wren; rdy = 0; set_key = 0; end //this state waits for mem to be ready to be copied
			`STATE8: 	begin arc_en = 0; check_en = 0; fill_en = 1; set_valid = 0; pt_addr = fill_addr;   pt_wrdata = 8'b0; 		  pt_wren = fill_wren; 	 rdy = 0; set_key = 0; end //set fill_en = 1
			`STATE9: 	begin arc_en = 0; check_en = 0; fill_en = 0; set_valid = 0; pt_addr = fill_addr;   pt_wrdata = 8'b0; 		  pt_wren = fill_wren; 	 rdy = 0; set_key = 0; end //copy into the pt		
			default: 	begin arc_en = 1'bx; check_en = 1'bx; set_valid = 1'bx; pt_addr = 8'bx; pt_wrdata = 8'bx; pt_wren = 1'bx; rdy = 1'bx; set_key = 1'bx; end
		endcase
	end
	
endmodule: crack

module check(input logic clk, input logic [7:0] rddata, input logic rst_n, output logic rdy, input en,
			   output logic wren, output logic [7:0] addr, output logic key_valid, output logic checked);

	reg [4:0] curr_state, next_state;
	reg [8:0] i;
	reg [7:0] val;
	reg [7:0] size;
	
	reg set_ia, set_size, set_val, set_checked;
	
	wire done;
	
	
//-----------------------datapath-----------------------------------//
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		begin 	i = 0; addr = 0; end
		else if(en) 	begin 	i = 0; addr = 0; end
		else if(set_ia) begin i = i + 1; addr = addr + 1; end
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n)  		size = 255;
		else if(en)  		size = 255;
		else if(set_size) 	size = rddata;
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n)  		val = 8'b0;
		else if(en)  		val = 8'b0;
		else if (set_val) 	val = rddata;
	end
	
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 			 checked = 0;  
		else if(en) 		 checked = 0;
		else if(set_checked) checked = 1; 
	end
		
	
	assign done = (i > size);
	assign wren = 0; 
	
//-----------------------statemachine-------------------------------//
	//state transistion
	always_ff @ (posedge clk, negedge rst_n) begin 
		if(~rst_n) 		 	curr_state = `RESET;
		else if (done) 		curr_state = `DONE;
		else 				curr_state = next_state;
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	next_state = en ? `STATE0 : `RESET;
			`STATE0: 	next_state = `STATE1;
			`STATE1: 	next_state = `STATE2;
			`STATE2: 	next_state = `STATE3;
			`STATE3: 	next_state = `STATE4;
			`STATE4: 	next_state = (val >= 8'h20 && val <= 8'h7E) ? `STATE1 : `WRONG; //8'h7E = 126, 8'h20 = 32
			`WRONG:		next_state = `RESET;
			`DONE: 		next_state = `RESET;
			default: 	next_state = 5'bx;
		endcase
	end
	
	always_comb begin 
		case(curr_state)
			`RESET: 	begin set_ia = 0; set_size = 0; set_val = 0; key_valid = 1'b0; rdy = 1; set_checked = 0; end //request size
			`STATE0: 	begin set_ia = 0; set_size = 0; set_val = 0; key_valid = 1'b0; rdy = 0; set_checked = 0; end //blank
			`STATE1: 	begin set_ia = 1; set_size = 1; set_val = 0; key_valid = 1'b0; rdy = 0; set_checked = 0; end //have size, set size
			
			`STATE2: 	begin set_ia = 0; set_size = 0; set_val = 0; key_valid = 1'b0; rdy = 0; set_checked = 0; end // request pt[i]
			`STATE3: 	begin set_ia = 0; set_size = 0; set_val = 1; key_valid = 1'b0; rdy = 0; set_checked = 0; end // blank
			`STATE4: 	begin set_ia = 1; set_size = 0; set_val = 0; key_valid = 1'b0; rdy = 0; set_checked = 0; end //increment the i and address and set value
			
			`WRONG: 	begin set_ia = 0; set_size = 0; set_val = 0; key_valid = 1'b0; rdy = 1; set_checked = 1; end //key is wrong. we are finished  so set rdy
			`DONE: 		begin set_ia = 0; set_size = 0; set_val = 0; key_valid = 1'b1; rdy = 1; set_checked = 1; end //key is right. we are finished so set rdy
			default: 	begin set_ia = 1'bx; set_size = 1'bx; set_val = 1'bx; key_valid = 1'bx; rdy = 1'bx; set_checked = 1'bx; end
		endcase
	end
	

endmodule: check


