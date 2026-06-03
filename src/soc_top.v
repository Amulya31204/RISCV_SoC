module soc_top (
    input  wire clk,
    input  wire rst,
    output wire uart_tx_pin
);

reg [31:0] mem [0:1023];
initial $readmemh("firmware.hex", mem);

wire        mem_valid;
wire        mem_instr;
reg         mem_ready;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [3:0]  mem_wstrb;
reg  [31:0] mem_rdata;

reg  [7:0]  uart_data;
reg         uart_start;
wire        uart_busy;

picorv32 #(
    .STACKADDR(32'h00000400),
    .PROGADDR_RESET(32'h00000000),
    .BARREL_SHIFTER(1),
    .COMPRESSED_ISA(0),
    .ENABLE_MUL(0),
    .ENABLE_DIV(0)
) cpu (
    .clk       (clk),
    .resetn    (~rst),
    .mem_valid (mem_valid),
    .mem_instr (mem_instr),
    .mem_ready (mem_ready),
    .mem_addr  (mem_addr),
    .mem_wdata (mem_wdata),
    .mem_wstrb (mem_wstrb),
    .mem_rdata (mem_rdata)
);

always @(posedge clk) begin
    mem_ready  <= 0;
    uart_start <= 0;

    if (mem_valid && !mem_ready) begin
        if (mem_addr == 32'h10000000) begin
            if (mem_wstrb != 0) begin
                uart_data  <= mem_wdata[7:0];
                uart_start <= 1;
            end
            mem_rdata <= {31'b0, ~uart_busy};
            mem_ready <= 1;
        end
        else if (mem_addr < 32'h00001000) begin
            if (mem_wstrb[0]) mem[mem_addr[11:2]][7:0]   <= mem_wdata[7:0];
            if (mem_wstrb[1]) mem[mem_addr[11:2]][15:8]  <= mem_wdata[15:8];
            if (mem_wstrb[2]) mem[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) mem[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
            mem_rdata <= mem[mem_addr[11:2]];
            mem_ready <= 1;
        end
    end
end

uart_tx #(
    .CLK_FREQ (100_000_000),
    .BAUD_RATE(115200)
) uart (
    .clk     (clk),
    .rst     (rst),
    .data_in (uart_data),
    .tx_start(uart_start),
    .tx      (uart_tx_pin),
    .tx_busy (uart_busy)
);

endmodule
