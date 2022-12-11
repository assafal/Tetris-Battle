// Designer: Mor (Mordechai) Dahan,
// Sep. 2022
// ***********************************************



module periphery_control (
	
	input		clk,
	output	A,
	output	B,
	output	Select_out,
	output	Start,
	output	Right,
	output	Left,
	output	Up,
	output	Down,
	output	[11:0] Wheel
	);
	
	wire	[11:0]	a0;
	wire	[11:0]	a1;
	wire	[11:0]	a2;
	wire	[11:0]	a3;
	wire	[11:0]	a4;
	
	// Analog Read Module
analog_input analog_input_inst(
	.clk(clk),
	.a0(a0), // LEFT/RIGHT Left = High, Right = middle, 0 = nothing
	.a1(a1), // UP/DOWN - Hihg up, midle down. 0 nothing
	.a2(a2), // Select button HIGH is pressed
	.a3(a3), // Button A 0 is pressed
	.a4(a4),	// Button B 0 is pressed
	.a5(Wheel) // Wheel input
	);
	
	assign A = a3 < 2048 ? 0 : 1; // A
	assign B = a4 < 2048 ? 0 : 1; // B
	assign Select_out = a2 > 12'hCFF ? 0 : 1; // Select
	assign Start = a2 < 12'hCFF & a2 > 12'h5FF ? 0 : 1; // Start
	assign Left = a0 > 12'hCFF ? 0 : 1; // Left
	assign Right = a0 < 12'hCFF & a0 > 12'h5FF ? 0 : 1; // Right
	assign Up = a1 > 12'hCFF ? 0 : 1; // UP
	assign Down = a1 < 12'hCFF & a1 > 12'h5FF ? 0 : 1; // DOWN

endmodule
