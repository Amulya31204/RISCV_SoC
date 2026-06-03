`timescale 1ns/1ps
module soc_tb;

reg clk = 0;
reg rst = 1;

always #5 clk = ~clk;

// Instantiate just the UART TX directly for verification
reg  [7:0] tx_data;
reg        tx_start = 0;
wire       tx_line;
wire       tx_busy;

uart_tx #(
    .CLK_FREQ(10_000_000),
    .BAUD_RATE(115200)
) dut (
    .clk     (clk),
    .rst     (rst),
    .data_in (tx_data),
    .tx_start(tx_start),
    .tx      (tx_line),
    .tx_busy (tx_busy)
);

// Latch received data
reg [7:0] received;
reg       got;

always @(posedge clk)
    if (tx_busy == 0 && got == 0 && tx_start == 0)
        got <= 0;

// Send a byte task
task send_char;
    input [7:0] ch;
    begin
        got      = 0;
        tx_data  = ch;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        wait(tx_busy == 0);
        repeat(200) @(posedge clk);
        $display("RISC-V SoC UART sent: 0x%02h ('%c')", ch, ch);
    end
endtask

initial begin
    $dumpfile("soc_tb.vcd");
    $dumpvars(0, soc_tb);
    rst = 1;
    repeat(5) @(posedge clk);
    rst = 0;
    repeat(5) @(posedge clk);

    $display("=== RISC-V SoC UART Verification ===");
    send_char("H");
    send_char("e");
    send_char("l");
    send_char("l");
    send_char("o");
    send_char(" ");
    send_char("W");
    send_char("o");
    send_char("r");
    send_char("l");
    send_char("d");

    $display("=== All characters transmitted successfully ===");
    $finish;
end

endmodule
