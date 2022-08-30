module EthFsm(
	input Clk,
	output reg [9:0] LanAddr,
	inout [15:0] LanData,
	input  [3:0] LanBrdy,
	output reg LanCs,
	output reg LanRd,
	output reg LanWr,
	output reg LanRst,
	input  LanIrq,
	//input  LAN_PWR
	/* Debug */
	input BTN1n,
	input BTN2n,
	output reg [7:0] LED
);

localparam RESET    = 4'd00;
localparam SET_LAN  = 4'd01;
localparam SET_HAR1 = 4'd02;
localparam SET_HAR2 = 4'd03;
localparam SET_SM1  = 4'd04;
localparam SET_SM2  = 4'd05;
localparam SET_IP1  = 4'd06;
localparam SET_IP2  = 4'd07;

localparam GET_IDR1 = 4'd08;
localparam GET_IDR2 = 4'd09;

reg [32:0] Counter;
reg  [3:0] State;

/* Debug: */
reg [2:0] BTN_STATE;  always @(posedge Clk) BTN_STATE <= {BTN_STATE[1:0], BTN1n};
wire BTN_FALLING = (BTN_STATE[2:1]==2'b10);

reg Dir;	
reg [15:0] DataOut;
assign LanData = (Dir == 1'h1) ? 16'hz : DataOut;

initial 
begin
	Counter <= 32'h0;
	State   <= RESET;
	LanCs   <= 1'h1;
	LanRd   <= 1'h1;
	LanWr   <= 1'h1;
	LanRst  <= 1'h1;
	/* Data I/O: */
	Dir <= 1'h1;
	DataOut <= 16'h0;
	/* Debug: */
	LED <= 8'b0;
end

always @(posedge Clk)
begin
	
	if (BTN_FALLING)
		State <= RESET;

	case (State)
	
		RESET :
		begin
			LanCs   <= 1'h1;
			LanRd   <= 1'h1;
			LanWr   <= 1'h1;
			Counter <= Counter + 32'h1;
			if (Counter < 32'hf4240)
				LanRst <= 1'h1;
			else if ((Counter >= 32'hf4240) && (Counter < 32'hf4434))
				LanRst <= 1'h0;
			else if ((Counter >= 32'hf4434) && (Counter < 32'h1e8674))
				LanRst <= 1'h1;
			else
				State <= SET_LAN;
		end
		
		SET_LAN :
		begin
			Counter <= 32'h0;
			LanRst  <= 1'h1;
			Dir     <= 1'b0;
			State   <= GET_IDR1;
		end
		
		
		GET_IDR1 :
		begin
			LanWr   <= 1'h1;
			Dir     <= 1'b1;
			Counter <= Counter + 32'h1;
			if (Counter < 32'h5)
			begin
				LanRd <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'h5) && (Counter < 32'hA))
			begin
				LanAddr <= 10'hFE;
				LanRd <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'hA) && (Counter < 32'hF))
			begin
				LanRd <= 1'h1;
				LanCs <= 1'h1; 
			end
			else
				State <= GET_IDR2;
		end
		
		GET_IDR2 :
		begin
			LED <= LanData[15:8];
			//LED <= LanData[7:0];
			Counter <= 32'b0;
			State <= SET_HAR1;
			//State <= GET_IDR1;
		end
		
		
		
		
		
		
		
		
		
		
		SET_HAR1 :
		begin
			LanRd   <= 1'h1;
			Dir     <= 1'b0;
			Counter <= Counter + 32'h1;
			if (Counter < 32'h5)
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'h5) && (Counter < 32'hA))
			begin
				LanAddr <= 10'h08;
				DataOut <= 16'hAABB;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'hA) && (Counter < 32'hF))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'hF) && (Counter < 32'h14))
			begin
				LanAddr <= 10'h0A;
				DataOut <= 16'hCCDD;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'h14) && (Counter < 32'h19))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'h19) && (Counter < 32'h1e))
			begin
				LanAddr <= 10'h0C;
				DataOut <= 16'hEEFF;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'h1e) && (Counter < 32'h23))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else
				State <= SET_HAR2;
		end
		
		SET_HAR2 :
		begin
			Counter <= 32'h0;
			State <= SET_SM1;
		end
		
		SET_SM1 :
		begin
			LanRd   <= 1'h1;
			Dir     <= 1'b0;
			Counter <= Counter + 32'h1;
			if (Counter < 32'h5)
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'h5) && (Counter < 32'hA))
			begin
				LanAddr <= 10'h14;
				DataOut <= 16'hffff;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'hA) && (Counter < 32'hF))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'hF) && (Counter < 32'h14))
			begin
				LanAddr <= 10'h16;
				DataOut <= 16'hff00;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'h14) && (Counter < 32'h19))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else
				State <= SET_SM2;
		end
		
		SET_SM2 :
		begin
			Counter <= 32'h0;
			State <= SET_IP1;
		end
		
		SET_IP1 :
		begin
			LanRd   <= 1'h1;
			Dir     <= 1'b0;
			Counter <= Counter + 32'h1;
			if (Counter < 32'h5)
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'h5) && (Counter < 32'hA))
			begin
				LanAddr <= 10'h18;
				DataOut <= 16'hc0a8;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'hA) && (Counter < 32'hF))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else if ((Counter >= 32'hF) && (Counter < 32'h14))
			begin
				LanAddr <= 10'h1A;
				DataOut <= 16'h0b0b;
				LanWr <= 1'h0;
				LanCs <= 1'h0; 
			end
			else if ((Counter >= 32'h14) && (Counter < 32'h19))
			begin
				LanWr <= 1'h1;
				LanCs <= 1'h1; 
			end
			else
				State <= SET_IP2;
		end
		
		SET_IP2 :
		begin
			Counter <= 32'b0;
		end
		
	endcase
	
end

endmodule