

`timescale 1ns/10ps

module  convolution(
	input		clk,
	input		reset,	
    input       start,
    output      finish,
			
	output		[11:0]iaddr,
	input signed[19:0]idata,	
	
	output	 	cwr,
	output	signed 	[12:0]caddr_wr,
	output	 	[19:0]cdata_wr
	);
    //wire reg
        reg [3:0]addr;
        reg signed [6:0] basex_r,basex_w;
        reg signed [6:0] basey_r,basey_w;
        reg signed [1:0] base_add_x;
        reg signed [1:0] base_add_y;
        reg [3:0]add_r,add_w;
        reg state_r;
        wire signed [12:0] y_ex;
        wire signed [12:0]address;
        reg  addr_valid_r,addr_valid_w;
        reg signed [8:0]x,y;
        reg signed [19:0]mul_r,mul_w;
        reg signed [45:0]acum_r,acum_w;
        reg signed[12:0]w_count_r,w_count_w;
        wire signed[19:0]answer;
        wire signed[29:0]shift_ans;
        wire signed[19:0]in;
    //assign
        assign in=idata;
        assign answer=$signed(shift_ans[20:0])+acum_r[15];
        assign finish=((caddr_wr==4095)&&(cwr==1))?1:0;
        assign cwr=(add_r==0)?1:0;
        assign shift_ans=acum_r>>>16;
        assign caddr_wr=w_count_r;
        assign cdata_wr=((add_r==0)&&(shift_ans[29]==0))?answer:0;
        assign iaddr=address[11:0];
        assign address=x+y_ex;
        assign y_ex={y,6'b0};
     
    //acum_w
        always @(*) begin
            if(add_r==0)begin
                acum_w=$signed(mul_w)*$signed(in)+$signed(36'h013100000);
            end
            else begin
                acum_w=acum_r+mul_w*in;
            end
        end
    //x y w_count_w 
        always @(*) begin
            x=basex_r+base_add_x;
            y=basey_r+base_add_y;
            w_count_w=(add_r==1)?w_count_r+1:w_count_r;
        end
    //addr_valid
        always @(*) begin
            if((x>=0)&&(x<=63)&&(y>=0)&&(y<=63))begin
                addr_valid_w=1;
            end
            else begin
                addr_valid_w=0;
            end
        end
    //base_add_x base_add_y mul_w
        always @(*)begin
            case(add_r)
            0:begin
                base_add_x=-1;
                base_add_y=-1;
                mul_w=(addr_valid_w)?20'h0A89E:0;
            end
            1:begin
                base_add_x=0;
                base_add_y=-1;
                mul_w=(addr_valid_w)?20'h092D5:0;
            end
            2:begin
                base_add_x=1;
                base_add_y=-1;
                mul_w=(addr_valid_w)?20'h06D43:0;
            end
            3:begin
                base_add_x=-1;
                base_add_y=0;
                mul_w=(addr_valid_w)?20'h01004:0;
            end
            4:begin
                base_add_x=0;
                base_add_y=0;
                mul_w=(addr_valid_w)?20'hF8F71:0;
            end
            5:begin
                base_add_x=1;
                base_add_y=0;
                mul_w=(addr_valid_w)?20'hF6E54:0;
            end
            6:begin
                base_add_x=-1;
                base_add_y=1;
                mul_w=(addr_valid_w)?20'hFA6D7:0;
            end
            7:begin
                base_add_x=0;
                base_add_y=1;
                mul_w=(addr_valid_w)?20'hFC834:0;
            end
            8:begin
                base_add_x=1;
                base_add_y=1;
                mul_w=(addr_valid_w)?20'hFAC19:0;
            end
            default: begin
                base_add_x=0;
                base_add_y=0;
                mul_w=(addr_valid_w)?20'hFAC19:0;
            end
            endcase
        end
    //add_w
        always @(*) begin
            if(state_r)begin
                add_w=(add_r==8)?0:add_r+1;
            end
            else begin
                add_w=add_r;
            end
        end
    //basex_w basey_w
        always @(*) begin
            if(add_r==8)begin
                basex_w=(basex_r==63)?0:basex_r+1;
                basey_w=(basex_r==63)?basey_r+1:basey_r;
            end
            else begin
                basex_w=basex_r;
                basey_w=basey_r;
            end
        end
    always @(posedge clk or posedge reset) begin
        if(reset)begin
            basex_r<=0;
            basey_r<=0;
            state_r<=0;
            mul_r<=0;
            acum_r<=0;
            w_count_r<=-1;
            addr_valid_r<=0;
            add_r<=0;
        end
        else begin
            acum_r<=acum_w;
            mul_r<=mul_w;
            basex_r<=basex_w;
            basey_r<=basey_w;
            state_r<=(start)?1:0;
            add_r<=add_w;
            w_count_r<=w_count_w;
            addr_valid_r<=addr_valid_w;
        end
    end

endmodule