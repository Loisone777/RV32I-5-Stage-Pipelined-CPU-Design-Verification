`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/17 15:45:22
// Design Name: 
// Module Name: cpu_top
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


module cpu_top(
    input wire clk,
    input wire rst,
    
    output wire        commit_valid,
    output wire [31:0] commit_pc,
    output wire [31:0] commit_instr,

    output wire        commit_rd_we,
    output wire [4:0]  commit_rd,
    output wire [31:0] commit_rd_data,

    output wire        commit_mem_we,
    output wire [31:0] commit_mem_addr,
    output wire [31:0] commit_mem_wdata
    );
    
    //========= IF stage ===========//
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    
    wire        branch_taken;
    wire [31:0] branch_target;
    wire        redirect_valid;
    wire [31:0] redirect_pc;
    wire [31:0] pc_next;
    
    // EBREAK = 32'h0010_0073
    wire halt_req;
    reg  front_halted;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            front_halted <= 1'b0;
        else if (halt_req)
            front_halted <= 1'b1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else if (redirect_valid)
            pc <= redirect_pc;
        else if (halt_req || front_halted)
            pc <= pc;
        else if (!stall)
            pc <= pc_plus4;
    end
    
    wire [31:0] if_instr;
    imem u_imem(
        .addr    (pc),
        .instr   (if_instr)
    );
    
    
    // IF/ID pipeline
    wire [31:0] id_pc,id_instr;
    wire        ifid_flush;
    wire        id_valid;
    
    assign ifid_flush = redirect_valid || halt_req || front_halted;
    
    if_id u_ifid(
        .clk        (clk),
        .rst        (rst),
        .stall      (stall), 
        .flush      (ifid_flush),   
                    
        //from if   
        .if_pc      (pc),
        .if_instr   (if_instr),
        .id_valid   (id_valid),
                    
        //to id     
        .id_pc      (id_pc),
        .id_instr   (id_instr)
    );
    
    //============ ID stage ==========
    //从指令中解析字段
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [4:0]  rs1,rs2,rd;
    wire [31:0] imm;
    wire uses_rs1;
    wire uses_rs2;
    
    decoder u_dec(
        .instr      (id_instr ),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .rs1        (rs1   ),
        .rs2        (rs2   ),
        .rd         (rd    ),  
        .uses_rs1   (uses_rs1),
        .uses_rs2   (uses_rs2),    
        .imm        (imm   )
    );
    
    //control unit
    wire RegWrite,MemRead,MemWrite,MemToReg,Branch,Jump,ALUSrc;
    wire [1:0] ALUOp;
    
    control_unit u_ctrl(
        .opcode     (opcode  ),
        .RegWrite   (RegWrite),   
        .MemRead    (MemRead ),    
        .MemWrite   (MemWrite),   
        .MemToReg   (MemToReg),   
        .Branch     (Branch  ),     
        .Jump       (Jump    ),       
        .ALUSrc     (ALUSrc  ),     
        .ALUOp      (ALUOp   )       
    );
    
    //register: writeback from WB stage
    wire [31:0] rs1_val,rs2_val;
    wire [31:0] wb_write_data;
    wire        wb_RegWrite;
    wire [4:0]  wb_rd;
    
    register_file u_rf(
        .clk        (clk    ),
        .we         (wb_RegWrite),         
        .waddr      (wb_rd  ),      
        .wdata      (wb_write_data),      
        .raddr1     (rs1 ),     
        .rdata1     (rs1_val ),     
        .raddr2     (rs2 ),     
        .rdata2     (rs2_val )     
    );
    
    //=============== Hazard Detection ============
    //load-use hazard: EX阶段的load -> 下一条用它
    wire id_ex_MemRead;
    wire [4:0] id_ex_rd;
    wire stall;
    
    hazard_detection u_hazard(
        .id_ex_MemRead   (id_ex_MemRead),
        .id_ex_rd        (id_ex_rd     ),
        .if_id_rs1       (rs1    ),
        .if_id_rs2       (rs2    ),
        .if_id_uses_rs1  (uses_rs1),
        .if_id_uses_rs2  (uses_rs2),
        .stall           (stall        )
    );
    
    //============= ID/EX pipeline ===========
    wire [31:0] ex_pc,ex_rs1_val,ex_rs2_val,ex_imm;
    wire        ex_valid;
    wire [31:0] ex_instr;
    wire [4:0]  ex_rs1,ex_rs2,ex_rd;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire [6:0]  ex_opcode;
    wire        ex_RegWrite,ex_MemRead,ex_MemWrite,ex_MemToReg;
    wire        ex_Branch,ex_Jump,ex_ALUSrc;
    wire [1:0]  ex_ALUOp;
    
    id_ex u_idex(
        .clk    (clk),
        .rst    (rst),
        .bubble         (stall),
        .flush          (redirect_valid),
        .id_valid       (id_valid),
        .id_instr       (id_instr),
        
        //signals from ID stage
        .id_pc          (id_pc      ),
        .id_rs1_val     (rs1_val ),
        .id_rs2_val     (rs2_val ),
        .id_imm         (imm     ),
        .id_rs1         (rs1     ),
        .id_rs2         (rs2     ),
        .id_rd          (rd      ),
                        
        .id_opcode      (opcode),
        .id_funct3      (funct3  ),
        .id_funct7      (funct7  ),
        .id_RegWrite    (RegWrite),   // 是否写寄存器堆
        .id_MemRead     (MemRead ),    // Data memory 读
        .id_MemWrite    (MemWrite),   // Data memory 写
        .id_MemToReg    (MemToReg),   // WB: 1=从内存写回，0=从 ALU 写回
        .id_Branch      (Branch  ),     // 分支指令
        .id_Jump        (Jump    ),       //for Jal/Jalr
        .id_ALUSrc      (ALUSrc  ),     // ALU 第二个操作数：0=rs2，1=imm
        .id_ALUOp       (ALUOp   ),      // 给 alu_control 用的高层编码
    
        //signals output to EX stage
        .ex_instr       (ex_instr),
        .ex_valid       (ex_valid),
        .ex_pc          (ex_pc      ),
        .ex_rs1_val     (ex_rs1_val ),
        .ex_rs2_val     (ex_rs2_val ),
        .ex_imm         (ex_imm     ),
        .ex_rs1         (ex_rs1     ),
        .ex_rs2         (ex_rs2     ),
        .ex_rd          (ex_rd      ),
                    
        .ex_opcode      (ex_opcode),
        .ex_funct3      (ex_funct3  ),
        .ex_funct7      (ex_funct7  ),
        .ex_RegWrite    (ex_RegWrite),   // 是否写寄存器堆
        .ex_MemRead     (ex_MemRead ),    // Data memory 读
        .ex_MemWrite    (ex_MemWrite),   // Data memory 写
        .ex_MemToReg    (ex_MemToReg),   // WB: 1=从内存写回，0=从 ALU 写回
        .ex_Branch      (ex_Branch  ),     // 分支指令
        .ex_Jump        (ex_Jump    ),       //for Jal/Jalr
        .ex_ALUSrc      (ex_ALUSrc  ),     // ALU 第二个操作数：0=rs2，1=imm
        .ex_ALUOp       (ex_ALUOp   )       // 给 alu_control 用的高层编码
    );
    
    // 给 hazard_detection 用的 id_ex_MemRead/id_ex_rd
    assign id_ex_MemRead = ex_MemRead;
    assign id_ex_rd      = ex_rd;
    
    // ============ EX stage ==============
    //forwarding
    wire [1:0] ForwardA,ForwardB;
    // 需要从后面两级拿信息：先声明线网，等下接
    wire        ex_mem_RegWrite;
    wire [4:0]  ex_mem_rd;
    wire [31:0] ex_mem_alu_result;
    wire        wb_RegWrite_int;
    wire [4:0]  wb_rd_int;
    // wb_write_data 前面已经声明
    
    forwarding_unit u_fwd (
        .ex_mem_RegWrite (ex_mem_RegWrite),
        .ex_mem_rd       (ex_mem_rd),
        .mem_wb_RegWrite (wb_RegWrite_int),
        .mem_wb_rd       (wb_rd_int),
        .id_ex_rs1       (ex_rs1),
        .id_ex_rs2       (ex_rs2),
        .ForwardA        (ForwardA),
        .ForwardB        (ForwardB)
    );
    
    //forwarding mux
    reg [31:0] alu_in1_pre,alu_in2_pre;
    always @(*) begin
        case(ForwardA)
            2'b10:alu_in1_pre = ex_mem_alu_result;
            2'b01:alu_in1_pre = wb_write_data;
            default: alu_in1_pre = ex_rs1_val;
        endcase
        
        case(ForwardB)
            2'b10:alu_in2_pre = ex_mem_alu_result;
            2'b01:alu_in2_pre = wb_write_data;
            default: alu_in2_pre = ex_rs2_val;
        endcase
    end
    
    wire [31:0] alu_in1 = alu_in1_pre;
    wire [31:0] alu_in2 = ex_ALUSrc ? ex_imm : alu_in2_pre;
    
    //ALU control
    wire [3:0] alu_ctrl;
    alu_control u_aluctrl(
        .ALUOp  (ex_ALUOp  ),
        .opcode (ex_opcode ),
        .funct3 (ex_funct3 ),
        .funct7 (ex_funct7 ),
        .ALUCtrl(alu_ctrl)
    );
    
    //ALU
    wire [31:0] alu_result;
    wire        alu_zero;
    alu u_alu(
        .a          (alu_in1),
        .b          (alu_in2),      
        .alu_ctrl   (alu_ctrl), 
        .result     (alu_result),
        .zero       (alu_zero)
    );
    
    // 分支目标先简单算：pc + imm
    wire [31:0] ex_branch_target = ex_pc + ex_imm;
    
    // ---------- Branch ----------
    assign branch_taken =
           ex_valid && ex_Branch &&
           (
               ((ex_funct3 == 3'b000) &&  alu_zero) ||  // beq
               ((ex_funct3 == 3'b001) && !alu_zero)     // bne
           );
    
    assign branch_target = ex_branch_target;
    
    // ---------- Jump: JAL / JALR ----------
    wire ex_is_jal;
    wire ex_is_jalr;
    wire jump_taken;
    
    wire ex_is_lui;
    wire ex_is_auipc;
    
    assign ex_is_lui   = (ex_opcode == 7'b0110111);
    assign ex_is_auipc = (ex_opcode == 7'b0010111);

    wire [31:0] ex_jalr_target;
    
    assign ex_is_jal  = (ex_opcode == 7'b1101111);
    assign ex_is_jalr = (ex_opcode == 7'b1100111);
    
    // JAL 与 JALR 都属于真正会修改 PC 的跳转指令
    assign jump_taken = ex_valid && ex_Jump && (ex_is_jal || ex_is_jalr);
    
    // JALR 的目标地址来自前递后的 rs1 + immediate。
    // 最低位必须清零，保证地址至少 2-byte 对齐。
    assign ex_jalr_target = (alu_in1_pre + ex_imm) & 32'hFFFF_FFFE;
    
    
    // ---------- Redirect control ----------
    assign redirect_valid = branch_taken || jump_taken;
    
    assign redirect_pc =
           ex_is_jalr ? ex_jalr_target :
           jump_taken ? ex_branch_target :
                        branch_target;
    
    assign pc_next = redirect_valid ? redirect_pc : pc_plus4;
    
    // 只有当前 ID 阶段的 EBREAK 确实在正确路径上时，才允许停机。
    // 若同周期 EX 阶段发生 taken branch/jump，则 ID 中指令属于错误路径，不能 halt。
    assign halt_req =
           id_valid &&
           (id_instr == 32'h0010_0073) &&
           !redirect_valid;
    
    //=================== EX/MEM pipeline ================
    wire        mem_valid;
    wire [31:0] mem_pc;
    wire [31:0] mem_instr;
    wire [31:0] mem_branch_target,mem_alu_result,mem_rs2_val;
    wire [4:0]  mem_rd;
    wire        mem_zero;
    wire        mem_RegWrite, mem_MemRead, mem_MemWrite, mem_MemToReg;
    wire        mem_Branch, mem_Jump;
    
    wire [31:0] ex_writeback_result;

    wire [31:0] ex_writeback_result;

    // 普通 ALU 指令：写回 alu_result
    // JAL / JALR：写回 PC + 4
    // LUI：写回 U 型立即数
    // AUIPC：写回当前指令 PC + U 型立即数
    assign ex_writeback_result =
           jump_taken  ? (ex_pc + 32'd4) :
           ex_is_lui   ? ex_imm :
           ex_is_auipc ? (ex_pc + ex_imm) :
                         alu_result;
    
    ex_mem u_exmem(
        .clk    (clk),
        .rst    (rst),
        .stall  (1'b0),  //先不用单独stall MEM,
        
        //from EX stage
        .ex_valid           (ex_valid),
        .ex_pc              (ex_pc),  
        .ex_instr           (ex_instr),
        .ex_branch_target   (ex_branch_target),     //branch/jump destination
        .ex_zero            (alu_zero         ),              //ALU zero 
        .ex_alu_result      (ex_writeback_result   ),        //ALU result
        .ex_rs2_val         (alu_in2_pre      ),           //store data
        .ex_rd              (ex_rd           ),
                           
        .ex_RegWrite        (ex_RegWrite     ),
        .ex_MemRead         (ex_MemRead      ),
        .ex_MemWrite        (ex_MemWrite     ),
        .ex_MemToReg        (ex_MemToReg     ),
        .ex_Branch          (ex_Branch       ),
        .ex_Jump            (ex_Jump         ),
        
        //to MEM stage
        .mem_valid          (mem_valid),
        .mem_pc             (mem_pc),
        .mem_instr          (mem_instr),
        .mem_branch_target  (mem_branch_target),     //branch/jump destination
        .mem_zero           (mem_zero         ),              //ALU zero 
        .mem_alu_result     (mem_alu_result   ),        //ALU result
        .mem_rs2_val        (mem_rs2_val      ),           //store data
        .mem_rd             (mem_rd           ),
                        
        .mem_RegWrite       (mem_RegWrite     ),
        .mem_MemRead        (mem_MemRead      ),
        .mem_MemWrite       (mem_MemWrite     ),
        .mem_MemToReg       (mem_MemToReg     ),
        .mem_Branch         (mem_Branch       ),
        .mem_Jump           (mem_Jump         )
    );
    
    //回接给forwarding
    assign ex_mem_RegWrite  = mem_RegWrite;
    assign ex_mem_rd        = mem_rd;
    assign ex_mem_alu_result = mem_alu_result;
    
    // ===================== MEM stage =====================
    wire [31:0] mem_read_data;
    dmem u_dmem (
        .clk       (clk),
        .MemRead   (mem_MemRead),
        .MemWrite  (mem_MemWrite),
        .addr      (mem_alu_result),
        .write_data(mem_rs2_val),
        .read_data (mem_read_data)
    );

    // （后面想做分支/跳转时，在这里用 mem_Branch/mem_zero/mem_branch_target 选择 pc_next）

    // ===================== MEM/WB pipeline =====================
    wire        wb_valid;
    wire [31:0] wb_pc_int;
    wire [31:0] wb_instr_int;
    
    wire        wb_store_we_int;
    wire [31:0] wb_store_addr_int;
    wire [31:0] wb_store_wdata_int;
    wire [31:0] wb_read_data_int, wb_alu_result_int;
    wire        wb_MemToReg_int;

    mem_wb u_memwb (
        .clk           (clk),
        .rst           (rst),
        .stall         (1'b0),
        .mem_valid     (mem_valid),
        
        .mem_pc        (mem_pc),
        .mem_instr     (mem_instr),
        
        .mem_store_we    (mem_MemWrite),
        .mem_store_addr  (mem_alu_result),
        .mem_store_wdata (mem_rs2_val),
        
        .mem_read_data (mem_read_data),
        .mem_alu_result(mem_alu_result),
        .mem_rd        (mem_rd),
        .mem_RegWrite  (mem_RegWrite),
        .mem_MemToReg  (mem_MemToReg),

        .wb_valid      (wb_valid),
        
        .wb_pc    (wb_pc_int),
        .wb_instr (wb_instr_int),
        
        .wb_store_we    (wb_store_we_int),
        .wb_store_addr  (wb_store_addr_int),
        .wb_store_wdata (wb_store_wdata_int),

        .wb_read_data  (wb_read_data_int),
        .wb_alu_result (wb_alu_result_int),
        .wb_rd         (wb_rd_int),
        .wb_RegWrite   (wb_RegWrite_int),
        .wb_MemToReg   (wb_MemToReg_int)
    );

    // ===================== WB stage =====================
    assign wb_write_data = wb_MemToReg_int ? wb_read_data_int : wb_alu_result_int;
    assign wb_RegWrite   = wb_RegWrite_int;
    assign wb_rd         = wb_rd_int;
    
    // -------- Architectural commit / retire trace --------
    // wb_valid=1 表示流水线末端有一条真实指令。
    
    assign commit_valid = wb_valid;
    assign commit_pc    = wb_pc_int;
    assign commit_instr = wb_instr_int;
    
    // 真正写 x0 不应视为架构寄存器写回。
    assign commit_rd_we   = wb_valid &&
                            wb_RegWrite_int &&
                            (wb_rd_int != 5'd0);
    
    assign commit_rd      = wb_rd_int;
    assign commit_rd_data = wb_write_data;
    
    // Store 的实际写操作发生在 MEM；
    // 此处把对应 store transaction 延迟到 WB 作为统一 commit record 输出。
    assign commit_mem_we    = wb_valid && wb_store_we_int;
    assign commit_mem_addr  = wb_store_addr_int;
    assign commit_mem_wdata = wb_store_wdata_int;
endmodule
