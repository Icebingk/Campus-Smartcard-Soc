// ============================================================================
// 校园智能卡 SoC — 片上自检固件 (PicoRV32 RV32EC)
// ============================================================================
// 功能: 启动后自动验证 CPU + 总线 + 所有外设互联
// 编译: make -f firmware.mk
// 加载: ROM $readmemh("firmware.hex")
// ============================================================================

// ─── 基本类型 (freestanding, 无 libc) ───
typedef unsigned int   uint32_t;
typedef unsigned short uint16_t;
typedef unsigned char  uint8_t;

// ─── 外设寄存器地址 (Memory Map) ───
#define BB_BASE         0x40000000
#define BB_CTRL         (*(volatile uint32_t*)(BB_BASE + 0x00))
#define BB_STATUS       (*(volatile uint32_t*)(BB_BASE + 0x04))
#define BB_TX_DATA      (*(volatile uint32_t*)(BB_BASE + 0x08))
#define BB_RX_DATA      (*(volatile uint32_t*)(BB_BASE + 0x0C))
#define BB_INT_EN       (*(volatile uint32_t*)(BB_BASE + 0x14))
#define BB_BAUD_CFG     (*(volatile uint32_t*)(BB_BASE + 0x1C))

#define AES_BASE        0x40001000
#define AES_CTRL        (*(volatile uint32_t*)(AES_BASE + 0x00))
#define AES_KEY0        (*(volatile uint32_t*)(AES_BASE + 0x08))
#define AES_KEY1        (*(volatile uint32_t*)(AES_BASE + 0x0C))
#define AES_KEY2        (*(volatile uint32_t*)(AES_BASE + 0x10))
#define AES_KEY3        (*(volatile uint32_t*)(AES_BASE + 0x14))

#define EEP_BASE        0x40002000
#define EEP_CTRL        (*(volatile uint32_t*)(EEP_BASE + 0x00))
#define EEP_ADDR        (*(volatile uint32_t*)(EEP_BASE + 0x08))
#define EEP_WDATA       (*(volatile uint32_t*)(EEP_BASE + 0x0C))
#define EEP_LEN         (*(volatile uint32_t*)(EEP_BASE + 0x14))

#define SRAM_BASE       0x00010000
#define SRAM_END        0x00011FFF

// ─── 测试结果标志 (写在 SRAM 尾部) ───
#define RESULT_PASS     0xCAFEBABE
#define RESULT_FAIL     0xDEADBEEF
volatile uint32_t * const test_result = (uint32_t*)0x00011FF0;
volatile uint32_t * const test_count  = (uint32_t*)0x00011FF4;

// ─── 简单宏 ───
#define PASS()  do { (*test_count)++; } while(0)
#define FAIL()  do { *test_result = RESULT_FAIL; } while(0)

static uint32_t pass_cnt = 0;

