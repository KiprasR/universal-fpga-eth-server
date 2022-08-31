module ClockCounter(
	input Clk,
	input Laser,
	output reg [31:0] LaserRate = 32'b0
);

	localparam ClkRate = 32'd50000000;

	reg [2:0] LaserState;  always @(posedge Clk) LaserState <= {LaserState[1:0], Laser};
	wire LaserRise = (LaserState[2:1] == 2'b01);
	
	reg [31:0] Counter = 32'd0;
	reg [31:0] LaserCounter = 32'd0;

	always @ (posedge Clk)
	begin
		if (Counter < (ClkRate - 32'd1))
		begin
			Counter <= Counter + 32'd1;
			if (LaserRise) LaserCounter <= LaserCounter + 32'd1;
		end
		else
		begin
			LaserRate <= LaserCounter;
			LaserCounter <= 32'd0;
			Counter <= 32'd0;
		end
	end
endmodule