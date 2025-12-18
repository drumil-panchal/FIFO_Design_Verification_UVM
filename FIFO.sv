`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module FIFO(
    input clk,
    input rst,
    input wr,
    input rd,
    input [7:0] din,
    output reg [7:0] dout,                  //reg is added as we want to directly work on dout
    output empty,
    output full,
    output logic overflow,
    output logic underflow
    );
    
    reg [3:0] wptr = 0, rptr = 0;           //pts to indicate no. of times writes and reads
    reg [4:0] cnt = 0;                      //5 bit to make sure last location in fifo correctly read and written
    reg [7:0] mem [15:0];                   //8 bit and size 16 elements
    
    always @(posedge clk)
        begin
            if(rst == 1)
                begin
                    wptr <= 0;
                    rptr <= 0;
                    cnt <= 0;
                    dout <= 0;
                    overflow <= 0;
                    underflow <= 0;
                end
                
            else
                begin
                    overflow <= 0;      //default: clear flags
                    underflow <= 0;
                    
                    if(wr && !rd) begin         //write
                        if(!full) begin
                            mem[wptr] <= din;
                            wptr <= wptr + 1;
                            cnt <= cnt + 1;
                        end
                        else begin
                            overflow <= 1'b1;
                        end
                    end
                    
                    else if(rd && !wr) begin
                        if(!empty) begin
                            dout <= mem[rptr];
                            rptr <= rptr + 1;
                            cnt <= cnt - 1;
                        end
                        else begin
                            underflow <= 1'b1;
                        end
                    end
                    
                    else if (wr && rd) begin
                        if (!full && !empty) begin
                            mem[wptr] <= din;
                            dout <= mem[rptr];
                            wptr <= wptr + 1;
                            rptr <= rptr + 1; 
                            cnt <= cnt;                  
                        end
                        else if (full) begin
                            overflow <= 1'b1; // read ok, write blocked
                            dout <= mem[rptr];
                            rptr <= rptr + 1;
                            cnt <= cnt - 1;                 
                        end
                        else if (empty) begin
                            underflow <= 1'b1; // write ok, read blocked
                            mem[wptr] <= din;
                            wptr <= wptr + 1;
                            cnt <= cnt + 1;                   
                        end
                    end
                end          
        end
        
        
    assign empty = (cnt == 0) ? 1'b1 : 1'b0;    //empty flag is set if count = 0
    assign full = (cnt == 16) ? 1'b1 : 1'b0;    //efull flag is set if count = 16
    
endmodule


interface fifo_if;
    logic clk, rd, wr, rst;
    logic empty, full;
    logic [7:0] din;
    logic [7:0] dout;
    logic overflow;
    logic underflow;
endinterface



























