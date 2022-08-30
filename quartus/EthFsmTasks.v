module EthFsmTasks(
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
	output [7:0] LED,
	output [7:0] StateOut,
	/* Inputs: */
	input [31:0] LaserRate
);

localparam RESET     = 8'd00;
localparam SET_LAN   = 8'd01;
localparam SET_HAR1  = 8'd02;
localparam SET_HAR2  = 8'd03;
localparam SET_SM1   = 8'd04;
localparam SET_SM2   = 8'd05;
localparam SET_IP1   = 8'd06;
localparam SET_IP2   = 8'd07;

localparam GET_IDR1  = 8'd08;
localparam GET_IDR2  = 8'd09;

localparam SET_PORT1 = 8'd10;
localparam SET_PORT2 = 8'd11;
localparam SET_TCP1  = 8'd12;
localparam SET_TCP2  = 8'd13;
localparam SET_SCK1  = 8'd14;
localparam SET_SCK2  = 8'd15;
localparam SET_SCK3  = 8'd16;
localparam SET_SCK4  = 8'd17;

localparam GET_STATE1  = 8'd18;
localparam GET_STATE2  = 8'd19;

localparam TCP_RCV1    = 8'd20;
localparam TCP_RCV2    = 8'd21;
localparam TCP_RCV3    = 8'd22;
localparam TCP_RCV4    = 8'd23;
localparam TCP_RCV5    = 8'd24;

localparam TCP_RX_FIFO1 = 8'd25;
localparam TCP_RX_FIFO2 = 8'd26;

localparam TCP_RCV3A = 8'd27;
localparam TCP_RCV3B = 8'd28;
localparam TCP_RCV3C = 8'd29;
localparam TCP_RCV3D = 8'd30;
localparam TCP_RCV3E = 8'd31;

localparam ECHO1 = 8'd32;
localparam ECHO2 = 8'd33;

localparam ERROR1 = 8'd34;
localparam ERROR2 = 8'd35;

localparam OK1 = 8'd36;
localparam OK2 = 8'd37;

localparam QUERY0 = 8'd38;
localparam QUERY1 = 8'd39;
localparam QUERY2 = 8'd40;

localparam RATE1 = 8'd41;
localparam RATE2 = 8'd42;

//localparam ERROR = 48'h4552_524f_5221;
localparam ERROR    = 48'h5221_524f_4552;
localparam OK       = 32'h2121_4f4b;
localparam ACQUIRE  = 48'h000A_4143_5120;

reg [32:0] TxCount;
reg [32:0] RxCount;
reg [32:0] RxCountP;
reg [32:0] Counter;
reg  [7:0] State;

