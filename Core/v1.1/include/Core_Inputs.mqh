//+------------------------------------------------------------------+
//|                                                 Core_Inputs.mqh  |
//|  Core v1.0 - Input ของ Core ทั้งหมดอยู่ที่ไฟล์นี้ที่เดียว           |
//|  ที่มา: Hedge1_Inputs.mqh (dcf4a12) ตัด Legacy Import ตามมติ D-01 |
//|                                                                  |
//|  EA หลักต้อง #define ค่าต่อไปนี้ก่อน #include ไฟล์นี้:             |
//|    STRATEGY_TAG             แท็กกลยุทธ์ 3 ตัวอักษร เช่น "HDG"      |
//|    STRATEGY_MAGIC_BASE      Magic ฐานของ EA เช่น 10000            |
//|    STRATEGY_DEFAULT_COMMENT Comment ตั้งต้น เช่น "HDG10000 base"   |
//+------------------------------------------------------------------+
#ifndef CORE_INPUTS_MQH
#define CORE_INPUTS_MQH

#ifndef STRATEGY_TAG
   #error "Core_Inputs: ต้อง #define STRATEGY_TAG ก่อน include"
#endif

#ifndef STRATEGY_MAGIC_BASE
   #error "Core_Inputs: ต้อง #define STRATEGY_MAGIC_BASE ก่อน include"
#endif

#ifndef STRATEGY_DEFAULT_COMMENT
   #error "Core_Inputs: ต้อง #define STRATEGY_DEFAULT_COMMENT ก่อน include"
#endif

//--- ภาษาของหน้า Inputs: ถ้า define INPUT_LANG_EN ใน EA จะใช้ป้ายอังกฤษจาก Core_InputsEN.mqh
#ifdef INPUT_LANG_EN
   #include "Core_InputsEN.mqh"
#else

//--- โหมด Auto Break-even (3 ตัวเลือก)
enum ENUM_BE_MODE
  {
   BE_OFF      = 0,   // false (ปิดใช้งาน)
   BE_FIXED    = 1,   // ไม่เลื่อน (ตั้ง SL ครั้งเดียว แล้วหยุด)
   BE_TRAILING = 2    // เลื่อนตาม (SL ขยับตามราคา)
  };

//====================== 1. Virtual Capital Auto-Lot ==============
input group "=== 1. Virtual Capital Auto-Lot ==="
input int    InpPointDigits     = 2;      // ทศนิยมตำแหน่ง Point ของคู่เงินตาม Broker (เช่น XAUUSD 2 ตำแหน่ง: 1 Point = $0.01)
input double InpInitialCapital  = 50.0;   // ทุนเริ่มต้นจำลองต่อบอท ($)
input double InpRefillAmount    = 10.0;   // กดปุ่ม REFILL หนึ่งครั้ง เพิ่มทุนเสมือน ($)
input double InpBaseLot         = 0.01;   // ขนาด Lot เริ่มต้น
input bool   InpAutoLot         = true;   // เปิดระบบคำนวณ Lot อัตโนมัติ
input double InpLotStepMoney    = 50.0;   // ขึ้นบันไดเพิ่ม Lot ทุกๆ ($)
input double InpLotIncrement    = 0.01;   // ขนาด Lot ที่เพิ่มขึ้นบันได
input bool   InpLockProfit      = false;  // Lock กำไร: กำไรไม่เพิ่มทุนเทรด (ขาดทุนลดทุน)
input int    InpMaxLotStep      = 4;      // Lot สูงสุดที่อนุญาต คูณ 0.01 (เช่น 4 = ไม่เกิน 0.04 / 0 = ไม่จำกัด)

