`ifndef AHB_DEFINES
  `define AHB_DEFINES
  package ahb;
  
  typedef enum logic [2:0]{BYTE,HALFFORD,WORD,BIT_64,FOUR_WORD,EIGHT_WORD,BIT_512,BIT_1024} type_hsize;
  typedef enum logic [2:0]{SINGLE,INCR,WRAP4,INCR4,WRAP8,INCR8,WRAP16,INCR16} type_hburst;
  typedef enum logic [1:0]{IDLE,BUSY,NONSEQ,SEQ} type_htrans;
  typedef enum logic {OKAY,ERROR} type_hresp;

  function logic[31:0] addr_next(input logic[31:0] current,input type_hburst burst);
  case(burst)
      SINGLE:
          addr_next = current + 4;
      INCR:
          addr_next = current + 4;
      INCR4:
          addr_next = current + 4;
      WRAP4:  // 4*4 = 16 byte boundries
          addr_next = {current[31:4],{current[3:0] + 4'd4}};
      INCR8:
          addr_next = current + 4;
      WRAP8: // 4 * 8 = 32 bytes boundries
          addr_next = {current[31:5],{current[4:0] + 5'd4}};
      INCR16:
          addr_next = current + 4;
      WRAP16: // 4 * 16 = 64 bytes boundries
          addr_next = {current[31:6],{current[5:0] + 6'd4}};
  endcase
endfunction

endpackage
`endif