void main(void) {
    // 初始化
    *test_result = RESULT_PASS;
    *test_count  = 0;

    // ================================================================
    // 1. ROM 内容读取测试
    // ================================================================
    volatile uint32_t *rom = (uint32_t*)0x00000000;
    uint32_t v = rom[0];  // 第一条指令 (不是 0 即可)
    if (v != 0) PASS(); else FAIL();

    v = rom[1];           // 第二条指令
    if (v != 0) PASS(); else FAIL();

    // ================================================================
    // 2. SRAM 读写测试
    // ================================================================
    volatile uint32_t *sram = (uint32_t*)SRAM_BASE;
    sram[0] = 0xDEADBEEF;
    if (sram[0] == 0xDEADBEEF) PASS(); else FAIL();

    sram[1] = 0xCAFEBABE;
    if (sram[1] == 0xCAFEBABE) PASS(); else FAIL();

    // Walking-1
    sram[0x10] = 0x00000001;
    if (sram[0x10] == 0x00000001) PASS(); else FAIL();

    // Walking-0
    sram[0x14] = 0xFFFFFFFE;
    if (sram[0x14] == 0xFFFFFFFE) PASS(); else FAIL();

    // All-1s
    sram[0x18] = 0xFFFFFFFF;
    if (sram[0x18] == 0xFFFFFFFF) PASS(); else FAIL();

    // All-0s
    sram[0x1C] = 0x00000000;
    if (sram[0x1C] == 0x00000000) PASS(); else FAIL();

    // ================================================================
    // 3. 数字基带寄存器测试
    // ================================================================
    BB_CTRL     = 0x00000003;
    if (BB_CTRL == 0x00000003) PASS(); else FAIL();

    BB_TX_DATA  = 0x55555555;
    if (BB_TX_DATA == 0x55555555) PASS(); else FAIL();

    BB_INT_EN   = 0x0000FFFF;
    if (BB_INT_EN == 0x0000FFFF) PASS(); else FAIL();

    BB_BAUD_CFG = 0x01A00001;
    if (BB_BAUD_CFG == 0x01A00001) PASS(); else FAIL();

    // 回读确认
    if (BB_CTRL == 0x00000003) PASS(); else FAIL();

    // ================================================================
    // 4. AES 密钥寄存器测试
    // ================================================================
    AES_KEY0 = 0x2b7e1516;
    AES_KEY1 = 0x28aed2a6;
    AES_KEY2 = 0xabf71588;
    AES_KEY3 = 0x09cf4f3c;

    if (AES_KEY0 == 0x2b7e1516) PASS(); else FAIL();
    if (AES_KEY1 == 0x28aed2a6) PASS(); else FAIL();
    if (AES_KEY2 == 0xabf71588) PASS(); else FAIL();
    if (AES_KEY3 == 0x09cf4f3c) PASS(); else FAIL();

    // 回读确认未串扰
    if (AES_KEY0 == 0x2b7e1516) PASS(); else FAIL();

    // ================================================================
    // 5. EEPROM 寄存器测试
    // ================================================================
    EEP_CTRL  = 0x00000003;
    EEP_ADDR  = 0x000001A0;
    EEP_WDATA = 0xFEDCBA98;
    EEP_LEN   = 0x00000040;

    if (EEP_CTRL  == 0x00000003) PASS(); else FAIL();
    if (EEP_ADDR  == 0x000001A0) PASS(); else FAIL();
    if (EEP_WDATA == 0xFEDCBA98) PASS(); else FAIL();
    if (EEP_LEN   == 0x00000040) PASS(); else FAIL();

    // ================================================================
    // 6. 边界地址测试
    // ================================================================
    // APB 外设区边界
    volatile uint32_t *apb_edge = (uint32_t*)0x40000FFC;
    *apb_edge = 0xB0B0B0B0;
    if (*apb_edge == 0xB0B0B0B0) PASS(); else FAIL();

    // AES 区起始
    volatile uint32_t *aes_start = (uint32_t*)0x40001000;
    *aes_start = 0xA5A5A5A5;
    if (*aes_start == 0xA5A5A5A5) PASS(); else FAIL();

    // 未映射地址返回默认值
    volatile uint32_t *unmapped = (uint32_t*)0x80000000;
    v = *unmapped;
    if (v == 0xDEADBEEF) PASS(); else FAIL();

    // 另一个未映射地址
    unmapped = (uint32_t*)0xFFFFFFFF;
    v = *unmapped;
    if (v == 0xDEADBEEF) PASS(); else FAIL();

    // ================================================================
    // 7. 背靠背连续访问
    // ================================================================
    sram[8]  = 0xAABBCCDD;
    sram[9]  = 0x11223344;
    sram[10] = 0x55667788;
    sram[11] = 0x99AABBCC;

    if (sram[8]  == 0xAABBCCDD) PASS(); else FAIL();
    if (sram[9]  == 0x11223344) PASS(); else FAIL();
    if (sram[10] == 0x55667788) PASS(); else FAIL();
    if (sram[11] == 0x99AABBCC) PASS(); else FAIL();

    // ================================================================
    // 8. 交叉外设测试
    // ================================================================
    BB_CTRL = 0xAAAAAAAA;
    AES_KEY0 = 0xBBBBBBBB;
    EEP_CTRL = 0xCCCCCCCC;
    BB_TX_DATA = 0xDDDDDDDD;

    if (BB_CTRL    == 0xAAAAAAAA) PASS(); else FAIL();
    if (AES_KEY0   == 0xBBBBBBBB) PASS(); else FAIL();
    if (EEP_CTRL   == 0xCCCCCCCC) PASS(); else FAIL();
    if (BB_TX_DATA == 0xDDDDDDDD) PASS(); else FAIL();

    // ================================================================
    // 9. 同地址反复覆写
    // ================================================================
    sram[100] = 0x11111111;
    sram[100] = 0x22222222;
    sram[100] = 0x33333333;
    sram[100] = 0xF1A1DEAD;
    if (sram[100] == 0xF1A1DEAD) PASS(); else FAIL();

    // ================================================================
    // 10. APB 地址别名
    // ================================================================
    // 基带 4KB 空间内回绕
    volatile uint32_t *bb_remap = (uint32_t*)(BB_BASE + 0x20);
    *bb_remap = 0xBBBB0001;
    if (*bb_remap == 0xBBBB0001) PASS(); else FAIL();

    // AES 4KB 空间内回绕
    volatile uint32_t *aes_remap = (uint32_t*)(AES_BASE + 0x40);
    *aes_remap = 0xA0000000;
    if (*aes_remap == 0xA0000000) PASS(); else FAIL();

    // ================================================================
    // 11. AES-128 加密功能测试 (FIPS-197 标准测试向量)
    // ================================================================
    #define AES_STATUS      (*(volatile uint32_t*)(AES_BASE + 0x04))
    #define AES_DIN0        (*(volatile uint32_t*)(AES_BASE + 0x18))
    #define AES_DIN1        (*(volatile uint32_t*)(AES_BASE + 0x1C))
    #define AES_DIN2        (*(volatile uint32_t*)(AES_BASE + 0x20))
    #define AES_DIN3        (*(volatile uint32_t*)(AES_BASE + 0x24))
    #define AES_DOUT0       (*(volatile uint32_t*)(AES_BASE + 0x28))
    #define AES_DOUT1       (*(volatile uint32_t*)(AES_BASE + 0x2C))
    #define AES_DOUT2       (*(volatile uint32_t*)(AES_BASE + 0x30))
    #define AES_DOUT3       (*(volatile uint32_t*)(AES_BASE + 0x34))

    // 设置密钥 (FIPS-197 Appendix B)
    AES_KEY0 = 0x2b7e1516;
    AES_KEY1 = 0x28aed2a6;
    AES_KEY2 = 0xabf71588;
    AES_KEY3 = 0x09cf4f3c;

    // 设置明文
    AES_DIN0 = 0x6bc1bee2;
    AES_DIN1 = 0x2e409f96;
    AES_DIN2 = 0xe93d7e11;
    AES_DIN3 = 0x7393172a;

    // 启动加密 (bit31=START, bit0=ENCRYPT)
    AES_CTRL = 0x80000001;

    // 轮询等待完成 (最多等 1000 次)
    volatile int timeout = 1000;
    while ((AES_STATUS & 0x1) && timeout > 0) timeout--;  // BUSY
    while (!(AES_STATUS & 0x2) && timeout > 0) timeout--;  // DONE

    // 验证密文: 预期 3ad77bb4 0d7a3660 a89ecaf3 2466ef97
    if (AES_DOUT0 == 0x3ad77bb4) PASS(); else FAIL();
    if (AES_DOUT1 == 0x0d7a3660) PASS(); else FAIL();
    if (AES_DOUT2 == 0xa89ecaf3) PASS(); else FAIL();
    if (AES_DOUT3 == 0x2466ef97) PASS(); else FAIL();

    // ================================================================
    // 12. AES-128 解密功能测试
    // ================================================================
    // 输入密文
    AES_DIN0 = 0x3ad77bb4;
    AES_DIN1 = 0x0d7a3660;
    AES_DIN2 = 0xa89ecaf3;
    AES_DIN3 = 0x2466ef97;

    // 启动解密 (bit31=START, bit1=DECRYPT)
    AES_CTRL = 0x80000002;

    timeout = 1000;
    while ((AES_STATUS & 0x1) && timeout > 0) timeout--;
    while (!(AES_STATUS & 0x2) && timeout > 0) timeout--;

    // 验证明文恢复
    if (AES_DOUT0 == 0x6bc1bee2) PASS(); else FAIL();
    if (AES_DOUT1 == 0x2e409f96) PASS(); else FAIL();
    if (AES_DOUT2 == 0xe93d7e11) PASS(); else FAIL();
    if (AES_DOUT3 == 0x7393172a) PASS(); else FAIL();

    // ================================================================
    // 13. 基带 FIFO 功能测试
    // ================================================================
    #define BB_FIFO_STATUS  (*(volatile uint32_t*)(BB_BASE + 0x10))

    // 写 TX 数据到基带 FIFO
    BB_TX_DATA = 0x000000A5;
    BB_TX_DATA = 0x0000005A;
    BB_TX_DATA = 0x000000FF;

    // 验证 FIFO 非空
    uint32_t fifo_st = BB_FIFO_STATUS;
    if (!(fifo_st & 0x20000)) PASS(); else FAIL();  // TX_FIFO 不空

    // 启动基带发送 (bit1=TX_START)
    BB_CTRL = 0x00000002;

    // 等待发送完成
    timeout = 1000;
    while (!(BB_STATUS & 0x2) && timeout > 0) timeout--;
    if (BB_STATUS & 0x2) PASS(); else FAIL();  // TX_DONE

    // ================================================================
    // 14. EEPROM 控制寄存器测试
    // ================================================================
    #define EEP_STATUS      (*(volatile uint32_t*)(EEP_BASE + 0x04))

    // 设置 I2C 分频 (13.56MHz / (67+1)*2 ≈ 100kHz)
    volatile uint32_t *eep_div = (uint32_t*)(EEP_BASE + 0x14);
    *eep_div = 0x00000043;  // DIV=67

    // 配置设备地址 + 存储地址
    EEP_ADDR = 0xA0000000 | 0x00000100;
    EEP_WDATA = 0x00000042;

    // 验证寄存器写读
    if (EEP_ADDR == (0xA0000000 | 0x00000100)) PASS(); else FAIL();
    if (EEP_WDATA == 0x00000042) PASS(); else FAIL();

    // ================================================================
    // 完成 — 写成功标志
    // ================================================================
    if (*test_result == RESULT_PASS) {
        *test_result = RESULT_PASS;  // 最终确认
    }
    // 死循环等待 (CPU 休眠)
    while (1) {
        asm volatile ("wfi");
    }
}
