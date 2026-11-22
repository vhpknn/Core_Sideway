//+------------------------------------------------------------------+
//|                                                  RangeBot_EA.mq5 |
//|  โครงเปล่าของกลยุทธ์ใหม่ บน EA Platform Core                      |
//|  ไม่มีตรรกะเทรด: คอมไพล์ได้ แนบกราฟได้ มี Panel และระบบ Core ครบ     |
//|  โครงนี้ทำตามรูปแบบ Hedge_EA.mq5 (ดู reference/Hedge_example/)       |
//+------------------------------------------------------------------+
#property copyright   "EA Platform Core - RangeBot"
#property version     "1.00"
#property description "RangeBot strategy skeleton (no trading logic)"

#define BUILD_DIRECT

//--- ค่าตัวตนของกลยุทธ์ (ต้องอยู่ก่อน include Core) init_strategy แก้บรรทัดเหล่านี้
#define STRATEGY_TAG             "RNG"
#define STRATEGY_EA_ORDINAL      4
#define STRATEGY_MAGIC_BASE      40000
#define STRATEGY_MAGIC_NEXT      40001
#define STRATEGY_DEFAULT_COMMENT "RNG40000 H1 base"

#define CORE_LOG_PREFIX          "RangeBot:"

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

#include "include/RangeBot_Inputs.mqh"
#include "include/RangeBot_Regime.mqh"
#include "include/RangeBot_Range.mqh"
#include "include/RangeBot_Strategy.mqh"

//--- Panel: ใช้ของ Core หรือสำเนาเฉพาะกลยุทธ์ (D-14) ถ้า define STRATEGY_OWN_PANEL
#ifdef STRATEGY_OWN_PANEL
   #include "include/RangeBot_Panel.mqh"
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
   RbOnDeinit();
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