wire ONE_BYTE_DONE    = (Counter >= 32'h0F);
wire TWO_BYTES_DONE   = (Counter >= 32'h19);
wire THREE_BYTES_DONE = (Counter >= 32'h23);

localparam SOCK_CLOSED      = 8'h00;
localparam SOCK_INIT        = 8'h13;
localparam SOCK_LISTEN      = 8'h14;
localparam SOCK_ESTABLISHED = 8'h17;
localparam SOCK_CLOSE_WAIT  = 8'h1C;
localparam SOCK_UDP         = 8'h17;
localparam SOCK_IPRAW       = 8'h32;
localparam SOCK_MACRAW      = 8'h42;
localparam SOCK_PPPOE       = 8'h5F;
localparam SOCK_SYNSENT     = 8'h15;
localparam SOCK_SYNRECV     = 8'h16;
localparam SOCK_FINWAIT     = 8'h18;
localparam SOCK_TIME_WAIT   = 8'h1B;
localparam SOCK_LAST_ACK    = 8'h1D;
localparam SOCK_ARP         = 8'h01;

/* SOCKET FSM: */
reg [15:0] SocketState;
reg [15:0] Fifo;
reg [32:0] FreeSize;
reg [79:0] Query;

wire SOCKET_CLOSED      = (SocketState[7:0] == SOCK_CLOSED);
wire SOCKET_INIT        = (SocketState[7:0] == SOCK_INIT);
wire SOCKET_LISTEN      = (SocketState[7:0] == SOCK_LISTEN);
wire SOCKET_ESTABLISHED = (SocketState[7:0] == SOCK_ESTABLISHED);
wire SOCKET_CLOSE_WAIT  = (SocketState[7:0] == SOCK_CLOSE_WAIT);

/* Debug: */
reg [2:0] BTN_STATE;  always @(posedge Clk) BTN_STATE <= {BTN_STATE[1:0], BTN1n};
wire BTN_FALLING = (BTN_STATE[2:1]==2'b10);
assign StateOut = State;

reg Dir;	
reg [15:0] DataOut;
assign LanData = (Dir == 1'h1) ? 16'hz : DataOut;

task JumpToState;
	input [7:0] NextState;
	begin
		Counter <= 32'h0;
		State <= NextState;
	end
endtask

task Write1bRegister;
	input  [9:0] Address;
	input [15:0] Data;
	begin
		LanRd <= 1'h1;
		Dir   <= 1'b0;
		Counter <= Counter + 32'h1;
		if (Counter < 32'h5)
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
		else if ((Counter >= 32'h5) && (Counter < 32'hA))
		begin
			LanAddr <= Address;
			DataOut <= Data;
			LanWr <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'hA) && (Counter < 32'hF))
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
	end
endtask

task Write1bRegisterWrapped;
	input  [9:0] Address;
	input [15:0] RegData;
	input  [7:0] NextState;
	begin
		if (ONE_BYTE_DONE)
			JumpToState(NextState);
		else
			Write1bRegister(Address, RegData);
	end
endtask

task Write2bRegister;
	input [19:0] Address;
	input [31:0] Data;
	begin
		LanRd <= 1'h1;
		Dir   <= 1'b0;
		Counter <= Counter + 32'h1;
		if (Counter < 32'h5)
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
		else if ((Counter >= 32'h5) && (Counter < 32'hA))
		begin
			LanAddr <= Address[19:10];
			DataOut <= Data[31:16];
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
			LanAddr <= Address[9:0];
			DataOut <= Data[15:0];
			LanWr <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'h14) && (Counter < 32'h19))
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
	end
endtask

task Write2bRegisterWrapped;
	input [19:0] Address;
	input [31:0] RegData;
	input  [7:0] NextState;
	begin
		if (TWO_BYTES_DONE)
			JumpToState(NextState);
		else
			Write2bRegister(Address, RegData);
	end
endtask

task Write3bRegister;
	input [29:0] Address;
	input [47:0] Data;
	begin
		LanRd <= 1'h1;
		Dir   <= 1'b0;
		Counter <= Counter + 32'h1;
		if (Counter < 32'h5)
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
		else if ((Counter >= 32'h5) && (Counter < 32'hA))
		begin
			LanAddr <= Address[29:20];
			DataOut <= Data[47:32];
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
			LanAddr <= Address[19:10];
			DataOut <= Data[31:16];
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
			LanAddr <= Address[9:0];
			DataOut <= Data[15:0];
			LanWr <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'h1e) && (Counter < 32'h23))
		begin
			LanWr <= 1'h1;
			LanCs <= 1'h1; 
		end
	end
endtask

task Write3bRegisterWrapped;
	input [29:0] Address;
	input [47:0] RegData;
	input  [7:0] NextState;
	begin
		if (THREE_BYTES_DONE)
			JumpToState(NextState);
		else
			Write3bRegister(Address, RegData);
	end
endtask

task Read1bRegister;
	input  reg  [9:0] Address;
	//output reg [15:0] RegData;
	begin
		LanWr <= 1'h1;
		Dir   <= 1'b1;
		Counter <= Counter + 32'h1;
		if (Counter < 32'h5)
		begin
			LanRd <= 1'h1;
			LanCs <= 1'h1; 
		end
		else if ((Counter >= 32'h5) && (Counter < 32'hA))
		begin
			LanAddr <= Address;
			LanRd <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'hA) && (Counter < 32'hF))
		begin
			LanRd <= 1'h1;
			LanCs <= 1'h1; 
			//RegData <= LanData;
		end
		/* Additional clause? */
	end
endtask

task Read1bRegisterWrapped;
	input  reg  [9:0] Address;
	output reg [15:0] RegData;
	input  reg  [7:0] NextState;
	begin
		RegData <= LanData; // Not sure why this is necessary...
		if (ONE_BYTE_DONE)
			JumpToState(NextState);
		else
			Read1bRegister(Address);
	end
endtask

reg [31:0] RegData2b;
task Read2bRegister;
	input  reg [19:0] Address;
	//output reg [31:0] RegData;
	begin
		LanWr <= 1'h1;
		Dir   <= 1'b1;
		Counter <= Counter + 32'h1;
		if (Counter < 32'h5)
		begin
			LanRd <= 1'h1;
			LanCs <= 1'h1; 
		end
		else if ((Counter >= 32'h5) && (Counter < 32'hA))
		begin
			LanAddr <= Address[19:10];
			LanRd <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'hA) && (Counter < 32'hF))
		begin
			LanRd <= 1'h1;
			LanCs <= 1'h1; 
			//RegData[31:16] <= LanData;
			RegData2b[31:16] <= LanData;
		end
		else if ((Counter >= 32'hf) && (Counter < 32'h14))
		begin
			LanAddr <= Address[9:0];
			LanRd <= 1'h0;
			LanCs <= 1'h0; 
		end
		else if ((Counter >= 32'h14) && (Counter < 32'h19))
		begin
			LanRd <= 1'h1;
			LanCs <= 1'h1; 
			//RegData[15:0] <= LanData;
			RegData2b[15:0] <= LanData;
		end
	/* Additional clause? */
	end