//====================== 2. Entry Gates & Auto Refill ==============
input group "=== 2. Entry Gates & Auto Refill ==="
input bool   InpUseTimeout      = true;   // ใช้ Timeout บังคับเปิดรอบใหม่
input int    InpTimeoutSeconds  = 300;    // Timeout บังคับเปิดรอบใหม่ (วินาที)
input bool   InpUseSpreadCheck  = true;   // ใช้ตรวจสเปรดก่อนเปิด
input int    InpMaxSpreadPoints = 25;     // สเปรดสูงสุดที่ยอมให้เปิด (Points)
input int    InpDeviationPoints = 10;     // ค่าเบี่ยงเบนราคาสูงสุดตอนส่งคำสั่ง (Points)

//====================== 3. Profit Protection & TP Controls =========
input group "=== 3. Profit Protection & TP Controls ==="
input int    InpCutLossPoints   = 1000;   // ตัดขาดทุนรายไม้เมื่อผิดทาง (Points)
input ENUM_BE_MODE InpBreakEvenMode = BE_TRAILING; // เปิดใช้งาน Auto Break-even แบบสัดส่วน
input double InpBreakEvenPct    = 20.0;   // % ของ Trigger (ล็อกกำไรตามสัดส่วน)
input int    InpBreakEvenTrigger= 1000;   // เริ่มกันทุนเมื่อราคาบวกถึง (Points)
input int    InpBreakEvenStep   = 100;    // ขยับเลื่อน SL ทุกๆ (Points) - ใช้เฉพาะโหมดเลื่อนตาม
input double InpRRPercent       = 200.0;  // เป้ากำไรต่อ Order R:R (% ของ Break-even Trigger) | 200%=ปิดที่ +2000 Points
input bool   InpUseTrailingTP   = true;   // เปิดระบบ Trailing TP ตามราคาที่ดีที่สุด
input int    InpTrailingPullback= 500;    // ระยะย้อนกลับจากราคาดีที่สุดก่อนปิด (Points)

//====================== 4. Sessions (ช่วงเวลาหยุดเทรด) ============
input group "=== 4. Sessions ช่วงเวลาหยุดเทรด (true = หยุดช่วงนี้) ==="
input bool   InpSession1Block   = false;  // Sessions 1: เปิดใช้ช่วงหยุดนี้
input string InpSession1Start   = "01:00";// เวลาเริ่ม (เซิร์ฟเวอร์)
input string InpSession1End     = "04:00";// เวลาจบ (เริ่มวันใหม่)
input bool   InpSession2Block   = false;  // Sessions 2: เปิดใช้ช่วงหยุดนี้
input string InpSession2Start   = "07:00";// เวลาเริ่ม (เซิร์ฟเวอร์)
input string InpSession2End     = "12:00";// เวลาจบ
input bool   InpSession3Block   = false;  // Sessions 3: เปิดใช้ช่วงหยุดนี้
input string InpSession3Start   = "21:00";// เวลาเริ่ม (เซิร์ฟเวอร์)
input string InpSession3End     = "24:00";// เวลาจบ (ปิดรอบวัน)

//====================== 5. System Identity & Blackbox =============
input group "=== 5. System Identity & Blackbox ==="
input long   InpMagicNumber     = STRATEGY_MAGIC_BASE;     // รหัสประจำตัว Magic Number (ช่วงตาม MAGIC_REGISTRY)
input string InpTradeComment    = STRATEGY_DEFAULT_COMMENT; // คอมเมนต์ประจำตัว รูปแบบ <TAG><Magic> <ข้อความ> (แสดงบน Panel)
input bool   InpIdentityCheck   = false;  // ตรวจป้ายชื่อ Identity: true = เตือนเมื่อ Comment/Magic ไม่ตรงรูปแบบ <TAG><Magic> | false = ปิด ไม่เตือนเลย (ใช้ Magic อิสระได้)
input bool   InpEnableReport    = true;   // สรุปรายงานกำไรขาดทุนเป็นไฟล์ CSV
input int    InpReportDays      = 5;      // สร้าง CSV ทุกกี่วัน (เมื่อ Basket ว่าง)

#endif // INPUT_LANG_EN

#endif // CORE_INPUTS_MQH