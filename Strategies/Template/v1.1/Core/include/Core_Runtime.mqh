//+------------------------------------------------------------------+
//|                                                 Core_Runtime.mqh |
//|  ลำดับการทำงานของ EA: ตรวจชนิดบัญชี + ตรวจ Input + เริ่มโมดูล      |
//|  + วนทำงานทุก Tick + ปิดระบบ (ใช้ร่วมกันทุกกลยุทธ์)                |
//|  ที่มา: OnInit / OnTick / OnDeinit ใน Hedge1.0.mq5 (dcf4a12)      |
//|  EA หลักต้อง include Panel (Core_Panel หรือสำเนาของกลยุทธ์)         |
//|  ก่อน include ไฟล์นี้                                             |
//+------------------------------------------------------------------+
#ifndef CORE_RUNTIME_MQH
#define CORE_RUNTIME_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"
#include "Core_Capital.mqh"
#include "Core_Basket.mqh"
#include "Core_Report.mqh"
#include "Core_Trade.mqh"
#include "Core_Protect.mqh"
#include "Core_Pause.mqh"
#include "Core_Engine.mqh"
#include "Core_StrategyAPI.mqh"
#include "Core_Identity.mqh"
#include "Core_Lock.mqh"

//+------------------------------------------------------------------+
//| ตรวจชนิดบัญชีเทียบกับที่กลยุทธ์รองรับ (มติ D-02)                  |
//| ตอนนี้ปฏิเสธเมื่อไม่ตรงเหมือนเดิม (พฤติกรรม Market ทำใน Phase 5)  |
//+------------------------------------------------------------------+
bool CoreCheckAccount()
  {
   ENUM_ACCT_SUPPORT support = Strategy_AccountSupport();

   if(support == ACCT_ANY)
      return(true);

   long marginMode = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   bool isHedging = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);

   bool ok = (support == ACCT_HEDGING_ONLY) ? isHedging : !isHedging;

   if(ok)
      return(true);

   Alert(CORE_LOG_PREFIX, " ชนิดบัญชีไม่ตรงกับที่กลยุทธ์ ", Strategy_Title(),
         " รองรับ | ต้องการ: ",
         (support == ACCT_HEDGING_ONLY ? "Hedging" : "Netting"),
         " | บัญชีนี้: ",
         (isHedging ? "Hedging" : "Netting/Exchange"));

   return(false);
  }

