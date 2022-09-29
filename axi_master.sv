// Burst types
`define AXI_BURST_TYPE_FIXED                                2'b00               //突发类型  FIFO
`define AXI_BURST_TYPE_INCR                                 2'b01               //ram
`define AXI_BURST_TYPE_WRAP                                 2'b10
// Access permissions
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100
// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
// Memory types (AW)
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

`define AXI_SIZE_BYTES_1                                    3'b000                //突发宽度一个数据的宽度
`define AXI_SIZE_BYTES_2                                    3'b001
`define AXI_SIZE_BYTES_4                                    3'b010
`define AXI_SIZE_BYTES_8                                    3'b011
`define AXI_SIZE_BYTES_16                                   3'b100
`define AXI_SIZE_BYTES_32                                   3'b101
`define AXI_SIZE_BYTES_64                                   3'b110
`define AXI_SIZE_BYTES_128                                  3'b111

module axi_master # (
    parameter RW_DATA_WIDTH     = 64,
    parameter RW_ADDR_WIDTH     = 32,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_STRB_WIDTH    = AXI_DATA_WIDTH/8,
    parameter AXI_USER_WIDTH    = 1
  )(
    input                               clock,
    input                               reset,

    input                               rw_valid_i,         //IF&MEM输入信号
    output                              rw_ready_o,         //IF&MEM输入信号
    output reg [RW_DATA_WIDTH-1:0]      data_read_o,        //IF&MEM输入信号
    input  [RW_DATA_WIDTH-1:0]          rw_w_data_i,        //IF&MEM输入信号
    input  [RW_ADDR_WIDTH-1:0]          rw_addr_i,          //IF&MEM输入信号
    input  [7:0]                        rw_size_i,          //IF&MEM输入信号
    input  [7:0]                        rw_len_i,           // burst 次数
    input                               read_req,           // 读请求
    input                               write_req,          // 写请求

    // external fifo interface
    output   logic                        rfifo_wen,
    output   logic                        rfifo_ren,
    // Advanced eXtensible Interface
    input                               axi_aw_ready_i,
    output                              axi_aw_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o,
    output [2:0]                        axi_aw_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_aw_user_o,
    output [7:0]                        axi_aw_len_o,
    output [2:0]                        axi_aw_size_o,
    output [1:0]                        axi_aw_burst_o,
    output                              axi_aw_lock_o,
    output [3:0]                        axi_aw_cache_o,
    output [3:0]                        axi_aw_qos_o,
    output [3:0]                        axi_aw_region_o,

    input                               axi_w_ready_i,
    output                              axi_w_valid_o,
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o,
    output [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_o,
    output                              axi_w_last_o,
    output [AXI_USER_WIDTH-1:0]         axi_w_user_o,

    output                              axi_b_ready_o,
    input                               axi_b_valid_i,
    /* verilator lint_off UNUSED */
    input  [1:0]                        axi_b_resp_i,
    /* verilator lint_off UNUSED */
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_b_user_i,

    input                               axi_ar_ready_i,
    output                              axi_ar_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o,
    output [2:0]                        axi_ar_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_ar_user_o,
    output [7:0]                        axi_ar_len_o,
    output [2:0]                        axi_ar_size_o,
    output [1:0]                        axi_ar_burst_o,
    output                              axi_ar_lock_o,
    output [3:0]                        axi_ar_cache_o,
    output [3:0]                        axi_ar_qos_o,
    output [3:0]                        axi_ar_region_o,

    output logic                        axi_r_ready_o,
    input                               axi_r_valid_i,
    input  [1:0]                        axi_r_resp_i,
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i,
    input                               axi_r_last_i,
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_r_user_i
  );

  // ------------------State Machine------------------TODO
  localparam AXI_READ  = 1'd0;
  localparam AXI_WRITE = 1'd1;

  // 写通道状态切换
  localparam  S_WR_IDLE   = 3'd0;
  localparam  S_WA_WAIT   = 3'd1;
  localparam  S_WA_START  = 3'd2;
  localparam  S_WD_WAIT   = 3'd3;
  localparam  S_WD_PROC   = 3'd4;
  localparam  S_WR_WAIT   = 3'd5;
  localparam  S_WR_DONE   = 3'd6;

  reg [2:0] wr_state;
  reg [31:0] reg_wr_addrs;
  reg reg_awvalid,reg_wvalid,reg_w_last;
  reg [7:0] reg_w_len;
  reg [7:0] reg_w_stb;

  always @(posedge clock) begin
    if(reset) begin
      wr_state    <= S_WR_IDLE;
      reg_wr_addrs <= 32'd0;
      reg_awvalid <= 1'b0;
      reg_wvalid  <= 1'b0;
      reg_w_last  <= 1'b0;
      reg_w_len   <= 8'd0;
    end
    else begin
      case (wr_state)
        S_WR_IDLE: begin
          if(rw_valid_i && write_req) begin
            wr_state     <= S_WA_WAIT;
            reg_wr_addrs <= rw_addr_i;
            reg_w_len    <= rw_len_i - 8'd1;
          end
          reg_awvalid <= 1'b0;
          reg_wvalid  <= 1'b0;
        end
        S_WA_WAIT: begin
          wr_state <= S_WA_START;
        end
        S_WA_START: begin
          wr_state <= S_WD_WAIT;
          reg_awvalid <= 1'b1;
        end
        S_WD_WAIT: begin
          if(axi_aw_ready_i) begin
            wr_state <= S_WD_PROC;
            reg_awvalid <= 1'b0;
          end
        end
        S_WD_PROC: begin
          reg_wvalid  <= 1'b1;
          if(axi_w_ready_i) begin
            rfifo_ren <= reg_wvalid ? 1:0;
            if(reg_w_len == 8'd0) begin
              wr_state <= S_WR_WAIT;
              reg_w_last <= 1'b1;
            end
            else begin
              reg_w_len <= reg_w_len - 8'd1;
            end
          end
        end
        S_WR_WAIT: begin
          rfifo_ren <= 0;
          reg_w_last <= 1'b0;
          if(axi_b_valid_i) begin
            wr_state <= S_WR_DONE;
          end
        end
        S_WR_DONE: begin
          wr_state <= S_WR_IDLE;
        end
        default: begin
          wr_state <= S_WR_IDLE;
        end
      endcase
    end
  end

  // 读通道状态切换
  localparam S_RD_IDLE = 3'd0;
  localparam S_RA_WAIT = 3'd1;
  localparam S_RA_START = 3'd2;
  localparam S_RD_WAIT = 3'd3;
  localparam S_RD_PROC = 3'd4;
  localparam S_RD_DONE = 3'd5;

  reg [2:0] rd_state;
  reg [31:0] reg_rd_addrs;
  reg [7:0] reg_rd_len;
  reg reg_arvalid;

  always @(posedge clock) begin
    if(reset) begin
      rd_state <= S_RD_IDLE;
      reg_rd_addrs <= 32'd0;
      reg_rd_len <= 8'd0;
      reg_arvalid <= 1'b0;
    end
    else begin
      case(rd_state)
        S_RD_IDLE: begin
          if(rw_valid_i && read_req) begin
            rd_state <= S_RA_WAIT;
            reg_rd_addrs <= rw_addr_i;
            reg_rd_len <= rw_len_i - 8'd1;
          end
          reg_arvalid <= 1'b0;
        end
        S_RA_WAIT: begin
          rd_state <= S_RA_START;
        end
        S_RA_START: begin
          rd_state <= S_RD_WAIT;
          reg_arvalid <= 1'b1;
        end
        S_RD_WAIT: begin
          if(axi_ar_ready_i) begin
            rd_state <= S_RD_PROC;
            reg_arvalid <= 1'b0;
            axi_r_ready_o <= 1;
          end
        end
        S_RD_PROC: begin
          if(axi_r_valid_i) begin
            data_read_o <= axi_r_data_i;
            rfifo_wen   <= 1;
            if(axi_r_last_i) begin
              rd_state <= S_RD_DONE;
              axi_r_ready_o <= 0;
            end
          end
        end
        S_RD_DONE: begin
          rd_state <= S_RD_IDLE;
          rfifo_wen <= 0;
        end
        default: begin
          rd_state <= S_RD_IDLE;
        end
      endcase
    end
  end

  assign rw_ready_o = rd_state == S_RD_IDLE && wr_state == S_WR_IDLE;

  // ------------------Write Transaction------------------
  parameter AXI_SIZE      = $clog2(AXI_DATA_WIDTH / 8);
  wire [AXI_ID_WIDTH-1:0] axi_id      = {AXI_ID_WIDTH{1'b1}};
  wire [AXI_USER_WIDTH-1:0] axi_user  = {AXI_USER_WIDTH{1'b0}};
  wire [7:0] axi_len      =  8'b0 ;
  wire [2:0] axi_size     = AXI_SIZE[2:0];
  // 写地址通道  以下没有备注初始化信号的都可能是你需要产生和用到的
  assign axi_aw_valid_o   = reg_awvalid;
  assign axi_aw_addr_o    = reg_wr_addrs;
  assign axi_aw_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;  //初始化信号即可
  assign axi_aw_id_o      = axi_id;                                                                           //初始化信号即可
  assign axi_aw_user_o    = axi_user;                                                                         //初始化信号即可
  assign axi_aw_len_o     = reg_w_len;
  assign axi_aw_size_o    = axi_size;
  assign axi_aw_burst_o   = `AXI_BURST_TYPE_INCR;
  assign axi_aw_lock_o    = 1'b0;                                                                             //初始化信号即可
  assign axi_aw_cache_o   = `AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE;                                  //初始化信号即可
  assign axi_aw_qos_o     = 4'h0;                                                                             //初始化信号即可
  assign axi_aw_region_o  = 4'h0;                                                                             //初始化信号即可

  // 写数据通道
  assign axi_w_valid_o    = reg_wvalid;
  assign axi_w_data_o     = rw_w_data_i;
  assign axi_w_strb_o     = rw_size_i;
  assign axi_w_last_o     = reg_w_last;
  assign axi_w_user_o     = axi_user;                                                                         //初始化信号即可

  // 写应答通道
  assign axi_b_ready_o    = axi_b_valid_i;


  // ------------------Read Transaction------------------

  // Read address channel signals
  assign axi_ar_valid_o   = reg_arvalid;
  assign axi_ar_addr_o    = reg_rd_addrs;
  assign axi_ar_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;  //初始化信号即可
  assign axi_ar_id_o      = axi_id;                                                                           //初始化信号即可
  assign axi_ar_user_o    = axi_user;                                                                         //初始化信号即可
  assign axi_ar_len_o     = reg_rd_len;
  assign axi_ar_size_o    = axi_size;
  assign axi_ar_burst_o   = `AXI_BURST_TYPE_INCR;
  assign axi_ar_lock_o    = 1'b0;                                                                             //初始化信号即可
  assign axi_ar_cache_o   = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;                                 //初始化信号即可
  assign axi_ar_qos_o     = 4'h0;                                                                             //初始化信号即可
  assign axi_ar_region_o = 4'h0;


endmodule
