//+------------------------------------------------------------------+
//|                                              RangeBot_Inputs.mqh |
//|  Input เฉพาะกลยุทธ์ (ตอนนี้ยังไม่มี)                              |
//|  กติกา: ต้องมีสองภาษา ชื่อ ชนิด ลำดับ ค่าเริ่มต้นเหมือนกัน       |
//|  ตัวอย่างรูปแบบ ดู Hedge_Inputs.mqh ใน reference/Hedge_example/     |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_INPUTS_MQH
#define RANGEBOT_INPUTS_MQH

//--- ชนิดบัญชีที่อนุญาตให้ RangeBot ทำงาน (เลือกใน Input)
#ifdef INPUT_LANG_EN
enum ENUM_RB_ACCOUNT_MODE
  {
   RB_ACCT_AUTO    = 0,   // AUTO (Hedging or Netting)
   RB_ACCT_HEDGING = 1,   // HEDGING accounts only
   RB_ACCT_NETTING = 2    // NETTING accounts only
  };
#else
enum ENUM_RB_ACCOUNT_MODE
  {
   RB_ACCT_AUTO    = 0,   // อัตโนมัติ (Hedging หรือ Netting)
   RB_ACCT_HEDGING = 1,   // เฉพาะบัญชี Hedging
   RB_ACCT_NETTING = 2    // เฉพาะบัญชี Netting
  };
#endif

input group "=== R. RangeBot ==="
#ifdef INPUT_LANG_EN
input ENUM_RB_ACCOUNT_MODE InpRbAccountMode = RB_ACCT_AUTO;   // InpRbAccountMode - Account type allowed (AUTO = Hedging or Netting)
#else
input ENUM_RB_ACCOUNT_MODE InpRbAccountMode = RB_ACCT_AUTO;   // ชนิดบัญชีที่อนุญาต (AUTO = Hedging หรือ Netting ก็ได้)
#endif

#endif // RANGEBOT_INPUTS_MQH