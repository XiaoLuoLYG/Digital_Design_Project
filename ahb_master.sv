`include "ahb.sv"
/* verilator lint_off IMPORTSTAR */
import ahb::*;
/* verilator lint_off IMPORTSTAR */
module ahb_master(
        // system signals
        input   logic                   HCLK,
        input   logic                   HRESETN,
        // user signals
        input   logic                   user_req,
        input   logic                   user_rw,
        input   type_hsize              user_size,
        input   type_hburst             user_burst,
        input   logic       [31:0]      user_addr,
        output  logic                   user_fifo_ren,
        output  logic                   user_fifo_wen,
        input   logic       [31:0]      user_fifo_data_i,
        output  logic       [31:0]      user_fifo_data_o,
        // AHB signals
        input   logic                   HRESP,
        input   logic                   HREADY,
        input   logic       [31:0]      HRDATA,
        output  logic       [31:0]      HADDR,
        output  type_hburst             HBURST,
        output  logic                   HMASTLOCK,
        output  logic       [6:0]       HPROT,
        output  type_hsize              HSIZE,
        output  type_htrans             HTRANS,
        output  logic       [31:0]      HWDATA,
        output  logic                   HWRITE
    );


    typedef enum logic [1:0] {S_IDLE,S_START,S_TRANS,S_RETRY} State;

    State                           state;
    type_hsize                      size_in;
    type_hburst                     burst_in;
    logic                           rd_wr_in;
    logic [31:0]                    addr_in;
    logic [31:0]                    addr_current;
    logic [4:0]                     cnt;
    logic [4:0]                     burst_beats;

    `define HMASTERLOCK__NOLOCK     1'b0
    `define HPROT__NOPROT           7'd0

    `define HSIZE__32BITS           3'b010
    `define READ_TRANSCATION        1'b0
    `define WRITE_TRANSCATION       1'b1

    assign HMASTLOCK                = `HMASTERLOCK__NOLOCK;
    assign HPROT                    = `HPROT__NOPROT;

    assign HWDATA                   = user_fifo_data_i;
    assign user_fifo_data_o         = HRDATA;

    always@(posedge HCLK) begin
        if(!HRESETN)
            state <= S_IDLE;
        
        case(state)
            S_IDLE : begin
                HTRANS              <= IDLE;
                if(user_req) begin
                    user_fifo_ren   <= 0;
                    user_fifo_wen   <= 0;
                    size_in         <= user_size;
                    addr_in         <= user_addr;
                    burst_in        <= user_burst;
                    rd_wr_in        <= user_rw;
                    addr_current    <= user_addr;
                    cnt             <= 0;
                    state           <= S_START;
                end
            end

            S_START: begin
                HTRANS              <= NONSEQ;
                HSIZE               <= size_in;
                HBURST              <= burst_in;
                HADDR               <= addr_current;
                HWRITE              <= rd_wr_in == `WRITE_TRANSCATION ? 1:0;
                if(HREADY) begin
                    // get next data
                    user_fifo_wen   <= rd_wr_in == `READ_TRANSCATION  ? 1:0;
                    user_fifo_ren   <= rd_wr_in == `WRITE_TRANSCATION ? 1:0;
                    addr_current    <= addr_next(addr_current,burst_in);
                    HADDR           <= addr_next(addr_current,burst_in);
                    // change state
                    cnt             <= cnt + 1;
                    state           <= S_TRANS;
                end else begin
                    if(HRESP == ERROR)
                        state       <= S_RETRY;
                end
            end

            S_TRANS: begin
                HTRANS              <= (cnt < burst_beats-1) ?  SEQ : IDLE;
                state               <= cnt == burst_beats ? S_IDLE : S_TRANS;
                if(HREADY) begin
                    // get next addr
                    addr_current    <= addr_next(addr_current,burst_in);
                    HADDR           <= addr_next(addr_current,burst_in);
                    user_fifo_wen       <= (rd_wr_in == `READ_TRANSCATION && cnt < burst_beats)  ? 1:0;
                    user_fifo_ren       <= (rd_wr_in == `WRITE_TRANSCATION && cnt < burst_beats) ? 1:0;
                    // get next data
                    // change state
                    cnt             <= cnt + 1;
                end else begin
                    if(HRESP == ERROR) 
                        state    <= S_RETRY;
                end
            end

            S_RETRY: begin
                addr_current     <= addr_in;
                cnt              <= 0;
                state            <= S_START;
            end

            default:
                state            <= S_IDLE;
        endcase
    end

    always_comb begin
        case(burst_in)
            SINGLE:
                burst_beats = 1;
            INCR:
                burst_beats = 1;
            INCR4:
                burst_beats = 4;
            WRAP4:
                burst_beats = 4;
            INCR8:
                burst_beats = 8;
            WRAP8:
                burst_beats = 8;
            INCR16:
                burst_beats = 16;
            WRAP16:
                burst_beats = 16;
        endcase
    end


endmodule
