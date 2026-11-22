//+------------------------------------------------------------------+
//|                                                  Template_EA.mq5 |
//|  โครงเปล่าของกลยุทธ์ใหม่ บน EA Platform Core                      |
//|  ไม่มีตรรกะเทรด: คอมไพล์ได้ แนบกราฟได้ มี Panel และระบบ Core ครบ     |
//|  tools/init_strategy.py จะเปลี่ยนคำว่า Template / TPL และค่าตัวตน     |
//|  โครงนี้ทำตามรูปแบบ Hedge_EA.mq5 (ดู reference/Hedge_example/)       |
//+------------------------------------------------------------------+
#property copyright   "EA Platform Core - Template"
#property version     "1.00"
#property description "Template strategy skeleton (no trading logic)"

#define BUILD_DIRECT

//--- ค่าตัวตนของกลยุทธ์ (ต้องอยู่ก่อน include Core) init_strategy แก้บรรทัดเหล่านี้
#define STRATEGY_TAG             "TPL"
#define STRATEGY_EA_ORDINAL      9
#define STRATEGY_MAGIC_BASE      90000
#define STRATEGY_MAGIC_NEXT      90001
#define STRATEGY_DEFAULT_COMMENT "TPL90000 H1 base"

#define CORE_LOG_PREFIX          "Template:"

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

#include "include/Template_Inputs.mqh"
#include "include/Template_Strategy.mqh"

//--- Panel: ใช้ของ Core หรือสำเนาเฉพาะกลยุทธ์ (D-14) ถ้า define STRATEGY_OWN_PANEL
#ifdef STRATEGY_OWN_PANEL
   #include "include/Template_Panel.mqh"
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