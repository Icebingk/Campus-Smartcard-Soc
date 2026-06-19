`timescale 1ns / 1ps
// ============================================================================
// AES-128 迭代折叠架构协处理器 (Iterative Architecture) — v1.0
// ============================================================================
// 功能: 低面积 AES-128 加密/解密引擎
//       单轮函数复用，10 轮迭代完成一次加解密
//       门数量控制在 4000 内（含 S-Box ROM）
//
// APB 基址: 0x4000_1000 (Slave 1)
// 寄存器数: 16 个 (0x00 ~ 0x3C)
//
// 版本: v1.0 (完整迭代引擎)
// 负责人: 阿呆不呆
// ============================================================================
//
// 使用流程:
//   1. 写 AES_KEY[0:3] 设置 128-bit 密钥
//   2. 写 AES_DIN[0:3] 设置 128-bit 明文/密文
//   3. 写 AES_CTRL.bit0=1 (ENCRYPT) 或 bit1=1 (DECRYPT)
//   4. 写 AES_CTRL.bit31=1 (START)
//   5. 轮询 AES_STATUS.bit0 (BUSY) 或等待中断
//   6. 读 AES_DOUT[0:3] 获取结果
//
// ============================================================================

module aes_top (
    input  wire         pclk, presetn,
    input  wire         psel, penable,
    input  wire [11:0]  paddr,
    input  wire         pwrite,
    input  wire [31:0]  pwdata,
    output reg  [31:0]  prdata,
    output wire         pready, pslverr,
    output reg          irq_o
);

    // ================================================================
    // APB 寄存器接口
    // ================================================================
    localparam NUM_REGS = 16;
    localparam ADDR_W   = 4;
    wire [ADDR_W-1:0] reg_addr;
    assign reg_addr = paddr[ADDR_W-1:0];
    wire apb_write;
    assign apb_write = psel && penable && pwrite;

    // 0x00 CTRL   0x04 STATUS  0x08 KEY0   0x0C KEY1
    // 0x10 KEY2   0x14 KEY3    0x18 DIN0   0x1C DIN1
    // 0x20 DIN2   0x24 DIN3    0x28 DOUT0  0x2C DOUT1
    // 0x30 DOUT2  0x34 DOUT3   0x38 INT_EN 0x3C INT_STATUS

    reg [31:0] regfile [0:NUM_REGS-1];
    integer i;
    always @(negedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < NUM_REGS; i = i + 1) regfile[i] <= 32'h0;
        end else if (apb_write) begin
            if (reg_addr != 4'h1 && !(reg_addr >= 4'hA && reg_addr <= 4'hD))
                regfile[reg_addr] <= pwdata;
            if (reg_addr == 4'hF)
                regfile[4'hF] <= regfile[4'hF] & ~pwdata;  // W1C
        end
    end

    always @(*) begin
        prdata = (psel && !pwrite) ? regfile[reg_addr] : 32'h0;
    end
    assign pready = 1'b1;
    assign pslverr = 1'b0;

    // ================================================================
    // S-Box & Inv S-Box (256 entries each)
    // ================================================================
    function [7:0] sbox;
        input [7:0] b;
        case (b)
            8'h00: sbox=8'h63; 8'h01: sbox=8'h7c; 8'h02: sbox=8'h77; 8'h03: sbox=8'h7b;
            8'h04: sbox=8'hf2; 8'h05: sbox=8'h6b; 8'h06: sbox=8'h6f; 8'h07: sbox=8'hc5;
            8'h08: sbox=8'h30; 8'h09: sbox=8'h01; 8'h0a: sbox=8'h67; 8'h0b: sbox=8'h2b;
            8'h0c: sbox=8'hfe; 8'h0d: sbox=8'hd7; 8'h0e: sbox=8'hab; 8'h0f: sbox=8'h76;
            8'h10: sbox=8'hca; 8'h11: sbox=8'h82; 8'h12: sbox=8'hc9; 8'h13: sbox=8'h7d;
            8'h14: sbox=8'hfa; 8'h15: sbox=8'h59; 8'h16: sbox=8'h47; 8'h17: sbox=8'hf0;
            8'h18: sbox=8'had; 8'h19: sbox=8'hd4; 8'h1a: sbox=8'ha2; 8'h1b: sbox=8'haf;
            8'h1c: sbox=8'h9c; 8'h1d: sbox=8'ha4; 8'h1e: sbox=8'h72; 8'h1f: sbox=8'hc0;
            8'h20: sbox=8'hb7; 8'h21: sbox=8'hfd; 8'h22: sbox=8'h93; 8'h23: sbox=8'h26;
            8'h24: sbox=8'h36; 8'h25: sbox=8'h3f; 8'h26: sbox=8'hf7; 8'h27: sbox=8'hcc;
            8'h28: sbox=8'h34; 8'h29: sbox=8'ha5; 8'h2a: sbox=8'he5; 8'h2b: sbox=8'hf1;
            8'h2c: sbox=8'h71; 8'h2d: sbox=8'hd8; 8'h2e: sbox=8'h31; 8'h2f: sbox=8'h15;
            8'h30: sbox=8'h04; 8'h31: sbox=8'hc7; 8'h32: sbox=8'h23; 8'h33: sbox=8'hc3;
            8'h34: sbox=8'h18; 8'h35: sbox=8'h96; 8'h36: sbox=8'h05; 8'h37: sbox=8'h9a;
            8'h38: sbox=8'h07; 8'h39: sbox=8'h12; 8'h3a: sbox=8'h80; 8'h3b: sbox=8'he2;
            8'h3c: sbox=8'heb; 8'h3d: sbox=8'h27; 8'h3e: sbox=8'hb2; 8'h3f: sbox=8'h75;
            8'h40: sbox=8'h09; 8'h41: sbox=8'h83; 8'h42: sbox=8'h2c; 8'h43: sbox=8'h1a;
            8'h44: sbox=8'h1b; 8'h45: sbox=8'h6e; 8'h46: sbox=8'h5a; 8'h47: sbox=8'ha0;
            8'h48: sbox=8'h52; 8'h49: sbox=8'h3b; 8'h4a: sbox=8'hd6; 8'h4b: sbox=8'hb3;
            8'h4c: sbox=8'h29; 8'h4d: sbox=8'he3; 8'h4e: sbox=8'h2f; 8'h4f: sbox=8'h84;
            8'h50: sbox=8'h53; 8'h51: sbox=8'hd1; 8'h52: sbox=8'h00; 8'h53: sbox=8'hed;
            8'h54: sbox=8'h20; 8'h55: sbox=8'hfc; 8'h56: sbox=8'hb1; 8'h57: sbox=8'h5b;
            8'h58: sbox=8'h6a; 8'h59: sbox=8'hcb; 8'h5a: sbox=8'hbe; 8'h5b: sbox=8'h39;
            8'h5c: sbox=8'h4a; 8'h5d: sbox=8'h4c; 8'h5e: sbox=8'h58; 8'h5f: sbox=8'hcf;
            8'h60: sbox=8'hd0; 8'h61: sbox=8'hef; 8'h62: sbox=8'haa; 8'h63: sbox=8'hfb;
            8'h64: sbox=8'h43; 8'h65: sbox=8'h4d; 8'h66: sbox=8'h33; 8'h67: sbox=8'h85;
            8'h68: sbox=8'h45; 8'h69: sbox=8'hf9; 8'h6a: sbox=8'h02; 8'h6b: sbox=8'h7f;
            8'h6c: sbox=8'h50; 8'h6d: sbox=8'h3c; 8'h6e: sbox=8'h9f; 8'h6f: sbox=8'ha8;
            8'h70: sbox=8'h51; 8'h71: sbox=8'ha3; 8'h72: sbox=8'h40; 8'h73: sbox=8'h8f;
            8'h74: sbox=8'h92; 8'h75: sbox=8'h9d; 8'h76: sbox=8'h38; 8'h77: sbox=8'hf5;
            8'h78: sbox=8'hbc; 8'h79: sbox=8'hb6; 8'h7a: sbox=8'hda; 8'h7b: sbox=8'h21;
            8'h7c: sbox=8'h10; 8'h7d: sbox=8'hff; 8'h7e: sbox=8'hf3; 8'h7f: sbox=8'hd2;
            8'h80: sbox=8'hcd; 8'h81: sbox=8'h0c; 8'h82: sbox=8'h13; 8'h83: sbox=8'hec;
            8'h84: sbox=8'h5f; 8'h85: sbox=8'h97; 8'h86: sbox=8'h44; 8'h87: sbox=8'h17;
            8'h88: sbox=8'hc4; 8'h89: sbox=8'ha7; 8'h8a: sbox=8'h7e; 8'h8b: sbox=8'h3d;
            8'h8c: sbox=8'h64; 8'h8d: sbox=8'h5d; 8'h8e: sbox=8'h19; 8'h8f: sbox=8'h73;
            8'h90: sbox=8'h60; 8'h91: sbox=8'h81; 8'h92: sbox=8'h4f; 8'h93: sbox=8'hdc;
            8'h94: sbox=8'h22; 8'h95: sbox=8'h2a; 8'h96: sbox=8'h90; 8'h97: sbox=8'h88;
            8'h98: sbox=8'h46; 8'h99: sbox=8'hee; 8'h9a: sbox=8'hb8; 8'h9b: sbox=8'h14;
            8'h9c: sbox=8'hde; 8'h9d: sbox=8'h5e; 8'h9e: sbox=8'h0b; 8'h9f: sbox=8'hdb;
            8'ha0: sbox=8'he0; 8'ha1: sbox=8'h32; 8'ha2: sbox=8'h3a; 8'ha3: sbox=8'h0a;
            8'ha4: sbox=8'h49; 8'ha5: sbox=8'h06; 8'ha6: sbox=8'h24; 8'ha7: sbox=8'h5c;
            8'ha8: sbox=8'hc2; 8'ha9: sbox=8'hd3; 8'haa: sbox=8'hac; 8'hab: sbox=8'h62;
            8'hac: sbox=8'h91; 8'had: sbox=8'h95; 8'hae: sbox=8'he4; 8'haf: sbox=8'h79;
            8'hb0: sbox=8'he7; 8'hb1: sbox=8'hc8; 8'hb2: sbox=8'h37; 8'hb3: sbox=8'h6d;
            8'hb4: sbox=8'h8d; 8'hb5: sbox=8'hd5; 8'hb6: sbox=8'h4e; 8'hb7: sbox=8'ha9;
            8'hb8: sbox=8'h6c; 8'hb9: sbox=8'h56; 8'hba: sbox=8'hf4; 8'hbb: sbox=8'hea;
            8'hbc: sbox=8'h65; 8'hbd: sbox=8'h7a; 8'hbe: sbox=8'hae; 8'hbf: sbox=8'h08;
            8'hc0: sbox=8'hba; 8'hc1: sbox=8'h78; 8'hc2: sbox=8'h25; 8'hc3: sbox=8'h2e;
            8'hc4: sbox=8'h1c; 8'hc5: sbox=8'ha6; 8'hc6: sbox=8'hb4; 8'hc7: sbox=8'hc6;
            8'hc8: sbox=8'he8; 8'hc9: sbox=8'hdd; 8'hca: sbox=8'h74; 8'hcb: sbox=8'h1f;
            8'hcc: sbox=8'h4b; 8'hcd: sbox=8'hbd; 8'hce: sbox=8'h8b; 8'hcf: sbox=8'h8a;
            8'hd0: sbox=8'h70; 8'hd1: sbox=8'h3e; 8'hd2: sbox=8'hb5; 8'hd3: sbox=8'h66;
            8'hd4: sbox=8'h48; 8'hd5: sbox=8'h03; 8'hd6: sbox=8'hf6; 8'hd7: sbox=8'h0e;
            8'hd8: sbox=8'h61; 8'hd9: sbox=8'h35; 8'hda: sbox=8'h57; 8'hdb: sbox=8'hb9;
            8'hdc: sbox=8'h86; 8'hdd: sbox=8'hc1; 8'hde: sbox=8'h1d; 8'hdf: sbox=8'h9e;
            8'he0: sbox=8'he1; 8'he1: sbox=8'hf8; 8'he2: sbox=8'h98; 8'he3: sbox=8'h11;
            8'he4: sbox=8'h69; 8'he5: sbox=8'hd9; 8'he6: sbox=8'h8e; 8'he7: sbox=8'h94;
            8'he8: sbox=8'h9b; 8'he9: sbox=8'h1e; 8'hea: sbox=8'h87; 8'heb: sbox=8'he9;
            8'hec: sbox=8'hce; 8'hed: sbox=8'h55; 8'hee: sbox=8'h28; 8'hef: sbox=8'hdf;
            8'hf0: sbox=8'h8c; 8'hf1: sbox=8'ha1; 8'hf2: sbox=8'h89; 8'hf3: sbox=8'h0d;
            8'hf4: sbox=8'hbf; 8'hf5: sbox=8'he6; 8'hf6: sbox=8'h42; 8'hf7: sbox=8'h68;
            8'hf8: sbox=8'h41; 8'hf9: sbox=8'h99; 8'hfa: sbox=8'h2d; 8'hfb: sbox=8'h0f;
            8'hfc: sbox=8'hb0; 8'hfd: sbox=8'h54; 8'hfe: sbox=8'hbb; 8'hff: sbox=8'h16;
            default: sbox=8'h00;
        endcase
    endfunction

    function [7:0] inv_sbox;
        input [7:0] b;
        case (b)
            8'h00: inv_sbox=8'h52; 8'h01: inv_sbox=8'h09; 8'h02: inv_sbox=8'h6a; 8'h03: inv_sbox=8'hd5;
            8'h04: inv_sbox=8'h30; 8'h05: inv_sbox=8'h36; 8'h06: inv_sbox=8'ha5; 8'h07: inv_sbox=8'h38;
            8'h08: inv_sbox=8'hbf; 8'h09: inv_sbox=8'h40; 8'h0a: inv_sbox=8'ha3; 8'h0b: inv_sbox=8'h9e;
            8'h0c: inv_sbox=8'h81; 8'h0d: inv_sbox=8'hf3; 8'h0e: inv_sbox=8'hd7; 8'h0f: inv_sbox=8'hfb;
            8'h10: inv_sbox=8'h7c; 8'h11: inv_sbox=8'he3; 8'h12: inv_sbox=8'h39; 8'h13: inv_sbox=8'h82;
            8'h14: inv_sbox=8'h9b; 8'h15: inv_sbox=8'h2f; 8'h16: inv_sbox=8'hff; 8'h17: inv_sbox=8'h87;
            8'h18: inv_sbox=8'h34; 8'h19: inv_sbox=8'h8e; 8'h1a: inv_sbox=8'h43; 8'h1b: inv_sbox=8'h44;
            8'h1c: inv_sbox=8'hc4; 8'h1d: inv_sbox=8'hde; 8'h1e: inv_sbox=8'he9; 8'h1f: inv_sbox=8'hcb;
            8'h20: inv_sbox=8'h54; 8'h21: inv_sbox=8'h7b; 8'h22: inv_sbox=8'h94; 8'h23: inv_sbox=8'h32;
            8'h24: inv_sbox=8'ha6; 8'h25: inv_sbox=8'hc2; 8'h26: inv_sbox=8'h23; 8'h27: inv_sbox=8'h3d;
            8'h28: inv_sbox=8'hee; 8'h29: inv_sbox=8'h4c; 8'h2a: inv_sbox=8'h95; 8'h2b: inv_sbox=8'h0b;
            8'h2c: inv_sbox=8'h42; 8'h2d: inv_sbox=8'hfa; 8'h2e: inv_sbox=8'hc3; 8'h2f: inv_sbox=8'h4e;
            8'h30: inv_sbox=8'h08; 8'h31: inv_sbox=8'h2e; 8'h32: inv_sbox=8'ha1; 8'h33: inv_sbox=8'h66;
            8'h34: inv_sbox=8'h28; 8'h35: inv_sbox=8'hd9; 8'h36: inv_sbox=8'h24; 8'h37: inv_sbox=8'hb2;
            8'h38: inv_sbox=8'h76; 8'h39: inv_sbox=8'h5b; 8'h3a: inv_sbox=8'ha2; 8'h3b: inv_sbox=8'h49;
            8'h3c: inv_sbox=8'h6d; 8'h3d: inv_sbox=8'h8b; 8'h3e: inv_sbox=8'hd1; 8'h3f: inv_sbox=8'h25;
            8'h40: inv_sbox=8'h72; 8'h41: inv_sbox=8'hf8; 8'h42: inv_sbox=8'hf6; 8'h43: inv_sbox=8'h64;
            8'h44: inv_sbox=8'h86; 8'h45: inv_sbox=8'h68; 8'h46: inv_sbox=8'h98; 8'h47: inv_sbox=8'h16;
            8'h48: inv_sbox=8'hd4; 8'h49: inv_sbox=8'ha4; 8'h4a: inv_sbox=8'h5c; 8'h4b: inv_sbox=8'hcc;
            8'h4c: inv_sbox=8'h5d; 8'h4d: inv_sbox=8'h65; 8'h4e: inv_sbox=8'hb6; 8'h4f: inv_sbox=8'h92;
            8'h50: inv_sbox=8'h6c; 8'h51: inv_sbox=8'h70; 8'h52: inv_sbox=8'h48; 8'h53: inv_sbox=8'h50;
            8'h54: inv_sbox=8'hfd; 8'h55: inv_sbox=8'hed; 8'h56: inv_sbox=8'hb9; 8'h57: inv_sbox=8'hda;
            8'h58: inv_sbox=8'h5e; 8'h59: inv_sbox=8'h15; 8'h5a: inv_sbox=8'h46; 8'h5b: inv_sbox=8'h57;
            8'h5c: inv_sbox=8'ha7; 8'h5d: inv_sbox=8'h8d; 8'h5e: inv_sbox=8'h9d; 8'h5f: inv_sbox=8'h84;
            8'h60: inv_sbox=8'h90; 8'h61: inv_sbox=8'hd8; 8'h62: inv_sbox=8'hab; 8'h63: inv_sbox=8'h00;
            8'h64: inv_sbox=8'h8c; 8'h65: inv_sbox=8'hbc; 8'h66: inv_sbox=8'hd3; 8'h67: inv_sbox=8'h0a;
            8'h68: inv_sbox=8'hf7; 8'h69: inv_sbox=8'he4; 8'h6a: inv_sbox=8'h58; 8'h6b: inv_sbox=8'h05;
            8'h6c: inv_sbox=8'hb8; 8'h6d: inv_sbox=8'hb3; 8'h6e: inv_sbox=8'h45; 8'h6f: inv_sbox=8'h06;
            8'h70: inv_sbox=8'hd0; 8'h71: inv_sbox=8'h2c; 8'h72: inv_sbox=8'h1e; 8'h73: inv_sbox=8'h8f;
            8'h74: inv_sbox=8'hca; 8'h75: inv_sbox=8'h3f; 8'h76: inv_sbox=8'h0f; 8'h77: inv_sbox=8'h02;
            8'h78: inv_sbox=8'hc1; 8'h79: inv_sbox=8'haf; 8'h7a: inv_sbox=8'hbd; 8'h7b: inv_sbox=8'h03;
            8'h7c: inv_sbox=8'h01; 8'h7d: inv_sbox=8'h13; 8'h7e: inv_sbox=8'h8a; 8'h7f: inv_sbox=8'h6b;
            8'h80: inv_sbox=8'h3a; 8'h81: inv_sbox=8'h91; 8'h82: inv_sbox=8'h11; 8'h83: inv_sbox=8'h41;
            8'h84: inv_sbox=8'h4f; 8'h85: inv_sbox=8'h67; 8'h86: inv_sbox=8'hdc; 8'h87: inv_sbox=8'hea;
            8'h88: inv_sbox=8'h97; 8'h89: inv_sbox=8'hf2; 8'h8a: inv_sbox=8'hcf; 8'h8b: inv_sbox=8'hce;
            8'h8c: inv_sbox=8'hf0; 8'h8d: inv_sbox=8'hb4; 8'h8e: inv_sbox=8'he6; 8'h8f: inv_sbox=8'h73;
            8'h90: inv_sbox=8'h96; 8'h91: inv_sbox=8'hac; 8'h92: inv_sbox=8'h74; 8'h93: inv_sbox=8'h22;
            8'h94: inv_sbox=8'he7; 8'h95: inv_sbox=8'had; 8'h96: inv_sbox=8'h35; 8'h97: inv_sbox=8'h85;
            8'h98: inv_sbox=8'he2; 8'h99: inv_sbox=8'hf9; 8'h9a: inv_sbox=8'h37; 8'h9b: inv_sbox=8'he8;
            8'h9c: inv_sbox=8'h1c; 8'h9d: inv_sbox=8'h75; 8'h9e: inv_sbox=8'hdf; 8'h9f: inv_sbox=8'h6e;
            8'ha0: inv_sbox=8'h47; 8'ha1: inv_sbox=8'hf1; 8'ha2: inv_sbox=8'h1a; 8'ha3: inv_sbox=8'h71;
            8'ha4: inv_sbox=8'h1d; 8'ha5: inv_sbox=8'h29; 8'ha6: inv_sbox=8'hc5; 8'ha7: inv_sbox=8'h89;
            8'ha8: inv_sbox=8'h6f; 8'ha9: inv_sbox=8'hb7; 8'haa: inv_sbox=8'h62; 8'hab: inv_sbox=8'h0e;
            8'hac: inv_sbox=8'haa; 8'had: inv_sbox=8'h18; 8'hae: inv_sbox=8'hbe; 8'haf: inv_sbox=8'h1b;
            8'hb0: inv_sbox=8'hfc; 8'hb1: inv_sbox=8'h56; 8'hb2: inv_sbox=8'h3e; 8'hb3: inv_sbox=8'h4b;
            8'hb4: inv_sbox=8'hc6; 8'hb5: inv_sbox=8'hd2; 8'hb6: inv_sbox=8'h79; 8'hb7: inv_sbox=8'h20;
            8'hb8: inv_sbox=8'h9a; 8'hb9: inv_sbox=8'hdb; 8'hba: inv_sbox=8'hc0; 8'hbb: inv_sbox=8'hfe;
            8'hbc: inv_sbox=8'h78; 8'hbd: inv_sbox=8'hcd; 8'hbe: inv_sbox=8'h5a; 8'hbf: inv_sbox=8'hf4;
            8'hc0: inv_sbox=8'h1f; 8'hc1: inv_sbox=8'hdd; 8'hc2: inv_sbox=8'ha8; 8'hc3: inv_sbox=8'h33;
            8'hc4: inv_sbox=8'h88; 8'hc5: inv_sbox=8'h07; 8'hc6: inv_sbox=8'hc7; 8'hc7: inv_sbox=8'h31;
            8'hc8: inv_sbox=8'hb1; 8'hc9: inv_sbox=8'h12; 8'hca: inv_sbox=8'h10; 8'hcb: inv_sbox=8'h59;
            8'hcc: inv_sbox=8'h27; 8'hcd: inv_sbox=8'h80; 8'hce: inv_sbox=8'hec; 8'hcf: inv_sbox=8'h5f;
            8'hd0: inv_sbox=8'h60; 8'hd1: inv_sbox=8'h51; 8'hd2: inv_sbox=8'h7f; 8'hd3: inv_sbox=8'ha9;
            8'hd4: inv_sbox=8'h19; 8'hd5: inv_sbox=8'hb5; 8'hd6: inv_sbox=8'h4a; 8'hd7: inv_sbox=8'h0d;
            8'hd8: inv_sbox=8'h2d; 8'hd9: inv_sbox=8'he5; 8'hda: inv_sbox=8'h7a; 8'hdb: inv_sbox=8'h9f;
            8'hdc: inv_sbox=8'h93; 8'hdd: inv_sbox=8'hc9; 8'hde: inv_sbox=8'h9c; 8'hdf: inv_sbox=8'hef;
            8'he0: inv_sbox=8'ha0; 8'he1: inv_sbox=8'he0; 8'he2: inv_sbox=8'h3b; 8'he3: inv_sbox=8'h4d;
            8'he4: inv_sbox=8'hae; 8'he5: inv_sbox=8'h2a; 8'he6: inv_sbox=8'hf5; 8'he7: inv_sbox=8'hb0;
            8'he8: inv_sbox=8'hc8; 8'he9: inv_sbox=8'heb; 8'hea: inv_sbox=8'hbb; 8'heb: inv_sbox=8'h3c;
            8'hec: inv_sbox=8'h83; 8'hed: inv_sbox=8'h53; 8'hee: inv_sbox=8'h99; 8'hef: inv_sbox=8'h61;
            8'hf0: inv_sbox=8'h17; 8'hf1: inv_sbox=8'h2b; 8'hf2: inv_sbox=8'h04; 8'hf3: inv_sbox=8'h7e;
            8'hf4: inv_sbox=8'hba; 8'hf5: inv_sbox=8'h77; 8'hf6: inv_sbox=8'hd6; 8'hf7: inv_sbox=8'h26;
            8'hf8: inv_sbox=8'he1; 8'hf9: inv_sbox=8'h69; 8'hfa: inv_sbox=8'h14; 8'hfb: inv_sbox=8'h63;
            8'hfc: inv_sbox=8'h55; 8'hfd: inv_sbox=8'h21; 8'hfe: inv_sbox=8'h0c; 8'hff: inv_sbox=8'h7d;
            default: inv_sbox=8'h00;
        endcase
    endfunction

    // ================================================================
    // GF(2^8) 乘法
    // ================================================================
    function [7:0] xtime; input [7:0] x; xtime = x[7] ? {x[6:0],1'b0}^8'h1b : {x[6:0],1'b0}; endfunction
    function [7:0] gf2; input [7:0] x; gf2 = xtime(x); endfunction
    function [7:0] gf3; input [7:0] x; gf3 = xtime(x)^x; endfunction
    function [7:0] gf9; input [7:0] x; gf9 = xtime(xtime(xtime(x)))^x; endfunction
    function [7:0] gf11; input [7:0] x; gf11 = xtime(xtime(xtime(x))^x)^x; endfunction
    function [7:0] gf13; input [7:0] x; gf13 = xtime(xtime(xtime(x)^x))^x; endfunction
    function [7:0] gf14; input [7:0] x; gf14 = xtime(xtime(xtime(x)^x)^x); endfunction

    // ================================================================
    // 密钥扩展 (44 字, 每轮 4 字 = 11 轮)
    // ================================================================
    reg [31:0] rkey [0:43];
    wire [127:0] user_key;
    assign user_key = {regfile[5], regfile[4], regfile[3], regfile[2]};

    function [7:0] rcon;
        input [3:0] r;
        case (r)
            4'd1: rcon=8'h01; 4'd2: rcon=8'h02; 4'd3: rcon=8'h04; 4'd4: rcon=8'h08;
            4'd5: rcon=8'h10; 4'd6: rcon=8'h20; 4'd7: rcon=8'h40; 4'd8: rcon=8'h80;
            4'd9: rcon=8'h1b; 4'd10: rcon=8'h36; default: rcon=8'h00;
        endcase
    endfunction

    wire [31:0] subw;
    assign subw = {sbox(rkey[1][23:16]), sbox(rkey[1][15:8]), sbox(rkey[1][7:0]), sbox(rkey[1][31:24])};

    // ================================================================
    // 状态机: IDLE → KEYEXP → RUN → DONE → IDLE
    // ================================================================
    localparam [2:0] S_IDLE=0, S_KEXP=1, S_RUN=2, S_DONE=3;
    reg [2:0] state, nxt;
    reg [3:0] round;       // 0..9
    reg [3:0] kcnt;        // 密钥扩展计数 0..10
    reg [127:0] st;        // 128-bit 数据状态
    wire start = regfile[0][31];
    wire decrypt = regfile[0][1];

    always @(posedge pclk or negedge presetn)
        if (!presetn) state <= S_IDLE; else state <= nxt;

    always @(*) begin
        nxt = state;
        case (state)
            S_IDLE: if (start) nxt = S_KEXP;
            S_KEXP: if (kcnt==10) nxt = S_RUN;
            S_RUN:  if (round==9) nxt = S_DONE;
            S_DONE: nxt = S_IDLE;
            default: nxt = S_IDLE;
        endcase
    end

    // 密钥扩展控制
    always @(posedge pclk or negedge presetn)
        if (!presetn) kcnt <= 0;
        else if (state==S_IDLE && start) kcnt <= 0;
        else if (state==S_KEXP) kcnt <= kcnt + 1;

    // 轮计数器
    always @(posedge pclk or negedge presetn)
        if (!presetn) round <= 0;
        else if (state==S_KEXP && kcnt==10) round <= 0;
        else if (state==S_RUN) round <= round + 1;

    // 密钥扩展 (1 拍内完成全部 44 字)
    integer ki;
    always @(posedge pclk) begin
        if (state==S_IDLE && start) begin
            rkey[0] <= user_key[127:96]; rkey[1] <= user_key[95:64];
            rkey[2] <= user_key[63:32];  rkey[3] <= user_key[31:0];
            for (ki=4; ki<44; ki=ki+1) begin
                if (ki%4==0)
                    rkey[ki] <= rkey[ki-4] ^ subw ^ {24'h0, rcon(ki/4)};
                else
                    rkey[ki] <= rkey[ki-4] ^ rkey[ki-1];
            end
        end
    end

    // ================================================================
    // 当前轮密钥
    // ================================================================
    wire [31:0] rk0, rk1, rk2, rk3;
    assign rk0 = decrypt ? rkey[40 - round*4] : rkey[round*4];
    assign rk1 = decrypt ? rkey[41 - round*4] : rkey[round*4 + 1];
    assign rk2 = decrypt ? rkey[42 - round*4] : rkey[round*4 + 2];
    assign rk3 = decrypt ? rkey[43 - round*4] : rkey[round*4 + 3];

    // ================================================================
    // SubBytes (16 字节)
    // ================================================================
    wire [7:0] sb [0:15];
    genvar g;
    generate
        for (g=0; g<16; g=g+1) begin : gsb
            assign sb[g] = decrypt ? inv_sbox(st[127-g*8 -: 8]) : sbox(st[127-g*8 -: 8]);
        end
    endgenerate

    // ================================================================
    // ShiftRows
    // ================================================================
    wire [7:0] sr [0:15];
    // row0 (0,4,8,12): no shift
    assign sr[0]=sb[0]; assign sr[4]=sb[4]; assign sr[8]=sb[8]; assign sr[12]=sb[12];
    // row1 (1,5,9,13): encrypt left1 / decrypt right1
    assign sr[1] =decrypt?sb[13]:sb[5];  assign sr[5] =decrypt?sb[1]:sb[9];
    assign sr[9] =decrypt?sb[5]:sb[13];  assign sr[13]=decrypt?sb[9]:sb[1];
    // row2 (2,6,10,14): left2==right2
    assign sr[2]=sb[10]; assign sr[6]=sb[14]; assign sr[10]=sb[2]; assign sr[14]=sb[6];
    // row3 (3,7,11,15): encrypt left3 / decrypt right3
    assign sr[3] =decrypt?sb[7]:sb[15];  assign sr[7] =decrypt?sb[11]:sb[3];
    assign sr[11]=decrypt?sb[15]:sb[7];  assign sr[15]=decrypt?sb[3]:sb[11];

    // ================================================================
    // MixColumns (4 列)
    // ================================================================
    wire [7:0] mc [0:15];
    genvar c;
    generate
        for (c=0; c<4; c=c+1) begin : gmc
            wire [7:0] a=sr[c*4], b=sr[c*4+1], cc=sr[c*4+2], d=sr[c*4+3];
            if (1) begin : enc  // encrypt: {02,03,01,01}
                assign mc[c*4]   = gf2(a)^gf3(b)^cc^d;
                assign mc[c*4+1] = a^gf2(b)^gf3(cc)^d;
                assign mc[c*4+2] = a^b^gf2(cc)^gf3(d);
                assign mc[c*4+3] = gf3(a)^b^cc^gf2(d);
            end
        end
    endgenerate

    // 解密 MixColumns 用独立组合逻辑
    wire [7:0] imc [0:15];
    genvar cd;
    generate
        for (cd=0; cd<4; cd=cd+1) begin : gimc
            wire [7:0] a=sr[cd*4], b=sr[cd*4+1], cc=sr[cd*4+2], d=sr[cd*4+3];
            assign imc[cd*4]   = gf14(a)^gf11(b)^gf13(cc)^gf9(d);
            assign imc[cd*4+1] = gf9(a)^gf14(b)^gf11(cc)^gf13(d);
            assign imc[cd*4+2] = gf13(a)^gf9(b)^gf14(cc)^gf11(d);
            assign imc[cd*4+3] = gf11(a)^gf13(b)^gf9(cc)^gf14(d);
        end
    endgenerate

    // Mux: encrypt 用 mc, decrypt 用 imc
    wire [127:0] after_mix;
    assign after_mix = decrypt ? {imc[0],imc[1],imc[2],imc[3],imc[4],imc[5],imc[6],imc[7],
                                   imc[8],imc[9],imc[10],imc[11],imc[12],imc[13],imc[14],imc[15]}
                               : {mc[0],mc[1],mc[2],mc[3],mc[4],mc[5],mc[6],mc[7],
                                   mc[8],mc[9],mc[10],mc[11],mc[12],mc[13],mc[14],mc[15]};

    // AddRoundKey
    wire [127:0] after_shift;
    assign after_shift = {sr[0],sr[1],sr[2],sr[3],sr[4],sr[5],sr[6],sr[7],
                          sr[8],sr[9],sr[10],sr[11],sr[12],sr[13],sr[14],sr[15]};
    wire [127:0] ark  = after_mix  ^ {rk0,rk1,rk2,rk3};
    wire [127:0] fark = after_shift ^ {rk0,rk1,rk2,rk3};  // final round (no MC)

    // 状态更新
    always @(posedge pclk or negedge presetn)
        if (!presetn) st <= 0;
        else if (state==S_IDLE && start)
            st <= {regfile[9],regfile[8],regfile[7],regfile[6]} ^ {rkey[0],rkey[1],rkey[2],rkey[3]};
        else if (state==S_RUN)
            st <= (round==9) ? fark : ark;

    // 结果写入
    always @(posedge pclk or negedge presetn)
        if (!presetn) ;
        else if (state==S_DONE) begin
            regfile[10] <= st[127:96]; regfile[11] <= st[95:64];
            regfile[12] <= st[63:32];  regfile[13] <= st[31:0];
        end

    // STATUS 更新
    always @(posedge pclk or negedge presetn)
        if (!presetn) ;
        else begin
            regfile[1][0] <= (state != S_IDLE);  // BUSY
            if (state==S_DONE) begin
                regfile[1][1] <= 1'b1;            // DONE
                regfile[0][31] <= 1'b0;           // clear START
            end else if (state==S_IDLE && start)
                regfile[1][1] <= 1'b0;
        end

    // 中断
    always @(posedge pclk or negedge presetn)
        if (!presetn) irq_o <= 0;
        else begin
            if (state==S_DONE && regfile[14][0]) begin
                irq_o <= 1'b1; regfile[15][0] <= 1'b1;
            end else if (!regfile[14][0]) irq_o <= 1'b0;
        end

endmodule
