module cpu(clk);
	input clk;
	//get instruction Inst
	wire equal, sign, nPC_sel, RegWr, RegDst, ExtOp, ALUSrc, MemWr, MemToReg;
	wire [2:0] ALUctr;
	control(Inst[31:26], Inst[5:0], Inst[25:21], Inst[20:16], Inst[15:11], Inst[15:0], equal, sign, nPC_sel, RegWr, RegDst, ExtOp, ALUSrc, ALUctr, MemWr, MemToReg);
	
	//datapath, 
endmodule

module control(Op, Fun, Rt, Rs, Rd, Imm16, equal, sign, nPC_sel, RegWr, RegDst, ExtOp, ALUSrc, ALUctr, MemWr, MemtoReg);
	input [5:0] Op;
	input [5:0] Fun;
	input [4:0] Rt;
	input [4:0] Rs;
	input [4:0] Rd;
	input [15:0] Imm16;
	input equal, sign;
	output nPC_sel, RegWr, RegDst, ALUSrc, MemWr, MemtoReg;
	output ExtOp;
	output [2:0] ALUctr;
	
	
	wire [14:0] func; //[add, addi, addu, sub, subu, and, or, sll, lw, sw, beq, bne, bgtz, slt, sltu]
	decode_func getfunc(Op, Fun, func, RegDst);
	get_ALUctr getaluctr(func, ALUctr);
	
	//nPC_sel branches
	wire beq_t;
	and_gate beqand(func[4], equal, beq_t);
	wire bne_t, not_equal;
	not_gate noteq(equal, not_equal);
	and_gate bneand(func[3], not_equal, bne_t);
	wire bgtz_t, ltorz, not_ltorz;
	or_gate orltorz(equal, sign, ltorz);
	not_gate notltorz(ltorz, not_ltorz);
	and_gate bgtzand(func[2], not_ltorz);
	wire branch_or1;
	or_gate branchor1(beq_t, bne_t, branch_or1);
	or_gate branchor2(branch_or1, bgtz_t, nPC_sel);
	
	//RegWr: add, addi, addu, sub, subu, and, or, sll, lw, slt, sltu (not sw, bew, bne, bgtz)
	wire [2:0] reg_wr_mid;
	or_gate regor1(func[2], func[3], reg_wr_mid[1]);
	or_gate regor2(func[4], func[5], reg_wr_mid[0]);
	or_gate regor3(reg_wr_mid[0], reg_wr_mid[1], reg_wr_mid[2]);
	not_gate regwrnot(reg_wr_mid[2], RegWr);
	
	//ExtOp: addi = 1, lw, sw = 1
	wire extop_mid;
	or_gate extopor1(func[5], func[6], extop_mid);
	or_gate extopor2(extop_mid, func[13], ExtOp);
	
	//ALUSrc (immediate?): not RegDst
	not_gate alusrcnot(RegDst, ALUSrc);
	
	//MemWr: only on sw
	assign MemWr = func[5];
	
	//MemToReg: only on lw
	assign MemToReg = func[6];
endmodule