//+------------------------------------------------------------------+
//| ตรวจค่า Input พื้นฐานกันพลาดตั้งแต่ต้น                              |
//| คืน INIT_SUCCEEDED หรือรหัสผิดพลาดตามเดิม                          |
//+------------------------------------------------------------------+
int CoreValidateInputs()
  {
   if(InpPointDigits < 0 || InpPointDigits > 8)
     {
      Alert(CORE_LOG_PREFIX, " ตั้ง InpPointDigits ได้แค่ 0-8 เท่านั้น");
      return(INIT_FAILED);
     }
   if(InpLotIncrement <= 0.0 || InpLotStepMoney <= 0.0)
     {
      Alert(CORE_LOG_PREFIX, " ค่า Lot Step / เงินต่อบันได ต้องมากกว่า 0");
      return(INIT_FAILED);
     }
   if(InpCutLossPoints <= 0)
     {
      Alert(CORE_LOG_PREFIX, " Cut Loss Points ต้องมากกว่า 0 เสมอ");
      return(INIT_FAILED);
     }

   //--- Trigger ใช้ทั้ง Break-even และ RR
   if(InpBreakEvenTrigger <= 0
      && (InpBreakEvenMode != BE_OFF || InpRRPercent > 0.0))
     {
      Alert(CORE_LOG_PREFIX, " Break-even Trigger ต้องมากกว่า 0 ถ้าเปิดใช้ BE หรือ RR");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- ป้องกันหารด้วยศูนย์ใน BE แบบเลื่อนตาม
   if(InpBreakEvenMode == BE_TRAILING && InpBreakEvenStep <= 0)
     {
      Alert(CORE_LOG_PREFIX, " Break-even Step ต้องมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- 0% อนุญาตให้ใช้ล็อกที่ราคาเข้า
   //--- ไม่รับ 100% ขึ้นไป ซึ่งตั้ง SL ถึงหรือเลยราคาปัจจุบัน
   if(InpBreakEvenMode != BE_OFF
      && (!MathIsValidNumber(InpBreakEvenPct)
          || InpBreakEvenPct < 0.0
          || InpBreakEvenPct >= 100.0))
     {
      Alert(CORE_LOG_PREFIX, " Break-even Percent ต้องอยู่ในช่วง 0 ถึงน้อยกว่า 100");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- RR = 0 หมายถึงปิด RR
   if(!MathIsValidNumber(InpRRPercent) || InpRRPercent < 0.0)
     {
      Alert(CORE_LOG_PREFIX, " RR Percent ต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(InpUseTrailingTP && InpTrailingPullback <= 0)
     {
      Alert(CORE_LOG_PREFIX, " Trailing Pullback ต้องมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- Timeout = 0 อนุญาต แต่ห้ามติดลบ
   if(InpUseTimeout && InpTimeoutSeconds < 0)
     {
      Alert(CORE_LOG_PREFIX, " Timeout Seconds ต้องไม่ติดลบ");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(InpUseSpreadCheck && InpMaxSpreadPoints < 0)
     {
      Alert(CORE_LOG_PREFIX, " Max Spread Points ต้องไม่ติดลบ");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(InpDeviationPoints < 0)
     {
      Alert(CORE_LOG_PREFIX, " Deviation Points ต้องไม่ติดลบ");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(InpEnableReport && InpReportDays <= 0)
     {
      Alert(CORE_LOG_PREFIX, " Report Days ต้องมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- ไม่ใช้ Magic 0 ซึ่งอาจปะปนกับ Position แบบ Manual ภายนอก
   if(InpMagicNumber <= 0)
     {
      Alert(CORE_LOG_PREFIX, " Magic Number ต้องมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(!MathIsValidNumber(InpBaseLot) || InpBaseLot <= 0.0)
     {
      Alert(CORE_LOG_PREFIX, " Base Lot ต้องเป็นตัวเลขมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(!MathIsValidNumber(InpLotIncrement)
      || !MathIsValidNumber(InpLotStepMoney)
      || InpLotIncrement <= 0.0
      || InpLotStepMoney <= 0.0)
     {
      Alert(CORE_LOG_PREFIX, " Lot Increment และ Lot Step Money ต้องเป็นตัวเลขมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(InpMaxLotStep < 0)
     {
      Alert(CORE_LOG_PREFIX, " Max Lot Step ต้องไม่ติดลบ");
      return(INIT_PARAMETERS_INCORRECT);
     }

   //--- ทุนเริ่มต้น 0 อนุญาตสำหรับทดสอบทุนหมดและ REFILL
   if(!MathIsValidNumber(InpInitialCapital)
      || InpInitialCapital < 0.0)
     {
      Alert(CORE_LOG_PREFIX, " Initial Capital ต้องเป็นตัวเลขตั้งแต่ 0 ขึ้นไป");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(!MathIsValidNumber(InpRefillAmount)
      || InpRefillAmount <= 0.0)
     {
      Alert(CORE_LOG_PREFIX, " Refill Amount ต้องเป็นตัวเลขมากกว่า 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| เริ่มระบบ (เรียกจาก OnInit ของ EA หลัก)                            |
//+------------------------------------------------------------------+
int CoreOnInit()
  {
   //--- ตรวจว่าบัญชีเป็นชนิดที่กลยุทธ์รองรับ
   if(!CoreCheckAccount())
      return(INIT_FAILED);

   //--- ตรวจค่า input พื้นฐานกันพลาดตั้งแต่ต้น
   int rc = CoreValidateInputs();

   if(rc != INIT_SUCCEEDED)
      return(rc);

   //--- ตรวจป้ายชื่อ EA (TAG / Magic / Comment) เตือนอย่างเดียว ไม่หยุดโหลด
   CoreCheckIdentity();

   //--- ตรวจ Trailing State Key ก่อนเริ่ม Engine
   if(!ProtectInit())
      return(INIT_FAILED);

   //--- ตรวจ REFILL / Report / Cycle State
   if(!CoreStateInit())
      return(INIT_FAILED);

   //--- สตาร์ทแต่ละโมดูล
   //--- ป้องกันแนบ EA ซ้ำ Magic เดียวกัน (D-27) พบซ้ำ = หยุดตัวที่แนบทีหลัง
   if(!CoreLockAcquire())
      return(INIT_FAILED);

   EngineInit();      // ตั้งค่าการส่งออเดอร์ (Magic/Deviation/Filling)
   ReportInit();      // เริ่มนับรอบรายงาน CSV
   CorePauseInit();   // กู้สถานะปุ่ม ON/OFF

   if(!Strategy_Init())
     {
      Alert(CORE_LOG_PREFIX, " Strategy_Init ล้มเหลว: ", Strategy_Title());
      return(INIT_FAILED);
     }

   PanelInit();       // สร้าง Panel + ปุ่มทั้งหมด

   Print(CORE_LOG_PREFIX, " เริ่มระบบสำเร็จ | ", _Symbol,
         " | Point=", DoubleToString(CorePoint(), _Digits),
         " | ทุนเริ่มต้น=$", DoubleToString(InpInitialCapital, 2));

   Print(CORE_LOG_PREFIX, " Strategy=", Strategy_Title(),
         " v", Strategy_Version(),
         " | TAG=", STRATEGY_TAG,
         " | Magic=", InpMagicNumber);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| ทำงานทุก Tick - ลำดับสำคัญ: บริหารไม้เดิมก่อน แล้วค่อยเปิดใหม่      |
//+------------------------------------------------------------------+
void CoreOnTick()
  {
   //--- 1) บริหาร Position เดิมก่อนเสมอ
   ProtectOnTick();

   //--- เริ่มนับ Timeout เมื่อพบ Basket ว่าง
   //--- ไม่รอให้ Report เสร็จก่อนเริ่มจับเวลาว่าง
   if(CoreBasketPositions() == 0)
     {
      if(g_emptySince == 0)
         g_emptySince = TimeCurrent();
     }

   //--- 2) ให้ Report ตรวจช่วง Basket ว่างก่อนเปิดรอบใหม่
   ReportOnTick();

   //--- 3) กลยุทธ์ตัดสินใจเข้าออเดอร์ (ผ่านประตู Gate ของ Core)
   Strategy_OnTick();

   //--- 4) แสดงสถานะหลังจัดการรอบนี้
   PanelUpdate();
  }

//+------------------------------------------------------------------+
//| ปิดระบบ (เรียกจาก OnDeinit ของ EA หลัก)                            |
//+------------------------------------------------------------------+
void CoreOnDeinit(const int reason)
  {
   //--- คง State ของ Position ที่ยังเปิดไว้
   GlobalVariablesFlush();

   CoreLockRelease();   // ปล่อยล็อก D-27 (เฉพาะเจ้าของ)
   PanelDeinit();   // ลบวัตถุ Panel ออกจากกราฟ
   Print(CORE_LOG_PREFIX, " ปิดระบบแล้ว (เหตุผล ", reason, ")");
  }

#endif // CORE_RUNTIME_MQH