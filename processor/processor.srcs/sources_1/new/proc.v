`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2024 17:25:49
// Design Name: 
// Module Name: proc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module proc(input clk1,input clk2);
reg [31:0] pc,if_id_ir,if_id_npc;  //npc is a temporary register which stores the value of the next instr at each stage. it is done because in case of a branch instr we may have to go to a different instr and cannot go on with our current iteration
reg [31:0] id_ex_npc,id_ex_a,id_ex_b,id_ex_ir,id_ex_imm;
reg [2:0] id_ex_type,ex_mem_type,mem_wb_type;
reg [31:0] ex_mem_ir,ex_mem_aluout,ex_mem_b;
reg ex_mem_cond;
reg [31:0] mem_wb_aluout,mem_wb_ir,mem_wb_lmd;
reg [31:0] bank [0:31];
reg [31:0] mem [0:1023];
parameter add=6'b000000,sub=6'b000001,AND=6'b000010,OR=6'b000011,slt=6'b000100,mul=6'b000101,hlt=6'b000110,lw=6'b000111,sw=6'b001001,addi=6'b001010,subi=6'b001011,slti=6'b001100,bneqz=6'b001101,beqz=6'b001110;
parameter rr_alu=3'b000,rm_alu=3'b001,load=3'b010,store=3'b011,branch=3'b100,halt=3'b101;
reg halted;
reg branched;

//fetch cycle
always @(posedge clk1) begin
if(halted==0) begin
if(((if_id_ir[31:26]==beqz)&&(ex_mem_cond==1))||((if_id_ir[31:26]==bneqz)&&(ex_mem_cond==0))) begin
if_id_ir<=#2 ex_mem_aluout;
branched<=#2 1;
if_id_npc<=#2 ex_mem_aluout+1;
pc<=#2 ex_mem_aluout+1;
end
else begin
if_id_ir<=#2 mem[pc];
if_id_npc<=#2 pc+1;
pc<=#2 pc+1;
end
end
end


//decode cycle
always @(posedge clk2) begin
if(halted==0) begin
id_ex_a<=bank[if_id_ir[25:21]];
id_ex_b<=bank[if_id_ir[20:16]];
id_ex_npc<=if_id_npc;
id_ex_ir<=if_id_ir;
id_ex_imm<={{16{if_id_ir[15]}},{if_id_ir[15:0]}};
end
case(if_id_ir[31:26])
add:id_ex_type<=rr_alu;
sub:id_ex_type<=rr_alu;
AND:id_ex_type<=rr_alu;
OR:id_ex_type<=rr_alu;
slt:id_ex_type<=rr_alu;
mul:id_ex_type<=rr_alu;
addi:id_ex_type<=rm_alu;
subi:id_ex_type<=rm_alu;
slti:id_ex_type<=rm_alu;
lw:id_ex_type<=load;
sw:id_ex_type<=store;
beqz:id_ex_type<=branch;
bneqz:id_ex_type<=branch;
hlt:id_ex_type<=halt;
default:id_ex_type<=halt;
endcase
end


//execute cycle
always @(posedge clk1) begin
if(halted==0) begin
ex_mem_ir<=id_ex_ir;
ex_mem_type<=id_ex_type;
branched<=0;
case(id_ex_type)
rr_alu:begin
case(id_ex_ir[31:26])
add:ex_mem_aluout<=id_ex_a+id_ex_b;
sub:ex_mem_aluout<=id_ex_a-id_ex_b;
AND:ex_mem_aluout<=id_ex_a&id_ex_b;
OR:ex_mem_aluout<=id_ex_a|id_ex_b;
slt:ex_mem_aluout<=(id_ex_a<id_ex_b)?1:0;
mul:ex_mem_aluout<=id_ex_a*id_ex_b;
default:ex_mem_aluout<=32'hxxxxxxxx;
endcase
end
rm_alu:begin
case(id_ex_ir[31:26])
addi:ex_mem_aluout<=id_ex_a+id_ex_imm;
subi:ex_mem_aluout<=id_ex_a-id_ex_imm;
slti:ex_mem_aluout<=id_ex_a<id_ex_imm;
endcase
end
load:begin
case(id_ex_ir[31:26])
lw:begin 
ex_mem_aluout<=id_ex_a+id_ex_imm;
ex_mem_b<=id_ex_b;
end
endcase
end
store:begin
case(id_ex_ir[31:26])
sw:begin 
ex_mem_aluout<=id_ex_a+id_ex_imm;
ex_mem_b<=id_ex_b;
end
endcase
end
branch: begin
ex_mem_aluout<=id_ex_npc+id_ex_imm;
ex_mem_cond<=(id_ex_a==0);
end
endcase
end
end


//memory cycle
always @(posedge clk2) begin
mem_wb_ir<=ex_mem_ir;
mem_wb_type<=ex_mem_type;
case(ex_mem_type)
rr_alu:mem_wb_aluout<=ex_mem_aluout;
rm_alu:mem_wb_aluout<=ex_mem_aluout;
load:mem_wb_lmd<=mem[ex_mem_aluout];
store:begin
if(branched==0)
mem[ex_mem_aluout]<=ex_mem_b;
end
endcase
end


//write back cycle
always @(posedge clk1) begin
if(branched==0)
case(mem_wb_type)
rr_alu:bank[mem_wb_ir[15:11]]<=mem_wb_aluout;
rm_alu:bank[mem_wb_ir[20:16]]<=mem_wb_aluout;
load:bank[mem_wb_ir[20:16]]<=mem_wb_lmd;
halt:halted<=1'b1;
endcase
end

endmodule
