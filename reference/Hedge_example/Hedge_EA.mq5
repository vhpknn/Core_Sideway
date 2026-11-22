//+------------------------------------------------------------------+
//|                                                     Hedge_EA.mq5 |
//|  EA Hedge 1.0 บน EA Platform Core                                |
//|  โครงสร้าง: Core (สำเนา CLEAN ใน Core/include) + ตลับ Hedge       |
//|  ลำดับการทำงานทุก Tick อยู่ใน Core_Runtime.mqh                     |
//+------------------------------------------------------------------+
#property copyright   "EA Platform Core - Hedge"
#property version     "1.00"
#property description "EA Hedge 1.0 - XAUUSD Hedge (Buy+Sell) with Virtual Capital"
#property description "Cut Loss / Auto Break-even / R:R / Trailing TP / Sessions / CSV Report"

//--- โปรไฟล์คอมไพล์ (โครงเปล่าตาม D-16 ยังไม่มีพฤติกรรมตามโปรไฟล์)
#define BUILD_DIRECT



//--- ค่ากำหนดของกลยุทธ์ (ต้องอยู่ก่อน include Core)
#define STRATEGY_TAG             "HDG"
#define STRATEGY_EA_ORDINAL      1
#define STRATEGY_MAGIC_BASE      10000
#define STRATEGY_MAGIC_NEXT      10023
#define STRATEGY_DEFAULT_COMMENT "HDG10000 H1 base"

//--- คำนำหน้า Log ของ Hedge ใช้แบบเดิมเพื่อเทียบ Log และให้ Collector อ่านต่อได้
#define CORE_LOG_PREFIX          "Hedge1:"

#include "Core/include/Core_Inputs.mqh"
#include "Core/include/Core_Utils.mqh"
#include "Core/include/Core_Capital.mqh"
#include "Core/include/Core_Session.mqh"
#include "Core/include/Core_Basket.mqh"
#include "Core/include/Core_Report.mqh"
#include "Core/include/Core_Trade.mqh"
#include "Core/include/Core_Protect.mqh"
#include "Core/include/Core_Pause.mqh"
#include "Core/include/Core_Engine.mqh"
#include "Core/include/Core_StrategyAPI.mqh"
#include "Core/include/Core_Identity.mqh"
#include "Core/include/CoreUI_Theme.mqh"

#include "include/Hedge_Inputs.mqh"
#include "include/Hedge_Strategy.mqh"

//--- Panel: ใช้ของ Core หรือสำเนาเฉพาะกลยุทธ์ (D-14) ถ้า define STRATEGY_OWN_PANEL
#ifdef STRATEGY_OWN_PANEL
   #include "include/Hedge_Panel.mqh"
#else
   #include "Core/include/Core_Panel.mqh"
#endif

#include "Core/include/Core_Runtime.mqh"

int OnInit()
  {
   return(CoreOnInit());
  }

void OnDeinit(const int reason)
  {
   CoreOnDeinit(reason);
  }

void OnTick()
  {
   CoreOnTick();
  }

void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
   PanelOnChartEvent(id, lparam, dparam, sparam);
  }