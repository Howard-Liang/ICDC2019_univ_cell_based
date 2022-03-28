
`timescale 1ns/10ps

module  CONV(
	input		  clk,
	input		  reset,
	output		  busy,	
	input		  ready,	
			
	output [11:0] iaddr,
	input  [19:0] idata,	
	
	output	 	  cwr,
	output [11:0] caddr_wr,
	output [19:0] cdata_wr,
	
	output	 	  crd,
	output [11:0] caddr_rd,
	input  [19:0] cdata_rd,
	
	output [ 2:0] csel
	);


parameter S_IDLE = 0;
parameter S_LAY0 = 1;
parameter S_LAY1 = 2;

reg [ 1:0] state_w, state_r;
reg [ 0:0] busy_w, busy_r;

assign busy = busy_r;

wire L0_start;
assign L0_start = (state_r == S_LAY0);
wire L0_finish;
wire [11:0] L0_iaddr;
assign iaddr = L0_iaddr;

wire L0_cwr;
wire [12:0] L0_caddr_wr;
wire [19:0] L0_cdata_wr;
// assign cwr = (state_r == S_LAY0) ? L0_cwr : L1_cwr;
// assign caddr_wr = (state_r == S_LAY0) ? L0_caddr_wr : L1_caddr_wr;
// assign cdata_wr = (state_r == S_LAY0) ? L0_cdata_wr : L1_cdata_wr;

wire L1_start;
assign L1_start = (state_r == S_LAY1);
wire L1_finish;

wire L1_cwr;
wire [11:0] L1_caddr_wr;
wire [19:0] L1_cdata_wr;
wire L1_crd;
wire [11:0] L1_caddr_rd;
assign crd = L1_crd;
assign caddr_rd = L1_caddr_rd;

assign cwr = (state_r == S_LAY0) ? L0_cwr : L1_cwr;
assign caddr_wr = (state_r == S_LAY0) ? L0_caddr_wr : L1_caddr_wr;
assign cdata_wr = (state_r == S_LAY0) ? L0_cdata_wr : L1_cdata_wr;

wire [2:0] L1_csel;
assign csel = L1_csel;

// ------------------------------------------
always @(*) begin
	case(state_r)
	S_IDLE: begin
		state_w = (ready) ? S_LAY0 : S_IDLE;
		busy_w = (ready) ? 1 : 0;
	end
	S_LAY0: begin
		state_w = (L0_finish) ? S_LAY1 : S_LAY0;
		busy_w = 1;
	end
	S_LAY1: begin
		state_w = (L1_finish) ? S_IDLE : S_LAY1;
		busy_w = (L1_finish) ? 0 : 1;
	end
	default: begin
		state_w = S_IDLE;
		busy_w = 0;
	end
	endcase
end

convolution L0 (
	.clk(clk),
	.reset(reset),
	.start(L0_start),
	.finish(L0_finish),
	.iaddr(L0_iaddr),
	.idata(idata),
	.cwr(L0_cwr),
	.caddr_wr(L0_caddr_wr),
	.cdata_wr(L0_cdata_wr)
);

L1 L1 (
	.L1_start(L1_start),
	.L1_finished(L1_finish),
	.clk(clk),
	.reset(reset),			
	.cwr(L1_cwr),
	.caddr_wr(L1_caddr_wr),
	.cdata_wr(L1_cdata_wr),
	.crd(L1_crd),
	.caddr_rd(L1_caddr_rd),
	.cdata_rd(cdata_rd),
	.csel(L1_csel)
);

// ------------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) begin
		state_r <= S_IDLE;
		busy_r <= 0;
    end
    else begin
        state_r <= state_w;
		busy_r <= busy_w;
    end
end

endmodule




