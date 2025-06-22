`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: vga_sync, clk_divider, sram, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// declare SRAM control signals
wire [16:0] sram_addr_start_screen;
wire [16:0] sram_addr_end_screen;
wire [16:0] sram_addr_bg;
wire [16:0] sram_addr_snake_head;
wire [16:0] sram_addr_snake_body [9:0];
wire [16:0] sram_addr_snake_tail;
wire [16:0] sram_addr_food;
wire [16:0] sram_addr_stone[1:0];
wire [16:0] sram_addr_number [3:0];
wire [16:0] sram_addr_wall [6:0];
wire [16:0] sram_addr_select_map;
wire [16:0] sram_addr_select_diff;
wire [16:0] sram_addr_shell;
wire [16:0] sram_addr_whistle_baby;
wire [16:0] sram_addr_mute;
wire [16:0] sram_addr_cstone;
wire [11:0] data_in;
wire [11:0] data_out_start_screen;
wire [11:0] data_out_end_screen;
wire [11:0] data_out_bg;
wire [11:0] data_out_snake_head;
wire [11:0] data_out_snake_body [9:0];
wire [11:0] data_out_snake_tail;
wire [11:0] data_out_food;
wire [11:0] data_out_stone [1:0];
wire [11:0] data_out_number [3:0];
wire [11:0] data_out_wall [6:0];
wire [11:0] data_out_select_map;
wire [11:0] data_out_select_diff;
wire [11:0] data_out_shell;
wire [11:0] data_out_whistle_baby;
wire [11:0] data_out_mute;
wire [11:0] data_out_cstone;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr_start_screen;
reg  [17:0] pixel_addr_end_screen;
reg  [17:0] pixel_addr_bg;
reg  [17:0] pixel_addr_snake_head;
reg  [17:0] pixel_addr_snake_body [9:0];
reg  [17:0] pixel_addr_snake_tail;
reg  [17:0] pixel_addr_food;
reg  [17:0] pixel_addr_stone [1:0];
reg  [17:0] pixel_addr_number [3:0];
reg  [17:0] pixel_addr_wall [6:0];
reg  [17:0] pixel_addr_select_map;
reg  [17:0] pixel_addr_select_diff;
reg  [17:0] pixel_addr_shell;
reg  [17:0] pixel_addr_whistle_baby;
reg  [17:0] pixel_addr_mute;
reg  [17:0] pixel_addr_cstone;

wire [3:0] btn_level, btn;
reg  [3:0] prev_btn;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
localparam start_screen_width = 240;
localparam start_screen_height = 16;
localparam end_screen_width = 200;
localparam end_screen_height = 35;
localparam number_width = 16;
localparam number_height = 24;

// Set parameters for the snake images
localparam snake_width      = 8; // Width of the snake.
localparam snake_height     = 8; // Height of the snake.
localparam [1:0] up = 0, down = 1, left = 2, right = 3;
localparam game_width  = 8*30;
localparam game_height = 8*27;
localparam [1:0] down_boundary = 0, up_boundary = 8'd208, right_boundary = 7'd95, left_boundary = 10'd703; //Don't remove this line.
reg [31:0] speed;
reg [1:0] add_speed;
localparam slow_speed = 24'd4000000;
localparam normal_speed = 21'd2000000;
localparam fast_speed = 20'd1000000;
reg [1:0] snake_previous_direction [9:0];
reg [1:0] snake_next_direction;
reg [9:0]  snake_x [9:0];
reg [9:0]  snake_y [9:0];
wire hit_boundary;
wire hit_stone;
wire hit_self;
wire [1:0] hit_wall;
wire        snake_head_region;
wire        snake_body_region0;
wire        snake_body_region1;
wire        snake_body_region2;
wire        snake_body_region3;
wire        snake_body_region4;
wire        snake_body_region5;
wire        snake_body_region6;
wire        snake_body_region7;
wire        snake_tail_region;
wire        food_region;
wire        stone_region0;
wire        stone_region1;
wire        select_map_region;
wire        select_diff_region;
wire        shell_region;
wire        whistle_baby_region;
wire        mute_region;
wire        cstone_region;
reg [31:0] snake_clock;
reg [9:0] snake_length;

wire start_screen_region;
wire end_screen_region;
wire number_region0;
wire number_region1;
wire number_region2;
wire number_region3;
wire wall_region0;
wire wall_region1;
wire wall_region2;
wire wall_region3;
wire wall_region4;
wire wall_region5;
localparam start_screen_x = 559;
localparam start_screen_y = 104;
localparam end_screen_x = 517;
localparam end_screen_y = 91;
localparam number_x0 = 475;
localparam number_y0 = 216;
localparam number_x1 = 447;
localparam number_y1 = 216;
localparam number_x2 = 303;
localparam number_y2 = 216;
localparam number_x3 = 275;
localparam number_y3 = 216;
localparam select_map_screen_x = 455;
localparam select_map_screen_y = 80;
localparam select_diff_screen_x = 455;
localparam select_diff_screen_y = 64;
reg [7:0] score;
reg [7:0] highest_score;

reg food_gone;
reg [6:0] food_clock_y;
reg [6:0] food_clock_x;
reg [9:0] food_x;
reg [9:0] food_y;
reg [6:0] stone_x0_clock;
reg [6:0] stone_y0_clock;
reg [6:0] stone_x1_clock;
reg [6:0] stone_y1_clock;
reg [9:0] stone_x0 = 383;
reg [9:0] stone_y0 =72;
reg [9:0] stone_x1 = 159;
reg [9:0] stone_y1 =192;
reg shell_gone;
reg [6:0] shell_clock_y;
reg [6:0] shell_clock_x;
reg [9:0] shell_x;
reg [9:0] shell_y;
reg [9:0] whistle_baby_x;
reg [9:0] whistle_baby_y;
reg [31:0] whistle_baby_clock;
reg [9:0] cstone_x;
reg [9:0] cstone_y;
reg [31:0] cstone_clock;
reg show_cstone;

reg map;
reg [1:0] difficulty;
reg music;
// states
reg [5:0] P, P_next;
localparam [5:0] S_INIT = 0, S_MAP = 1, S_DIFF = 2, S_STAR = 3, S_GAME = 4, S_OVER = 5;
assign usr_led = P;

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce btn_db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

// Enable one cycle of btn_pressed per each button hit
always @(posedge clk) begin
  if (~reset_n) prev_btn <= 4'h0;
  else prev_btn <= btn_level;
end

assign btn = (btn_level & ~prev_btn);

// ------------------------------------------------------------------------
// The following code describes initialized SRAM memory blocks
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H), .FILE("background.mem"))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_bg), .data_i(data_in), .data_o(data_out_bg));
//When region equals to false, read a transparent cell.
//If there is no transparent cell in .mem, the program won't show the correct image.
//Add a transparent cell manually if so.

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(start_screen_width*start_screen_height), .FILE("start_screen.mem"))
  ram1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_start_screen), .data_i(data_in), .data_o(data_out_start_screen));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(end_screen_width*end_screen_height+1), .FILE("end_screen.mem"))
  ram2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_end_screen), .data_i(data_in), .data_o(data_out_end_screen));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*4), .FILE("snake_head.mem"))
  ram3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_head), .data_i(data_in), .data_o(data_out_snake_head));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram4 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[0]), .data_i(data_in), .data_o(data_out_snake_body[0]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram5 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[1]), .data_i(data_in), .data_o(data_out_snake_body[1]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram6 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[2]), .data_i(data_in), .data_o(data_out_snake_body[2]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram10 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[3]), .data_i(data_in), .data_o(data_out_snake_body[3]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram11 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[4]), .data_i(data_in), .data_o(data_out_snake_body[4]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram12 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[5]), .data_i(data_in), .data_o(data_out_snake_body[5]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram13 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[6]), .data_i(data_in), .data_o(data_out_snake_body[6]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*2), .FILE("snake_body.mem"))
  ram14 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_body[7]), .data_i(data_in), .data_o(data_out_snake_body[7]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height*4), .FILE("snake_tail.mem"))
  ram7 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_snake_tail), .data_i(data_in), .data_o(data_out_snake_tail));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height), .FILE("food.mem"))
  ram8 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_food), .data_i(data_in), .data_o(data_out_food));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height), .FILE("stone.mem"))
  ram9 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_stone[0]), .data_i(data_in), .data_o(data_out_stone[0]));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(snake_width*snake_height), .FILE("stone.mem"))
  ram27 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_stone[1]), .data_i(data_in), .data_o(data_out_stone[1]));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_width*number_height*10), .FILE("number.mem"))
  ram15 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number[0]), .data_i(data_in), .data_o(data_out_number[0]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_width*number_height*10), .FILE("number.mem"))
  ram16 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number[1]), .data_i(data_in), .data_o(data_out_number[1]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_width*number_height*10), .FILE("number.mem"))
  ram28 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number[2]), .data_i(data_in), .data_o(data_out_number[2]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(number_width*number_height*10), .FILE("number.mem"))
  ram29 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_number[3]), .data_i(data_in), .data_o(data_out_number[3]));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*22), .FILE("wall.mem"))
  ram17 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[0]), .data_i(data_in), .data_o(data_out_wall[0]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*6), .FILE("wall.mem"))
  ram18 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[1]), .data_i(data_in), .data_o(data_out_wall[1]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*6), .FILE("wall.mem"))
  ram19 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[2]), .data_i(data_in), .data_o(data_out_wall[2]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(120 * 59 + 1), .FILE("select_map.mem"))
  ram20 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_select_map), .data_i(data_in), .data_o(data_out_select_map));
 
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(120 * 85 + 1), .FILE("select_diff.mem"))
  ram21 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_select_diff), .data_i(data_in), .data_o(data_out_select_diff));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*20), .FILE("wall.mem"))
  ram22 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[3]), .data_i(data_in), .data_o(data_out_wall[3]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*16), .FILE("wall.mem"))
  ram23 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[4]), .data_i(data_in), .data_o(data_out_wall[4]));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64*11), .FILE("wall.mem"))
  ram24 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_wall[5]), .data_i(data_in), .data_o(data_out_wall[5]));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(64), .FILE("shell.mem"))
  ram25 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_shell), .data_i(data_in), .data_o(data_out_shell));

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(120 * 59 + 1), .FILE("whistle_baby.mem"))
  ram26 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_whistle_baby), .data_i(data_in), .data_o(data_out_whistle_baby));
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(24*24), .FILE("mute.mem"))
  ram30 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_mute), .data_i(data_in), .data_o(data_out_mute));
          
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(5200), .FILE("cstone.mem"))
  ram31 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_cstone), .data_i(data_in), .data_o(data_out_cstone));
          
assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr_start_screen = pixel_addr_start_screen;
assign sram_addr_end_screen = pixel_addr_end_screen;
assign sram_addr_bg = pixel_addr_bg;
assign sram_addr_snake_head = pixel_addr_snake_head;
assign sram_addr_snake_body[0] = pixel_addr_snake_body[0];
assign sram_addr_snake_body[1] = pixel_addr_snake_body[1];
assign sram_addr_snake_body[2] = pixel_addr_snake_body[2];
assign sram_addr_snake_body[3] = pixel_addr_snake_body[3];
assign sram_addr_snake_body[4] = pixel_addr_snake_body[4];
assign sram_addr_snake_body[5] = pixel_addr_snake_body[5];
assign sram_addr_snake_body[6] = pixel_addr_snake_body[6];
assign sram_addr_snake_body[7] = pixel_addr_snake_body[7];
assign sram_addr_snake_tail = pixel_addr_snake_tail;
assign sram_addr_food = pixel_addr_food;
assign sram_addr_stone[0] = pixel_addr_stone[0];
assign sram_addr_stone[1] = pixel_addr_stone[1];
assign sram_addr_number[0] = pixel_addr_number[0];
assign sram_addr_number[1] = pixel_addr_number[1];
assign sram_addr_number[2] = pixel_addr_number[2];
assign sram_addr_number[3] = pixel_addr_number[3];
assign sram_addr_wall[0] = pixel_addr_wall[0];
assign sram_addr_wall[1] = pixel_addr_wall[1];
assign sram_addr_wall[2] = pixel_addr_wall[2];
assign sram_addr_wall[3] = pixel_addr_wall[3];
assign sram_addr_wall[4] = pixel_addr_wall[4];
assign sram_addr_wall[5] = pixel_addr_wall[5];
assign sram_addr_select_map = pixel_addr_select_map;
assign sram_addr_select_diff = pixel_addr_select_diff;
assign sram_addr_shell = pixel_addr_shell;
assign sram_addr_whistle_baby = pixel_addr_whistle_baby;
assign sram_addr_mute = pixel_addr_mute;
assign sram_addr_cstone = pixel_addr_cstone;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the snake, upper bits of the
// snake clock is the x position of the snake on the VGA screen.
// or 10.49 msec

always @(posedge clk) begin
  if (~reset_n) P <= S_INIT;
  else P <= P_next;
end

always @(*) begin
  case(P)
    S_INIT:
      P_next <= S_MAP;
    S_MAP:
      if (btn[1] || btn[2]) P_next <= S_DIFF;
      else P_next <= S_MAP;
    S_DIFF:
      if (btn[0] || btn[1] || btn[2]) P_next <= S_STAR;
      else P_next <= S_DIFF;
    S_STAR:
      if (btn != 4'b0000) P_next <= S_GAME;
      else P_next <= S_STAR;
    S_GAME:
      if (hit_self || hit_boundary || (map==0&&hit_wall[0]) || (map==1&&hit_wall[1]) || score==8'b11111111 || snake_length<=1) P_next <= S_OVER; // todo: dead
      else P_next <= S_GAME;
    S_OVER:
      if (btn != 4'b0000) P_next <= S_INIT;
      else P_next <= S_OVER;
  endcase
end

always @(posedge clk) begin
  if (P == S_INIT) begin
    map <= 0;
    difficulty <= 1;
    speed <= slow_speed;
    music <= 0;
  end
  else begin
    if(P == S_MAP) begin
        if (btn[1]) map <= 0;
        else if (btn[2]) map <= 1;
        if (btn[3]) music <= 1;
    end
     else if(P == S_DIFF) begin
        music <= 0;
        if (btn[0]) begin
            difficulty = 0;
            speed <= slow_speed;
        end
        else if (btn[1]) begin
            difficulty = 1;
            speed <= normal_speed;
        end
        else if (btn[2]) begin
            difficulty = 2;
            speed <= fast_speed;
        end
    end
    else if (P==S_GAME && P_next==S_GAME) begin
        if (snake_x[0]==food_x&&snake_y[0]==food_y) speed <= speed;
        else if (food_gone)speed<= speed - 100000;
    end
  end
end

//Use button to change direction.
always @(posedge clk) begin
  if (P == S_INIT || P == S_STAR) begin
    snake_previous_direction[0] = right;
    snake_previous_direction[1] = right;
    snake_previous_direction[2] = right;
    snake_previous_direction[3] = right;
    snake_previous_direction[4] = right;
    snake_previous_direction[5] = right;
    snake_previous_direction[6] = right;
    snake_previous_direction[7] = right;
    snake_previous_direction[8] = right;
    snake_previous_direction[9] = right;
    snake_next_direction = right;
  end
  else if (P == S_GAME)begin
    if (btn[3] && snake_previous_direction[0] != down) snake_next_direction = up;
    if (btn[2] && snake_previous_direction[0] != up) snake_next_direction = down;
    if (btn[1] && snake_previous_direction[0] != right) snake_next_direction = left;
    if (btn[0] && snake_previous_direction[0] != left) snake_next_direction = right;
    else snake_next_direction = snake_next_direction;
  end
  if (snake_y[0][2:0] == 3'b000 && snake_x[0][3:0] == 4'b1111 && snake_clock == speed-1) begin
    if (P == S_GAME) begin
    snake_previous_direction[9] <= snake_previous_direction[8];
    snake_previous_direction[8] <= snake_previous_direction[7];
    snake_previous_direction[7] <= snake_previous_direction[6];
    snake_previous_direction[6] <= snake_previous_direction[5];
    snake_previous_direction[5] <= snake_previous_direction[4];
    snake_previous_direction[4] <= snake_previous_direction[3];
    snake_previous_direction[3] <= snake_previous_direction[2];
    snake_previous_direction[2] <= snake_previous_direction[1];
    snake_previous_direction[1] <= snake_previous_direction[0];
    snake_previous_direction[0] <= snake_next_direction;
    end
  end
end

//Change the position of snake by direction.
assign hit_boundary = 208 < snake_y[0] || up_boundary > snake_y[0] || 559 < snake_x[0] || snake_x[0] < 95;
assign hit_stone = (snake_x[0] == stone_x0 && snake_y[0] == stone_y0) || (snake_x[0] == stone_x1 && snake_y[0] == stone_y1);
assign hit_wall[0] = (snake_y[0] == 56 && 159 <= snake_x[0] && snake_x[0] <= 239) || 
                                 (snake_y[0] == 56 && 415 <= snake_x[0] && snake_x[0] <= 495) || 
                                 (snake_y[0] == 152 && 159 <= snake_x[0] && snake_x[0] <= 495);
assign hit_wall[1] = (snake_y[0] == 32 && 207 <= snake_x[0] && snake_x[0] <= 447) || 
                                 (snake_y[0] == 120 && 207 <= snake_x[0] && snake_x[0] <= 367) || 
                                 (snake_x[0] == 207 && 32 <= snake_y[0] && snake_y[0] <= 176);
assign hit_self = ((snake_length>=2&&snake_x[0]==snake_x[1]&&snake_y[0]==snake_y[1]) ||
                             (snake_length>=3&&snake_x[0]==snake_x[2]&&snake_y[0]==snake_y[2]) ||
                             (snake_length>=4&&snake_x[0]==snake_x[3]&&snake_y[0]==snake_y[3]) ||
                             (snake_length>=5&&snake_x[0]==snake_x[4]&&snake_y[0]==snake_y[4]) ||
                             (snake_length>=6&&snake_x[0]==snake_x[5]&&snake_y[0]==snake_y[5]) ||
                             (snake_length>=7&&snake_x[0]==snake_x[6]&&snake_y[0]==snake_y[6]) ||
                             (snake_length>=8&&snake_x[0]==snake_x[7]&&snake_y[0]==snake_y[7]) ||
                             (snake_length>=9&&snake_x[0]==snake_x[8]&&snake_y[0]==snake_y[8]) ||
                             (snake_length>=10&&snake_x[0]==snake_x[9]&&snake_y[0]==snake_y[9]));

always @(posedge clk) begin
  if (~reset_n || P == S_INIT) begin
    snake_x[0] <= 319;
    snake_x[1] <= 303;
    snake_x[2] <= 287;
    snake_x[3] <= 271;
    snake_x[4] <= 255;
    snake_x[5] <= 239;
    snake_x[6] <= 223;
    snake_x[7] <= 207;
    snake_x[8] <= 191;
    snake_x[9] <= 175;
    snake_y[0] <= 104;
    snake_y[1] <= 104;
    snake_y[2] <= 104;
    snake_y[3] <= 104;
    snake_y[4] <= 104;
    snake_y[5] <= 104;
    snake_y[6] <= 104;
    snake_y[7] <= 104;
    snake_y[8] <= 104;
    snake_y[9] <= 104;
    snake_clock <= 0;
  end
    else if (P == S_GAME && P_next == S_GAME) begin
       if (snake_clock == speed) begin
         if (snake_previous_direction[0] == up) snake_y[0] <= snake_y[0] - 1;
         if (snake_previous_direction[0] == down) snake_y[0] <= snake_y[0] + 1;
         if (snake_previous_direction[0] == left) snake_x[0] <= snake_x[0] - 2;
         if (snake_previous_direction[0] == right) snake_x[0] <= snake_x[0] + 2;
         if (snake_previous_direction[1] == up) snake_y[1] <= snake_y[1] - 1;
         if (snake_previous_direction[1] == down) snake_y[1] <= snake_y[1] + 1;
         if (snake_previous_direction[1] == left) snake_x[1] <= snake_x[1] - 2;
         if (snake_previous_direction[1] == right) snake_x[1] <= snake_x[1] + 2;
         if (snake_previous_direction[2] == up) snake_y[2] <= snake_y[2] - 1;
         if (snake_previous_direction[2] == down) snake_y[2] <= snake_y[2] + 1;
         if (snake_previous_direction[2] == left) snake_x[2] <= snake_x[2] - 2;
         if (snake_previous_direction[2] == right) snake_x[2] <= snake_x[2] + 2;
         if (snake_previous_direction[3] == up) snake_y[3] <= snake_y[3] - 1;
         if (snake_previous_direction[3] == down) snake_y[3] <= snake_y[3] + 1;
         if (snake_previous_direction[3] == left) snake_x[3] <= snake_x[3] - 2;
         if (snake_previous_direction[3] == right) snake_x[3] <= snake_x[3] + 2;
         if (snake_previous_direction[4] == up) snake_y[4] <= snake_y[4] - 1;
         if (snake_previous_direction[4] == down) snake_y[4] <= snake_y[4] + 1;
         if (snake_previous_direction[4] == left) snake_x[4] <= snake_x[4] - 2;
         if (snake_previous_direction[4] == right) snake_x[4] <= snake_x[4] + 2;
         if (snake_previous_direction[5] == up) snake_y[5] <= snake_y[5] - 1;
         if (snake_previous_direction[5] == down) snake_y[5] <= snake_y[5] + 1;
         if (snake_previous_direction[5] == left) snake_x[5] <= snake_x[5] - 2;
         if (snake_previous_direction[5] == right) snake_x[5] <= snake_x[5] + 2;
         if (snake_previous_direction[6] == up) snake_y[6] <= snake_y[6] - 1;
         if (snake_previous_direction[6] == down) snake_y[6] <= snake_y[6] + 1;
         if (snake_previous_direction[6] == left) snake_x[6] <= snake_x[6] - 2;
         if (snake_previous_direction[6] == right) snake_x[6] <= snake_x[6] + 2;
         if (snake_previous_direction[7] == up) snake_y[7] <= snake_y[7] - 1;
         if (snake_previous_direction[7] == down) snake_y[7] <= snake_y[7] + 1;
         if (snake_previous_direction[7] == left) snake_x[7] <= snake_x[7] - 2;
         if (snake_previous_direction[7] == right) snake_x[7] <= snake_x[7] + 2;
         if (snake_previous_direction[8] == up) snake_y[8] <= snake_y[8] - 1;
         if (snake_previous_direction[8] == down) snake_y[8] <= snake_y[8] + 1;
         if (snake_previous_direction[8] == left) snake_x[8] <= snake_x[8] - 2;
         if (snake_previous_direction[8] == right) snake_x[8] <= snake_x[8] + 2;
         if (snake_previous_direction[9] == up) snake_y[9] <= snake_y[9] - 1;
         if (snake_previous_direction[9] == down) snake_y[9] <= snake_y[9] + 1;
         if (snake_previous_direction[9] == left) snake_x[9] <= snake_x[9] - 2;
         if (snake_previous_direction[9] == right) snake_x[9] <= snake_x[9] + 2;
        snake_clock <= 0;
      end
      else snake_clock <= snake_clock + 1;
    end
  else if (P == S_OVER || P_next == S_OVER) begin
        snake_x[0] <= snake_x[0];
        snake_x[1] <= snake_x[1];
        snake_x[2] <= snake_x[2];
        snake_x[3] <= snake_x[3];
        snake_x[4] <= snake_x[4];
        snake_x[5] <= snake_x[5];
        snake_x[6] <= snake_x[6];
        snake_x[7] <= snake_x[7];
        snake_x[8] <= snake_x[8];
        snake_x[9] <= snake_x[9];
        snake_y[0] <= snake_y[0];
        snake_y[1] <= snake_y[1];
        snake_y[2] <= snake_y[2];
        snake_y[3] <= snake_y[3];
        snake_y[4] <= snake_y[4];
        snake_y[5] <= snake_y[5];
        snake_y[6] <= snake_y[6];
        snake_y[7] <= snake_y[7];
        snake_y[8] <= snake_y[8];
        snake_y[9] <= snake_y[9];
  end
end

always @ (posedge clk) begin
    if (~reset_n || P == S_INIT) begin
        food_gone <= 0;
        shell_gone <= 0;
        shell_x <= shell_clock_x * 16 + 111;
        shell_y <= shell_clock_y * 8 + 8;
        food_x <= food_clock_x * 16 + 111;
        food_y <= food_clock_y * 8 + 8;
    end
    if (P == S_INIT) begin
        stone_x0 <= stone_x0_clock * 16 + 111;
        stone_y0 <= stone_y0_clock * 8 + 8;
        stone_x1 <= stone_x1_clock * 16 + 111;
        stone_y1 <= stone_y1_clock * 8 + 8;
    end
    if(P == S_GAME) begin
      if (snake_x[0] == shell_x && snake_y[0] == shell_y) 
        shell_gone <= 1;
      else if (shell_gone) begin
          shell_gone <= 0;
          shell_x <= shell_clock_x * 16 + 111;
          shell_y <= shell_clock_y * 8 + 8;
      end
      if (map == 0 && 
        ( (shell_y == 56 && shell_x >= 159 && shell_x <= 239) || 
          (shell_y == 56 && shell_x >= 415 && shell_x <= 495) ||
          (shell_y == 152 && shell_x >= 159 && shell_x <= 495)   )) begin
            shell_y <= shell_y + 16;
          end 
      if (map == 1 && 
        ( (shell_y == 32 && shell_x >= 223 && shell_x <= 447) || 
          (shell_y == 120 && shell_x >= 223 && shell_x <= 367)   )) begin
            shell_y <= shell_y - 8;
          end
      if (map == 1 &&
          (shell_x == 207 && shell_y >= 64 && shell_y <= 176) ) begin
          shell_x <= shell_x - 16;
        end
      if (snake_x[0] == food_x && snake_y[0] == food_y)
        food_gone <= 1;
     else if (food_gone) begin
          food_gone <= 0;
          // x has to be 1111 in the back, y have to be 000 in the back
          // boundery : x from 95 to 559 (+16 for every tile), y from 0 to 208 (+8 for every tile)
          food_x <= food_clock_x * 16 + 111;
          food_y <= food_clock_y * 8 + 8;
      end
      // check if food is generate in the walls
       if (map == 0 && 
        ( (food_y == 56 && food_x >= 159 && food_x <= 239) || 
          (food_y == 56 && food_x >= 415 && food_x <= 495) ||
          (food_y == 152 && food_x >= 159 && food_x <= 495)   )) begin
            food_y <= food_y + 16;
          end 
      if (map == 1 && 
        ( (food_y == 32 && food_x >= 223 && food_x <= 447) || 
          (food_y == 120 && food_x >= 223 && food_x <= 367)   )) begin
            food_y <= food_y - 8;
          end
      if (map == 1 &&
          (food_x == 207 && food_y >= 64 && food_y <= 176) ) begin
          food_x <= food_x - 16;
        end
    end
end

//control the length of snake
always @(posedge clk) begin
    if (~reset_n || P == S_INIT)  
        snake_length <= 5;
    if (P == S_GAME) begin
      if (snake_x[0] == food_x && snake_y[0] == food_y)
        snake_length <= snake_length;
      else if (food_gone)
           if (snake_length != 10) snake_length <= snake_length + 1;
      if (snake_x[0] == shell_x && snake_y[0] == shell_y)
        snake_length <= snake_length;
      else if (shell_gone) 
        snake_length <= snake_length - 2;
    end
end

//score
always @(posedge clk) begin
    if (~reset_n) highest_score <= 8'b00000000;
    if (~reset_n || P == S_INIT) score <= 8'b00000000;
    if(P == S_GAME) begin
        if (snake_x[0] == food_x && snake_y[0] == food_y) begin
            score <= score;
            highest_score <= highest_score;
        end
        else if (food_gone) begin
            if (score != 8'b10011001) score <= score + 1;
            if (score[3:0] == 4'b1001) score <= score + 7;
        end
        if (snake_clock == speed && ((snake_x[0] == stone_x0 && snake_y[0] == stone_y0) || (snake_x[0] == stone_x1 && snake_y[0] == stone_y1))) begin
            if (score[3:0] == 4'b0000 && score != 8'b00000000) score <= score - 6;
            if (score != 8'b00000000) score <= score - 1;
            else score <= 8'b11111111 ;
        end
        if (score != 8'b11111111 && score > highest_score) highest_score <= score;
    end
end
 
always @(posedge clk) begin
    if (~reset_n || P == S_INIT) begin
      food_clock_x <= 21;
      food_clock_y <= 15;
      shell_clock_x <= 10;
      shell_clock_y <= 5;
      stone_x0_clock <= 19;
      stone_y0_clock <= 10;
      stone_x1_clock <= 4;
      stone_y1_clock <= 23;
    end
    else if (P == S_GAME) begin
      if (food_clock_x == 27) food_clock_x <= 0;
      else food_clock_x <= food_clock_x + 1;
      if (food_clock_y == 24) food_clock_y <= 0;
      else food_clock_y <= food_clock_y + 1;
      if (shell_clock_x == 27) shell_clock_x <= 0;
      else shell_clock_x <= shell_clock_x + 1;
      if (shell_clock_y == 24) shell_clock_y <= 0;
      else shell_clock_y <= shell_clock_y + 1;
      if (stone_x0_clock == 27) stone_x0_clock <= 0;
      else stone_x0_clock <= stone_x0_clock + 1;
      if (stone_y0_clock >= 24) stone_y0_clock <= 0;
      else stone_y0_clock <= stone_y0_clock + 2;
      if (stone_x1_clock >= 27) stone_x1_clock <= 0;
      else stone_x1_clock <= stone_x1_clock + 2;
      if (stone_y1_clock == 24) stone_y1_clock <= 0;
      else stone_y1_clock <= stone_y1_clock + 1;
    end
end

always @(posedge clk) begin
    if (~reset_n || P == S_INIT) begin
        whistle_baby_x <= 95;
        whistle_baby_y <= 80;
        whistle_baby_clock <= 0;
    end
    else if (music)begin
        if (whistle_baby_clock == 1000000) begin
            whistle_baby_x <= whistle_baby_x + 1;
            whistle_baby_clock <= 0;
        end
        else whistle_baby_clock <= whistle_baby_clock + 1;
        if (whistle_baby_x >= 455) whistle_baby_x <= whistle_baby_x;
    end
end

always @(posedge clk) begin
    if (~reset_n || P == S_INIT) begin
        cstone_x <= 95;
        cstone_y <= 80;
        cstone_clock <= 0;
        show_cstone <= 0;
    end
    if ((snake_x[0] == stone_x0 && snake_y[0] == stone_y0) || (snake_x[0] == stone_x1 && snake_y[0] == stone_y1)) 
        show_cstone <= 1;
    if (show_cstone)begin
        if (cstone_clock == 500000) begin
            cstone_x <= cstone_x + 1;
            cstone_clock <= 0;
        end
        else cstone_clock <= cstone_clock + 1;
        if (cstone_x >= 640) show_cstone <= 0;
    end
end

// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the snake image is 8x8, when scaled-up
// on the screen, it becomes    . 'pos' specifies the right edge of the
// snake image.
assign snake_head_region =
           pixel_y >= (snake_y[0]<<1) && pixel_y < (snake_y[0]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[0] && pixel_x < snake_x[0] + 1;
assign snake_body_region0 =
           pixel_y >= (snake_y[1]<<1) && pixel_y < (snake_y[1]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[1] && pixel_x < snake_x[1] + 1;
assign snake_body_region1 =
           pixel_y >= (snake_y[2]<<1) && pixel_y < (snake_y[2]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[2] && pixel_x < snake_x[2] + 1;
assign snake_body_region2 =
           pixel_y >= (snake_y[3]<<1) && pixel_y < (snake_y[3]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[3] && pixel_x < snake_x[3] + 1;
assign snake_body_region3 =
           pixel_y >= (snake_y[4]<<1) && pixel_y < (snake_y[4]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[4] && pixel_x < snake_x[4] + 1;
assign snake_body_region4 =
           pixel_y >= (snake_y[5]<<1) && pixel_y < (snake_y[5]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[5] && pixel_x < snake_x[5] + 1;
assign snake_body_region5 =
           pixel_y >= (snake_y[6]<<1) && pixel_y < (snake_y[6]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[6] && pixel_x < snake_x[6] + 1;
assign snake_body_region6 =
           pixel_y >= (snake_y[7]<<1) && pixel_y < (snake_y[7]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[7] && pixel_x < snake_x[7] + 1;
assign snake_body_region7 =
           pixel_y >= (snake_y[8]<<1) && pixel_y < (snake_y[8]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[8] && pixel_x < snake_x[8] + 1;
 assign snake_tail_region =
           pixel_y >= (snake_y[snake_length-1]<<1) && pixel_y < (snake_y[snake_length-1]+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= snake_x[snake_length-1] && pixel_x < snake_x[snake_length-1] + 1;
 assign start_screen_region =
            pixel_y >= (start_screen_y<<1) && pixel_y < (start_screen_y+start_screen_height)<<1 &&
           (pixel_x + (start_screen_width*2-1)) >= start_screen_x && pixel_x < start_screen_x + 1;
 assign end_screen_region =
            pixel_y >= (end_screen_y<<1) && pixel_y < (end_screen_y+end_screen_height)<<1 &&
           (pixel_x + (end_screen_width*2-1)) >= end_screen_x && pixel_x < end_screen_x + 1;
 assign food_region =
            pixel_y >= (food_y<<1) && pixel_y < (food_y+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= food_x && pixel_x < food_x + 1;
 assign stone_region0 =
            pixel_y >= (stone_y0<<1) && pixel_y < (stone_y0+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= stone_x0 && pixel_x < stone_x0 + 1;
 assign stone_region1 =
            pixel_y >= (stone_y1<<1) && pixel_y < (stone_y1+snake_height)<<1 &&
           (pixel_x + (snake_width*2-1)) >= stone_x1 && pixel_x < stone_x1 + 1;
assign number_region0 =
           pixel_y >= (number_y0<<1) && pixel_y < (number_y0+number_height)<<1 &&
           (pixel_x + (number_width*2-1)) >= number_x0 && pixel_x < number_x0 + 1;
assign number_region1 =
           pixel_y >= (number_y1<<1) && pixel_y < (number_y1+number_height)<<1 &&
           (pixel_x + (number_width*2-1)) >= number_x1 && pixel_x < number_x1 + 1;
assign number_region2 =
           pixel_y >= (number_y2<<1) && pixel_y < (number_y2+number_height)<<1 &&
           (pixel_x + (number_width*2-1)) >= number_x2 && pixel_x < number_x2 + 1;
assign number_region3 =
           pixel_y >= (number_y3<<1) && pixel_y < (number_y3+number_height)<<1 &&
           (pixel_x + (number_width*2-1)) >= number_x3 && pixel_x < number_x3 + 1;
assign wall_region0 =
           pixel_y >= (152<<1) && pixel_y < (152+8)<<1 &&
           (pixel_x + (176*2-1)) >= 495 && pixel_x < 495 + 1;
assign wall_region1 =
           pixel_y >= (56<<1) && pixel_y < (56+8)<<1 &&
           (pixel_x + (48*2-1)) >= 239 && pixel_x < 239 + 1;
assign wall_region2 =
           pixel_y >= (56<<1) && pixel_y < (56+8)<<1 &&
           (pixel_x + (48*2-1)) >= 495 && pixel_x < 495 + 1;
assign select_map_region = 
          pixel_y >= (select_map_screen_y << 1) && pixel_y < (select_map_screen_y + 59) << 1 &&
           (pixel_x + (120 * 2) - 1) >= select_map_screen_x && pixel_x < (select_map_screen_x) + 1;
assign select_diff_region = 
          pixel_y >= (select_diff_screen_y << 1) && pixel_y < (select_diff_screen_y + 85) << 1 &&
           (pixel_x + (120 * 2) - 1) >= select_diff_screen_x && pixel_x < (select_diff_screen_x) + 1;
assign wall_region3 =
           pixel_y >= (32<<1) && pixel_y < (32+152)<<1 &&
           (pixel_x + (8*2-1)) >= 207 && pixel_x < 207 + 1;
assign wall_region4 =
           pixel_y >= (32<<1) && pixel_y < (32+8)<<1 &&
           (pixel_x + (128*2-1)) >= 447 && pixel_x < 447 + 1;
assign wall_region5 =
           pixel_y >= (120<<1) && pixel_y < (120+8)<<1 &&
           (pixel_x + (88*2-1)) >= 367 && pixel_x < 367 + 1;
assign shell_region = 
          pixel_y >= (shell_y << 1) && pixel_y < (shell_y + 8) << 1 &&
           (pixel_x + (8 * 2) - 1) >= shell_x && pixel_x < (shell_x) + 1;
assign whistle_baby_region = 
          pixel_y >= (whistle_baby_y << 1) && pixel_y < (whistle_baby_y + 59) << 1 &&
           (pixel_x + (120 * 2) - 1) >= whistle_baby_x && pixel_x < (whistle_baby_x) + 1;
assign mute_region = 
          pixel_y >= (216 << 1) && pixel_y < (216 + 24) << 1 &&
           (pixel_x + (24 * 2) - 1) >= 559 && pixel_x < (559) + 1;
assign cstone_region = 
          pixel_y >= (cstone_y << 1) && pixel_y < (cstone_y + 80) << 1 &&
           (pixel_x + (65 * 2) - 1) >=cstone_x && pixel_x < (cstone_x) + 1;

always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr_start_screen <= 0;
    pixel_addr_end_screen <= 0;
    pixel_addr_bg <= 0;
    pixel_addr_snake_head <= 0;
    pixel_addr_snake_body[0] <= 0;
    pixel_addr_snake_body[1] <= 0;
    pixel_addr_snake_body[2] <= 0;
    pixel_addr_snake_body[3] <= 0;
    pixel_addr_snake_body[4] <= 0;
    pixel_addr_snake_body[5] <= 0;
    pixel_addr_snake_body[6] <= 0;
    pixel_addr_snake_body[7] <= 0;
    pixel_addr_snake_tail <= 0;
    pixel_addr_food <= 0;
    pixel_addr_stone[0] <= 0;
    pixel_addr_stone[1] <= 0;
    pixel_addr_number[0] <= 0;
    pixel_addr_number[1] <= 0;
    pixel_addr_number[2] <= 0;
    pixel_addr_number[3] <= 0;
    pixel_addr_wall[0] <= 0;
    pixel_addr_wall[1] <= 0;
    pixel_addr_wall[2] <= 0;
    pixel_addr_select_map <= 0;
    pixel_addr_select_diff <= 0;
    pixel_addr_wall[3] <= 0;
    pixel_addr_wall[4] <= 0;
    pixel_addr_wall[5] <= 0;
    pixel_addr_shell <= 0;
    pixel_addr_whistle_baby <= 0;
    pixel_addr_mute <= 0;
    pixel_addr_cstone <= 0;
  end
  else begin
    pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    if (P == S_STAR && start_screen_region)
        pixel_addr_start_screen <=
                  ((pixel_y>>1)-start_screen_y)*start_screen_width +
                  ((pixel_x +(start_screen_width*2-1)-start_screen_x)>>1);
    else pixel_addr_start_screen <= 0;
    if (P == S_OVER && end_screen_region)
        pixel_addr_end_screen <=
                  ((pixel_y>>1)-end_screen_y)*end_screen_width +
                  ((pixel_x +(end_screen_width*2-1)-end_screen_x)>>1);
    else pixel_addr_end_screen <= 0;
    if (P == S_MAP && select_map_region)
        pixel_addr_select_map <= 
                  ((pixel_y >> 1) - select_map_screen_y) * 120 +
                  ((pixel_x + (120 * 2 - 1) - select_map_screen_x) >> 1);
    else pixel_addr_select_map <= 7080;
    if (P == S_DIFF && select_diff_region)
        pixel_addr_select_diff <= 
                  ((pixel_y >> 1) - select_diff_screen_y) * 120 +
                  ((pixel_x + (120 * 2 - 1) - select_diff_screen_x) >> 1);
    else pixel_addr_select_diff <= 10200;
    if (snake_head_region)
        pixel_addr_snake_head <= snake_width*snake_height*snake_previous_direction[0] +
                  ((pixel_y>>1)-snake_y[0])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[0])>>1);
     else pixel_addr_snake_head <= 0;
     if (snake_length>=3 && snake_body_region0)
           pixel_addr_snake_body[0] <= snake_width*snake_height*snake_previous_direction[1][1] +
                  ((pixel_y>>1)-snake_y[1])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[1])>>1);
     else pixel_addr_snake_body[0] <= 0;
     if (snake_length>=4 && snake_body_region1)
           pixel_addr_snake_body[1] <= snake_width*snake_height*snake_previous_direction[2][1] +
                  ((pixel_y>>1)-snake_y[2])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[2])>>1);
     else pixel_addr_snake_body[1] <= 0;
     if (snake_length>=5 && snake_body_region2)
           pixel_addr_snake_body[2] <= snake_width*snake_height*snake_previous_direction[3][1] +
                  ((pixel_y>>1)-snake_y[3])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[3])>>1);
     else pixel_addr_snake_body[2] <= 0;
     if (snake_length>=6 && snake_body_region3)
           pixel_addr_snake_body[3] <= snake_width*snake_height*snake_previous_direction[4][1] +
                  ((pixel_y>>1)-snake_y[4])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[4])>>1);
     else pixel_addr_snake_body[3] <= 0;
     if (snake_length>=7 && snake_body_region4)
           pixel_addr_snake_body[4] <= snake_width*snake_height*snake_previous_direction[5][1] +
                  ((pixel_y>>1)-snake_y[5])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[5])>>1);
     else pixel_addr_snake_body[4] <= 0;
     if (snake_length>=8 && snake_body_region5)
           pixel_addr_snake_body[5] <= snake_width*snake_height*snake_previous_direction[6][1] +
                  ((pixel_y>>1)-snake_y[6])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[6])>>1);
     else pixel_addr_snake_body[5] <= 0;
     if (snake_length>=9 && snake_body_region6)
           pixel_addr_snake_body[6] <= snake_width*snake_height*snake_previous_direction[7][1] +
                  ((pixel_y>>1)-snake_y[7])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[7])>>1);
     else pixel_addr_snake_body[6] <= 0;
     if (snake_length>=10 && snake_body_region7)
           pixel_addr_snake_body[7] <= snake_width*snake_height*snake_previous_direction[8][1] +
                  ((pixel_y>>1)-snake_y[8])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[8])>>1);
     else pixel_addr_snake_body[7] <= 0;
     if (snake_tail_region)
        pixel_addr_snake_tail <= snake_width*snake_height*snake_previous_direction[snake_length-1] +
                  ((pixel_y>>1)-snake_y[snake_length-1])*snake_width +
                  ((pixel_x +(snake_width*2-1)-snake_x[snake_length-1])>>1);
     else pixel_addr_snake_tail <= 0;
     if (food_region && ~food_gone)
        pixel_addr_food <= 
                  ((pixel_y>>1)-food_y)*snake_width +
                  ((pixel_x +(snake_width*2-1)-food_x)>>1);
      else pixel_addr_food <= 0;
      if (stone_region0)
        pixel_addr_stone[0] <= 
                  ((pixel_y>>1)-stone_y0)*snake_width +
                  ((pixel_x +(snake_width*2-1)-stone_x0)>>1);
      else pixel_addr_stone[0] <= 0;
      if (stone_region1)
        pixel_addr_stone[1] <= 
                  ((pixel_y>>1)-stone_y1)*snake_width +
                  ((pixel_x +(snake_width*2-1)-stone_x1)>>1);
      else pixel_addr_stone[1] <= 0;
       if (number_region0)
        pixel_addr_number[0] <= score[3:0]*number_width*number_height + 
                  ((pixel_y>>1)-number_y0)*number_width +
                  ((pixel_x +(number_width*2-1)-number_x0)>>1);
      else pixel_addr_number[0] <= 0;
       if (number_region1)
        pixel_addr_number[1] <=  score[7:4]*number_width*number_height + 
                  ((pixel_y>>1)-number_y1)*number_width +
                  ((pixel_x +(number_width*2-1)-number_x1)>>1);
      else pixel_addr_number[1] <= 0;
       if (number_region2)
        pixel_addr_number[2] <= highest_score[3:0]*number_width*number_height + 
                  ((pixel_y>>1)-number_y2)*number_width +
                  ((pixel_x +(number_width*2-1)-number_x2)>>1);
      else pixel_addr_number[2] <= 0;
       if (number_region3)
        pixel_addr_number[3] <=  highest_score[7:4]*number_width*number_height + 
                  ((pixel_y>>1)-number_y3)*number_width +
                  ((pixel_x +(number_width*2-1)-number_x3)>>1);
      else pixel_addr_number[3] <= 0;
      if (map == 0 && wall_region0)
        pixel_addr_wall[0] <=  
                  ((pixel_y>>1)-152)*176 +
                  ((pixel_x +(176*2-1)-495)>>1);
      else pixel_addr_wall[0] <= 0;
      if (map == 0 && wall_region1)
        pixel_addr_wall[1] <=  
                  ((pixel_y>>1)-56)*48 +
                  ((pixel_x +(48*2-1)-239)>>1);
      else pixel_addr_wall[1] <= 0;
      if (map == 0 && wall_region2)
        pixel_addr_wall[2] <=  
                  ((pixel_y>>1)-56)*48 +
                  ((pixel_x +(48*2-1)-495)>>1);
      else pixel_addr_wall[2] <= 0;
      if (map == 1 && wall_region3)
        pixel_addr_wall[3] <=  
                  ((pixel_y>>1)-176)*8 +
                  ((pixel_x +(8*2-1)-207)>>1);
      else pixel_addr_wall[3] <= 0;
      if (map == 1 && wall_region4)
        pixel_addr_wall[4] <=  
                  ((pixel_y>>1)-32)*128 +
                  ((pixel_x +(128*2-1)-447)>>1);
      else pixel_addr_wall[4] <= 0;
      if (map == 1 && wall_region5)
        pixel_addr_wall[5] <=  
                  ((pixel_y>>1)-120)*88 +
                  ((pixel_x +(88*2-1)-367)>>1);
      else pixel_addr_wall[5] <= 0;
      if (shell_region && ~shell_gone)
        pixel_addr_shell <= 
                  ((pixel_y>>1)-shell_y)*8 +
                  ((pixel_x +(8*2-1)-shell_x)>>1);
      else pixel_addr_shell <= 0;
      if (music && whistle_baby_region)
        pixel_addr_whistle_baby <= 
                  ((pixel_y >> 1) - whistle_baby_y) * 120 +
                  ((pixel_x + (120 * 2 - 1) - whistle_baby_x) >> 1);
      else pixel_addr_whistle_baby <= 7080;
      if (~music && mute_region)
        pixel_addr_mute <= 
                  ((pixel_y >> 1) - 216) * 24 +
                  ((pixel_x + (24 * 2 - 1) - 559) >> 1);
      else pixel_addr_mute <= 0;
      if (show_cstone && cstone_region)
        pixel_addr_cstone <= 
                  ((pixel_y >> 1) - cstone_y) * 65 +
                  ((pixel_x + (65 * 2 - 1) - cstone_x) >> 1);
      else pixel_addr_cstone <= 0;
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if (data_out_cstone != 12'h0f0)rgb_next = data_out_cstone;
  else if (data_out_whistle_baby != 12'h0f0) rgb_next = data_out_whistle_baby;
  else if (data_out_select_map != 12'h0f0) rgb_next = data_out_select_map;
  else if (data_out_select_diff != 12'h0f0) rgb_next = data_out_select_diff;
  else if (data_out_end_screen != 12'h0f0) rgb_next = data_out_end_screen;
  else if (data_out_start_screen != 12'h0f0) rgb_next = data_out_start_screen;
  else if (data_out_stone[0] != 12'h0f0) rgb_next = data_out_stone[0];
  else if (data_out_stone[1] != 12'h0f0) rgb_next = data_out_stone[1];
  else if (data_out_snake_head != 12'h0f0) rgb_next = data_out_snake_head;
  else if (data_out_snake_body[0] != 12'h0f0) rgb_next = data_out_snake_body[0];
  else if (data_out_snake_body[1] != 12'h0f0) rgb_next = data_out_snake_body[1];
  else if (data_out_snake_body[2] != 12'h0f0) rgb_next = data_out_snake_body[2];
  else if (data_out_snake_body[3] != 12'h0f0) rgb_next = data_out_snake_body[3];
  else if (data_out_snake_body[4] != 12'h0f0) rgb_next = data_out_snake_body[4];
  else if (data_out_snake_body[5] != 12'h0f0) rgb_next = data_out_snake_body[5];
  else if (data_out_snake_body[6] != 12'h0f0) rgb_next = data_out_snake_body[6];
  else if (data_out_snake_body[7] != 12'h0f0) rgb_next = data_out_snake_body[7];
  else if (data_out_snake_tail != 12'h0f0) rgb_next = data_out_snake_tail;
  else if (data_out_food != 12'h0f0) rgb_next = data_out_food;
  else if (data_out_number[0] != 12'h0f0) rgb_next = data_out_number[0];
  else if (data_out_number[1] != 12'h0f0) rgb_next = data_out_number[1];
  else if (data_out_number[2] != 12'h0f0) rgb_next = data_out_number[2];
  else if (data_out_number[3] != 12'h0f0) rgb_next = data_out_number[3];
  else if (data_out_wall[0] != 12'h0f0) rgb_next = data_out_wall[0];
  else if (data_out_wall[1] != 12'h0f0) rgb_next = data_out_wall[1];
  else if (data_out_wall[2] != 12'h0f0) rgb_next = data_out_wall[2];
  else if (data_out_wall[3] != 12'h0f0) rgb_next = data_out_wall[3];
  else if (data_out_wall[4] != 12'h0f0) rgb_next = data_out_wall[4];
  else if (data_out_wall[5] != 12'h0f0) rgb_next = data_out_wall[5];
  else if (data_out_shell != 12'h0f0) rgb_next = data_out_shell;
  else if (data_out_mute != 12'h0f0) rgb_next = data_out_mute;
  else if (data_out_bg != 12'h0f0)rgb_next = data_out_bg; // RGB value at (pixel_x, pixel_y)
  else rgb_next = 12'h000;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule