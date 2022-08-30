module EthGlobal(
	/* PLL: */
	CLK100MHz,
	/* LAN: */
	LAN_ADR,
	LAN_D,
	LAN_BDY,
	LAN_CS,
	LAN_RD,
	LAN_WR,
	LAN_RST,
	LAN_IRQ,
	LAN_PWR,
	/* Misc I/O: */
	LED,
	UFL1,
	UFL2,
	UFL3,
	UFL4,
	UFL5,
	UFL6,
	UFL7,
	UFL8, 
	BTN1n,
	BTN2n
);

/* Crystal/Misc.: */
input CLK100MHz;
wire CLK100;
wire CLK50;
wire CLK20;

/* LAN: */
output [9:0] LAN_ADR;
inout [15:0] LAN_D;
input  [3:0] LAN_BDY;
output LAN_CS;
output LAN_RD;
output LAN_WR;
output LAN_RST;
input  LAN_IRQ;
output LAN_PWR;

/* Misc I/O: */
output [7:0] LED;
output UFL1;
output UFL2;
output UFL3;
output UFL4;
output UFL5;
input  UFL6;
output UFL7;
output UFL8;
input BTN1n;
input BTN2n;

/* Registers: */
wire [31:0] LASER_RATE;

/* Debug: */
wire [7:0] STATE_OUT;

PLL1 pll1(
	.inclk0(CLK100MHz),
	.c0(CLK100),
	.c1(CLK50),
	.c2(CLK20),
	.locked(LAN_PWR)
);

EthFsmTasks eth_fsm(
	//.Clk(CLK100),
	.Clk(CLK50),
	.LanAddr(LAN_ADR),
	.LanData(LAN_D),
	//input  [3:0] LanBrdy,
	.LanCs(LAN_CS),
	.LanRd(LAN_RD),
	.LanWr(LAN_WR),
	.LanRst(LAN_RST),
	.LanIrq(LAN_IRQ),
	/* Debug: */
	.BTN1n(BTN1n),
	.BTN2n(BTN2n),
	.LED(LED),
	.StateOut(STATE_OUT),
	/* Inputs: */
	.LaserRate(LASER_RATE)
);

ClockCounter clk_cnt(
	.Clk(CLK50),
	.Laser(UFL6),
	.LaserRate(LASER_RATE)
);

//assign LED[0] = BTN1n;
//assign LED[3:0] = LAN_BDY;

assign UFL1 = LAN_RST;
assign UFL3 = LAN_WR;
assign UFL4 = LAN_RD;
assign UFL7 = STATE_OUT == 8'd14;
assign UFL8 = LAN_IRQ;

endmodule