module get_ALUctr(func, ALUctr);
	input [5:0] func;
	output [2:0] ALUctr;
	//maybe figure out how to use ALUCU?
	//ALU ALUctr 0=and, 1=or, 2=fa, 3=slt_signed, 4=fa_u, 5=sll, 6=sub, 7=slt
	//ALU(ctrl, A,B,shamt,cout,ovf,ze,R)
	
	//ALU and (000): and
	wire alu_and;
	assign alu_and = func[9];
	
	//ALU or (001): or
	wire alu_or;
	assign alu_or = func[8];
	
	//ALU fa (010): add, addi
	wire alu_fa;
	or_gate oradd(func[14], func[13], alu_fa);
	
	//ALU slt_signed (011): slt
	wire alu_slt;
	assign alu_slt = func[1];
	
	//ALU fa_u (100): addu
	wire alu_fau;
	assign alu_fau = func[12];
	
	//ALU sll (101): sll
	wire alu_sll;
	assign alu_sll = func[7];
	
	//ALU sub (110): sub, subu, beq, bne, bgtz
	wire alu_sub;
	wire [2:0] alu_sub_mid;
	or_gate orsub1(func[11], func[10], alu_sub_mid[2]);
	or_gate orsub2(func[4], func[3], alu_sub_mid[1]);
	or_gate orsub3(func[2], alu_sub_mid[2], alu_sub_mid[0]);
	or_gate orsub4(alu_sub_mid[1], alu_sub_mid[0], alu_sub);
	
	//ALU slt (111): sltu
	wire alu_sltu;
	assign alu_sltu = func[0];
	
	//encode
	wire [1:0] or_wires_1;
	or_gate orenc1(alu_or, alu_slt, or_wires_1[1]);
	or_gate orenc2(alu_sll, alu_sltu, or_wires_1[0]);
	or_gate orenc3(or_wires_1[1], or_wires_1[0], ALUctr[0]);
	
	wire [1:0] or_wires_2;
	or_gate orenc4(alu_fa, alu_slt, or_wires_2[1]);
	or_gate orenc5(alu_sub, alu_slt, or_wires_2[0]);
	or_gate orenc6(or_wires_2[1], or_wires_2[0], ALUctr[1]);
	
	wire [1:0] or_wires_3;
	or_gate orenc7(alu_fau, alu_sll, or_wires_3[1]);
	or_gate orenc8(alu_sub, alu_sltu, or_wires_3[0]);
	or_gate orenc9(or_wires_3[1], or_wires_3[0], ALUctr[2]);
endmodule

module decode_func(Op, Fun, func, RegDst);
	input [5:0] Op;
	input [5:0] Fun;
	output [14:0] func; //[add, addi, addu, sub, subu, and, or, sll, lw, sw, beq, bne, bgtz, slt, sltu]
	output RegDst;
	
	wire r_type;
	set_if_eq setr(Op, 6'b000000, r_type);
	assign RegDst = r_type
	
	wire [8:0] r_func; //[add, addu, sub, subu, and, or, sll, slt, sltu]
	set_if_eq addr(Fun, 6'b100000, r_func[8]);
	set_if_eq addur(Fun, 6'b100001, r_func[7]);
	set_if_eq subr(Fun, 6'b100010, r_func[6]);
	set_if_eq subur(Fun, 6'b100011, r_func[5]);
	set_if_eq andr(Fun, 6'b100100, r_func[4]);
	set_if_eq orr(Fun, 6'b100101, r_func[3]);
	set_if_eq sllr(Fun, 6'b000000, r_func[2]);
	set_if_eq sltr(Fun, 6'b101010, r_func[1]);
	set_if_eq sltur(Fun, 6'b101011, r_func[0]);
	
	mux addmux(r_type, 1'b0, r_func[8], func[14]);
	set_if_eq addif(Op, 6'b001000, func[13]);
	mux addumux(r_type, 1'b0, r_func[7], func[12]);
	mux submux(r_type, 1'b0, r_func[6], func[11]);
	mux subumux(r_type, 1'b0, r_func[5], func[10]);
	mux andmux(r_type, 1'b0, r_func[4], func[9]);
	mux ormux(r_type, 1'b0, r_func[3], func[8]);
	mux sllmux(r_type, 1'b0, r_func[2], func[7]);
	set_if_eq lwf(Op, 6'b100011, func[6]);
	set_if_eq swf(Op, 6'b101011, func[5]);
	set_if_eq beqf(Op, 6'b000100, func[4]);
	set_if_eq bnef(Op, 6'b000101, func[3]);
	set_if_eq bgtzf(Op, 6'b000111, func[2]);
	mux sltmux(r_type, 1'b0, r_func[1], func[1]);
	mux sltumux(r_type, 1'b0, r_func[0], func[0]);
endmodule

module set_if_eq(x, y, z);
	input [5:0] x;
	input [5:0] y;
	output z;
	wire [5:0] xored;
	
	genvar i;
	generate
	for (i = 0; i < 6; i = i + 1) begin
		xor_gate xorl(x[i], y[i], xored[i]);
	end
	endgenerate
	
	wire [4:0] ored;
	or_gate or1(xored[0], xored[1], ored[0]);
	or_gate or2(xored[2], xored[3], ored[1]);
	or_gate or3(xored[4], xored[5], ored[2]);
	or_gate or4(ored[0], ored[1], ored[3]);
	or_gate or5(ored[2], ored[3], ored[4]);
	
	not_gate not1(ored[4], z);
endmodule