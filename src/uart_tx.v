module uart_tx #(
  parameter CLK_FREQ  = 100_000_000,
  parameter BAUD_RATE = 9600
)(
  input  wire       clk, rst,
  input  wire [7:0] data_in,
  input  wire       tx_start,
  output reg        tx,
  output reg        tx_busy
);
  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  reg [15:0] clk_count;
  reg [3:0]  bit_index;
  reg [9:0]  tx_shift;  // start + 8 data + stop
  localparam IDLE=0, START=1, DATA=2, STOP=3;
  reg [1:0] state;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state<=IDLE; tx<=1; tx_busy<=0;
      clk_count<=0; bit_index<=0;
    end else begin
      case (state)
        IDLE: begin
          tx<=1; tx_busy<=0;
          if (tx_start) begin
            tx_shift<={1'b1, data_in, 1'b0};
            state<=START; clk_count<=0; bit_index<=0; tx_busy<=1;
          end
        end
        START: begin
          tx<=tx_shift[0];
          if (clk_count==CLKS_PER_BIT-1) begin
            clk_count<=0; tx_shift<=tx_shift>>1; bit_index<=1; state<=DATA;
          end else clk_count<=clk_count+1;
        end
        DATA: begin
          tx<=tx_shift[0];
          if (clk_count==CLKS_PER_BIT-1) begin
            clk_count<=0; tx_shift<=tx_shift>>1;
            if (bit_index==8) state<=STOP;
            else bit_index<=bit_index+1;
          end else clk_count<=clk_count+1;
        end
        STOP: begin
          tx<=1;
          if (clk_count==CLKS_PER_BIT-1) begin
            state<=IDLE; clk_count<=0; tx_busy<=0;
          end else clk_count<=clk_count+1;
        end
      endcase
    end
  end
endmodule
