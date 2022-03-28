
`timescale 1ns/10ps

module  L1(
	input		  L1_start,  // FSM starts L1
	output		  L1_finished,  // indicate L1 finished

	input		  clk,
	input		  reset,			
	
	output	 	  cwr,
	output [11:0] caddr_wr,
	output [19:0] cdata_wr,
	
	output	 	  crd,
	output [11:0] caddr_rd,
	input signed [19:0] cdata_rd,

	output [ 2:0] csel
	);


// ---------------------------------------
localparam S_IDLE  = 0;
localparam S_READ  = 1;
localparam S_WRITE = 2;

reg 	   [ 1:0] L1_state_w, L1_state_r;
reg signed [19:0] peak_w, peak_r;
reg 	   [11:0] counter_w, counter_r;
reg 	   [ 0:0] L1_finished_w, L1_finished_r;

assign L1_finished = L1_finished_r;

assign cwr = (L1_state_r == S_WRITE); 
assign caddr_wr = (counter_r == 0) ? 10'd1023 : counter_r[11:2] - 1;
assign cdata_wr = peak_r;

assign crd = (L1_state_r == S_READ);
assign caddr_rd = {counter_r[11:7], counter_r[1:1], counter_r[6:2], counter_r[0:0]};

assign csel = (L1_state_r == S_WRITE) ? 3'd3 : 3'd1;

// ---------------------------------------
always @(*) begin
	case(L1_state_r)
	S_IDLE: begin
		L1_state_w = (L1_start) ? S_READ : S_IDLE;
		counter_w = counter_r;
		L1_finished_w = 0;
		peak_w = -524288;
	end
	S_READ: begin
		L1_state_w = (counter_r[1:0] == 2'd3) ? S_WRITE : S_READ;
		counter_w = counter_r + 1;
		L1_finished_w = 0;
		peak_w = (peak_r > cdata_rd) ? peak_r : cdata_rd;
	end
	S_WRITE: begin
		L1_state_w = (counter_r == 12'd0) ? S_IDLE : S_READ;
		counter_w = counter_r;
		L1_finished_w = (counter_r == 12'd0) ? 1 : 0;
		peak_w = -524288;
	end
	default: begin
		L1_state_w = S_IDLE;
		counter_w = counter_r;
		L1_finished_w = 0;
		peak_w = -524288;
	end
	endcase
end

// ---------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
		L1_state_r <= S_IDLE;
		counter_r <= 0;
		L1_finished_r <= 0;
		peak_r <= -524288;  // the minimum
    end
    else begin
        L1_state_r <= L1_state_w;
		counter_r <= counter_w;
		L1_finished_r <= L1_finished_w;
		peak_r <= peak_w;
    end
end


endmodule