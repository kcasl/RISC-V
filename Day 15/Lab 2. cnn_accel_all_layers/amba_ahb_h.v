//`defines specified by AMBA 2.0 AHB
//for masters
//the maximum number of masters
`define N_MAX_MASTER 16
//W_MAX_MASTERS log2(N_MAX_MASTER)
`define W_MAX_MASTER 4
//the width of signals
`define W_TRANS 2
	`define TRANS_IDLE 2'h0
	`define TRANS_BUSY 2'h1
	`define TRANS_NONSEQ 2'h2
	`define TRANS_SEQ 2'h3
`ifdef H264E_WA_USE_CUSTOMIZED_HBURST
`define W_BURST 4
	`define BURST_SINGLE 4'h0
	`define BURST_INCR   4'h1
	`define BURST_WRAP4  4'h2
	`define BURST_INCR4  4'h3
	`define BURST_WRAP8  4'h4
	`define BURST_INCR8  4'h5
	`define BURST_WRAP16 4'h6
	`define BURST_INCR16 4'h7
	`define BURST_INCR2  4'h8
	`define BURST_INCR3  4'h9
	`define BURST_INCR9  4'ha
`else
`define W_BURST 3 
	`define BURST_SINGLE 3'h0
	`define BURST_INCR   3'h1
	`define BURST_WRAP4  3'h2
	`define BURST_INCR4  3'h3
	`define BURST_WRAP8  3'h4
	`define BURST_INCR8  3'h5
	`define BURST_WRAP16 3'h6
	`define BURST_INCR16 3'h7
`endif
`define W_SIZE 3
	`define SIZE_BYTE 3'h0
	`define SIZE_HALFWORD 3'h1
	`define SIZE_WORD 3'h2
	`define SIZE_DWORD 3'h3
	`define SIZE_DDWORD 3'h4
	`define SIZE_TDWORD 3'h5
	`define SIZE_QDWORD 3'h6
	`define SIZE_FDWORD 3'h7
`define W_PROT 4
	//HPROT[0]
	`define IX_PROT_DATA 0
	`define PROT_OPCODE 1'b0
	`define PROT_DATA 1'b1
	//HPROT[1]
	`define IX_PROT_PREVILEGED 1
	`define PROT_USER 1'b0
	`define PROT_PREVILEGED 1'b1
	//HPROT[2]
	`define IX_PROT_BUF 2
	`define PROT_UNBUF 1'b0
	`define PROT_BUF 1'b1
	//HPROT[3]
	`define IX_PROT_CACHEABLE 3
	`define PROT_NOTCACHE 1'b0
	`define PROT_CACHEABLE 1'b1
`define W_RESP 2
	`define RESP_OKAY 0
	`define RESP_ERROR 1
	`define RESP_RETRY 2
	`define RESP_SPLIT 3

//The address range of an AHB slave can not excess 1kB boundary. 
`define W_MAX_LOCAL_ADDR 25