endtask

task Read2bRegisterWrapped;
	input  [19:0] Address;
	output [31:0] RegData;
	input   [7:0] NextState;
	begin
		RegData <= RegData2b;	// Not sure why this is necessary...
		if (TWO_BYTES_DONE)
			JumpToState(NextState);
		else
			Read2bRegister(Address);
	end
endtask

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
	/* FIFO: */
	Fifo <= 16'h0;
	FreeSize  <= 32'h0;
	/* SOCKET: */
	SocketState <= 16'h0;
	TxCount <= 32'h0;
	RxCount <= 32'h0;
	/* Debug: */
	LedReg <= 8'h0;
end

reg [7:0] LedReg;
assign LED = BTN2n ? SocketState[7:0] : State;

always @(posedge Clk)
begin
	
	if (BTN_FALLING)
		State <= RESET;

	case (State)
	
		/* LAN reset: */
		RESET :
		begin
			LanCs <= 1'h1;
			LanRd <= 1'h1;
			LanWr <= 1'h1;
			Counter <= Counter + 32'h1;
			if (Counter < 32'hf4240)
			//if (Counter < 32'h40)
				LanRst <= 1'h1;
			else if ((Counter >= 32'hf4240) && (Counter < 32'hf4434))
			//else if ((Counter >= 32'h40) && (Counter < 32'h50))
				LanRst <= 1'h0;
			else if ((Counter >= 32'hf4434) && (Counter < 32'h1e8674))
			//else if ((Counter >= 32'h50) && (Counter < 32'h60))
				LanRst <= 1'h1;
			else
				State <= SET_LAN;
		end
		
		SET_LAN :
		begin
			Counter <= 32'h0;
			LanRst  <= 1'h1;
			Dir     <= 1'b0;
			//State   <= GET_IDR1;
			State   <= SET_HAR1;
		end
		
		/*GET_IDR1 :
		begin
			Read1bRegisterWrapped(10'h0FE, SocketState, SET_HAR1);
		end*/
		
		SET_HAR1 :
		begin
			Write3bRegisterWrapped({10'h8,10'ha,10'hc}, 48'haabbccddeeff, SET_SM1);
		end
		
		SET_SM1 :
		begin
			Write2bRegisterWrapped({10'h14, 10'h16}, 32'hffffff00, SET_IP1);
		end
		
		SET_IP1 :
		begin
			Write2bRegisterWrapped({10'h18, 10'h1A}, 32'hc0a80b0b, SET_PORT1);
		end		
		
		SET_PORT1 :
		begin
			Write1bRegisterWrapped(10'h20A, 16'd80, SET_TCP1);
		end
		
		SET_TCP1 :
		begin
			Write1bRegisterWrapped(10'h200, 16'h1, SET_SCK1); /* MR TCP */
		end
		
		SET_SCK1 :
		begin
			Write1bRegisterWrapped(10'h202, 16'h01, SET_SCK3); /* CR OPEN */
		end
		
		SET_SCK3 :
		begin
			Write1bRegisterWrapped(10'h202, 16'h02, GET_STATE1); /* CR LISTEN */
		end
		
		GET_STATE1 :
		begin
			Read1bRegisterWrapped(10'h208, SocketState, GET_STATE2);
		end
		
		GET_STATE2 :
		begin
			State <= SOCKET_CLOSED      ? SET_SCK1   : 
			         SOCKET_CLOSE_WAIT  ? SET_SCK1   :
						SOCKET_ESTABLISHED ? TCP_RCV1   :
											      GET_STATE1 ;
		end
		
		TCP_RCV1 :
		begin
			Read2bRegisterWrapped({10'h228,10'h22A}, RxCount, 
										 (RxCount == 32'h0) ? GET_STATE1 : TCP_RX_FIFO1);	/* RX_RSR */
			if (TWO_BYTES_DONE)
			begin
				//Query    <= 80'hAABBCCDDEEFF11223344;
				Query    <= 80'h0;
				TxCount  <= 32'h0;
				RxCountP <= RxCount;
			end
		end
		
		TCP_RX_FIFO1 :
		begin
			Read1bRegisterWrapped(10'h230, Fifo, TCP_RX_FIFO2);	// RX_FIFO
			//Read1bRegisterWrapped(10'h230, Fifo, ECHO1);			// RX_FIFO
			//Read1bRegisterWrapped(10'h230, Fifo, (RxCountP == 32'h6) ? ECHO1 : TCP_RX_FIFO2);	// RX_FIFO
			if (ONE_BYTE_DONE)
				RxCount <= RxCount - 32'd2;
		end
		
		/* Copy received data to TX fifo: */
		ECHO1 :
		begin
			Write1bRegisterWrapped(10'h22E, Fifo, TCP_RX_FIFO2);	// TX_FIFO 
		end
		
		TCP_RX_FIFO2 :
		begin
			Query <= {Query[63:0], Fifo};
			//Query <= {Fifo, Query[79:16]};
			//Query <= {Query[63:0], RxCount[15:0]};
			//Query <= {Query[63:0], RxCountP[15:0]};
			State <= (RxCount == 32'h0) ? TCP_RCV2 : TCP_RX_FIFO1;
		end
		
		TCP_RCV2 :
		begin
			//Write1bRegisterWrapped(10'h202, 16'h40, TCP_RCV3A); 	// RECV
			//Write1bRegisterWrapped(10'h202, 16'h40, ECHO2); 			// RECV
			//Write1bRegisterWrapped(10'h202, 16'h40, ERROR1); 		// RECV
			//Write1bRegisterWrapped(10'h202, 16'h40, (RxCountP == 32'h6) ? ECHO2 : ERROR1); 				// RECV
			//Write1bRegisterWrapped(10'h202, 16'h40, (Query[79:32] == 48'h000841435120) ? OK1 : QUERY1);		// RECV
			Write1bRegisterWrapped(10'h202, 16'h40, (Query[79:32] == 48'h000841435120) ? OK1 : RATE1);		// RECV
		end
		
		ECHO2 :
		begin
			TxCount <= (RxCountP >> 1);
			State   <= TCP_RCV4;
		end
		
		ERROR1 :
		begin
			Write1bRegisterWrapped(10'h22E, ERROR >> (TxCount << 4), ERROR2);
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'h1;
		end
		ERROR2 :
		begin
			State <= (TxCount == 32'h3) ? TCP_RCV4 : ERROR1;
		end
		
		OK1 :
		begin
			Write1bRegisterWrapped(10'h22E, OK >> (TxCount << 4), OK2);
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'h1;
		end
		OK2 :
		begin
			State <= (TxCount == 32'h3) ? TCP_RCV4 : OK1;
		end
		
		QUERY1 :
		begin
			Write1bRegisterWrapped(10'h22E, (Query >> (TxCount << 4)), QUERY2);
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'h1;
		end
		QUERY2 :
		begin
			State <= (TxCount == 32'h5) ? TCP_RCV4 : QUERY1;
		end
		
		RATE1 :
		begin
			Write1bRegisterWrapped(10'h22E, LaserRate >> (TxCount << 4), RATE2);
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'h1;
		end
		RATE2 :
		begin
			State <= (TxCount == 32'h2) ? TCP_RCV4 : RATE1;
		end
		
		
		/* 8 kB overflow: */
		/*TCP_RCV3A :
		begin
			Write1bRegisterWrapped(10'h22E, FreeSize[15:0], TCP_RCV3B);		// TX_FIFO 
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'b1;
		end
		TCP_RCV3B :
		begin
			Read2bRegisterWrapped({10'h224,10'h226}, FreeSize, TCP_RCV3C);	// RX_FSR 
		end
		TCP_RCV3C :
		begin
			State <= (FreeSize == 32'h0) ? TCP_RCV4 : TCP_RCV3A;
		end*/
		/*TCP_RCV3A :
		begin
			Read2bRegisterWrapped({10'h224,10'h226}, FreeSize, TCP_RCV3B);	// RX_FSR 
		end
		TCP_RCV3B :
		begin
			State <= (FreeSize == 32'h0) ? TCP_RCV4 : TCP_RCV3C;		
		end
		TCP_RCV3C :
		begin
			Write1bRegisterWrapped(10'h22E, FreeSize[15:0], TCP_RCV3A);		// TX_FIFO 
			if (ONE_BYTE_DONE)
				TxCount <= TxCount + 32'b1;
		end*/
		
		/* All capital letters: */
		/* TCP_RCV3A :
		begin
			if (ONE_BYTE_DONE)
			begin
				JumpToState(TCP_RCV3B);
				TxCount <= TxCount + 32'b1;
			end
			else
				Write1bRegister(10'h22E, TxCount + 32'h41);	// TX_FIFO 
		end
		TCP_RCV3B :
		begin
			State <= (TxCount >= 32'd26) ? TCP_RCV4 : TCP_RCV3A;
		end */
		
		/* Get received size: */
		/*TCP_RCV3A :
		begin
			if (ONE_BYTE_DONE)
			begin
				JumpToState(TCP_RCV3B);
				TxCount <= TxCount + 32'b1;
			end
			else
				Write1bRegister(10'h22E, Temp >> (TxCount << 4));	// TX_FIFO 
		end
		TCP_RCV3B :
		begin
			State <= (TxCount >= 32'd2) ? TCP_RCV4 : TCP_RCV3A;
		end*/
				
		/* Get free size: */
		/*TCP_RCV3A :
		begin
			if (TWO_BYTES_DONE)
				JumpToState(TCP_RCV3B);
			else
				Read2bRegister({10'h224,10'h226}, RxCount);	// RX_FSR 
		end
		TCP_RCV3B :
		begin
			if (ONE_BYTE_DONE)
			begin
				JumpToState(TCP_RCV3C);
				TxCount <= TxCount + 32'b1;
			end
			else
				Write1bRegister(10'h22E, RxCount >> (TxCount << 4));	// TX_FIFO 
		end
		TCP_RCV3C :
		begin
			State <= (TxCount >= 32'd2) ? TCP_RCV4 : TCP_RCV3B;
		end*/
		
		/* TCP_RCV3 :
		begin
			if (ONE_BYTE_DONE)
				JumpToState(TCP_RCV4);
			else
				Write1bRegister(10'h22E, 16'h5859);	// TX_FIFO 
		end*/
		
		TCP_RCV4 :
		begin
			Write2bRegisterWrapped({10'h220,10'h222}, (TxCount << 1), TCP_RCV5);
		end
		
		TCP_RCV5 :
		begin
			Write1bRegisterWrapped(10'h202, 16'h20, GET_STATE1); /* SEND */
		end
		
	endcase
	
end

endmodule