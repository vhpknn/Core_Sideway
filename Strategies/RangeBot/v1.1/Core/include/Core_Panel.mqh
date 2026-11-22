//+------------------------------------------------------------------+
//|                                                   Core_Panel.mqh |
//|  Responsive Panel: ข้อมูลสถานะ + ปุ่มมาตรฐาน + ช่องปุ่มกลยุทธ์     |
//|  + ปุ่ม ON/OFF ต่อกราฟ + แถว Entry + แถวเตือน Identity            |
//|  รองรับกราฟขนาดเล็ก / ปรับ layout เมื่อย่อหรือขยายหน้าต่าง        |
//|  ที่มา: Hedge1_Panel.mqh (dcf4a12) ส่วนของ Hedge ย้ายเป็นปุ่ม      |
//|  ของกลยุทธ์ผ่าน Core_StrategyAPI                                  |
//|  สัญญาที่สำเนา Panel เฉพาะกลยุทธ์ (D-14) ต้องคงไว้:               |
//|    PanelInit, PanelDeinit, PanelUpdate, PanelOnChartEvent        |
//+------------------------------------------------------------------+
#ifndef CORE_PANEL_MQH
#define CORE_PANEL_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"
#include "Core_Capital.mqh"
#include "Core_Session.mqh"
#include "Core_Basket.mqh"
#include "Core_Trade.mqh"
#include "Core_Engine.mqh"
#include "Core_Pause.mqh"
#include "Core_StrategyAPI.mqh"
#include "Core_Identity.mqh"
#include "CoreUI_Theme.mqh"

//--- ฟอนต์หัวข้อกลุ่ม (ธีมไม่ได้กำหนด ใช้ค่าเดิมของ Panel)
#ifndef CUI_FONT_SECTION
   #define CUI_FONT_SECTION 7
#endif

//--- ความสูง Panel ตามระดับ (ธีมไม่ได้กำหนด ระดับ L ใช้ CUI_PANEL_H_NORMAL)
#ifndef CUI_PANEL_H_M
   #define CUI_PANEL_H_M        266
#endif
#ifndef CUI_PANEL_H_S
   #define CUI_PANEL_H_S        192
#endif
#ifndef CUI_PANEL_PAD_BOTTOM
   #define CUI_PANEL_PAD_BOTTOM 6
#endif

//--- ความสูง Panel เมื่อเปิด Lock Profit (มีบรรทัดสถานะเพิ่ม)
#ifndef CUI_PANEL_H_M_LK
   #define CUI_PANEL_H_M_LK 278
#endif
#ifndef CUI_PANEL_H_S_LK
   #define CUI_PANEL_H_S_LK 222
#endif

//--- ระดับ Panel อัตโนมัติ
#define PANEL_TIER_L   0
#define PANEL_TIER_M   1
#define PANEL_TIER_S   2
#define PANEL_TIER_XS  3

//--- แมปชื่อสีเดิมของ Panel เข้ากับธีมกลาง (เทียบกับ Hedge1_Panel ได้ทีละบรรทัด)
#define COL_BG              CUI_BG
#define COL_BORDER          CUI_BORDER
#define COL_HEADER          CUI_HEADER
#define COL_TEXT            CUI_TEXT
#define COL_DIM             CUI_LABEL
#define COL_CYAN            CUI_CYAN
#define COL_EQUITY          CUI_GREEN
#define COL_PROFIT          CUI_GREEN
#define COL_WARN            CUI_RED
#define COL_ACTIVE          CUI_YELLOW
#define COL_BUY_TEXT        CUI_BUY_TEXT
#define COL_SELL_TEXT       CUI_SELL_TEXT
#define COL_GRAY            CUI_BTN_REFILL
#define COL_MUSTARD         CUI_BTN_CLOSE_ALL
#define COL_CLOSE_BUY_BG    CUI_BTN_CLOSE_BUY
#define COL_CLOSE_BUY_FRAME CUI_FRAME_CLOSE_BUY
#define COL_CLOSE_SELL_BG   CUI_BTN_CLOSE_SELL
#define COL_CLOSE_SELL_FRAME CUI_FRAME_CLOSE_SELL

//--- สถานะ Panel
bool g_panelReady         = false;
bool g_panelMinimized     = false;
bool g_panelAutoMinimized = false;
bool g_panelCompact       = false;
int  g_panelTier          = 0;

//--- ขนาด/ตำแหน่งที่คำนวณตามขนาดกราฟ
int g_panelX       = CUI_PANEL_X;
int g_panelY       = CUI_PANEL_Y;
int g_panelW       = CUI_PANEL_W_NORMAL;
int g_panelHFull   = CUI_PANEL_H_NORMAL;
int g_panelHMin    = CUI_PANEL_H_MIN;
int g_panelBtnX    = 252;
int g_panelBtnW    = 168;
int g_panelNameX   = 14;
int g_panelValueX  = 132;
int g_panelFont    = CUI_FONT_NORMAL;
int g_panelHeadFont= CUI_FONT_HEADER;

//--- รหัสปุ่มของกลยุทธ์ในช่อง 1-3 (ว่าง = ไม่มีปุ่มในช่องนั้น)
string g_stratBtnId[3] = {"", "", ""};

//+------------------------------------------------------------------+
//| Prefix ของ Object ป้องกันชนกับ EA/Indicator ตัวอื่น                |
//+------------------------------------------------------------------+
string PanelPrefix()
  {
   return(STRATEGY_TAG + "P_");
  }

//+------------------------------------------------------------------+
//| สร้างชื่อ Object ของ Panel                                       |
//+------------------------------------------------------------------+
string PName(string id)
  {
   return(PanelPrefix() + id);
  }

//+------------------------------------------------------------------+
//| อ่านความกว้างของกราฟเป็น Pixel                                   |
//+------------------------------------------------------------------+
int PanelChartWidth()
  {
   long width = 0;
   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, width))
      return(900);
   return((int)width);
  }

//+------------------------------------------------------------------+
//| ตรวจว่า Panel อยู่ในโหมดซ่อนรายละเอียดหรือไม่                    |
//+------------------------------------------------------------------+
bool PanelIsMinimized()
  {
   return(g_panelMinimized || g_panelAutoMinimized);
  }

//--- ความสูงของกราฟ (Pixel)
int PanelChartHeight()
  {
   long height = 0;
   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, height))
      return(800);
   return((int)height);
  }

//--- ความสูงของแต่ละระดับ (โหมด Lock สูงกว่าเล็กน้อยสำหรับ M และ S)
int PanelTierHeightOf(int tier)
  {
   if(tier == PANEL_TIER_M)
      return(InpLockProfit ? CUI_PANEL_H_M_LK : CUI_PANEL_H_M);

   if(tier >= PANEL_TIER_S)
      return(InpLockProfit ? CUI_PANEL_H_S_LK : CUI_PANEL_H_S);

   return(CUI_PANEL_H_NORMAL);
  }

//--- เลือกระดับ Panel จากขนาดกราฟ (ใหญ่สุดที่ใส่พอ)
int PanelPickTier(int chartW, int chartH)
  {
   if(chartW < CUI_PANEL_MIN_AT)
      return(PANEL_TIER_XS);

   int avail = chartH - CUI_PANEL_Y - CUI_PANEL_PAD_BOTTOM;

   if(avail >= CUI_PANEL_H_NORMAL)
      return(PANEL_TIER_L);
   if(avail >= PanelTierHeightOf(PANEL_TIER_M))
      return(PANEL_TIER_M);
   if(avail >= PanelTierHeightOf(PANEL_TIER_S))
      return(PANEL_TIER_S);

   return(PANEL_TIER_XS);
  }

//--- ความสูง Panel ของระดับปัจจุบัน
int PanelTierHeight()
  {
   return(PanelTierHeightOf(g_panelTier));
  }

//+------------------------------------------------------------------+
//| คำนวณ Layout ตามความกว้างของกราฟ                                 |
//| >=520 px : Normal                                                |
//| 330-519  : Compact ลดความกว้าง/Font                              |
//| <330 px  : Auto Minimize เพื่อไม่ให้ Panel ล้นจอ                  |
//+------------------------------------------------------------------+
bool PanelRefreshLayoutMetrics()
  {
   int chartW = PanelChartWidth();

   bool oldCompact = g_panelCompact;
   bool oldAutoMin = g_panelAutoMinimized;
   int  oldW       = g_panelW;
   int  oldH       = g_panelHFull;
   int  oldTier    = g_panelTier;
   int  chartH     = PanelChartHeight();

   g_panelCompact       = (chartW < CUI_PANEL_COMPACT_AT);
   g_panelTier          = PanelPickTier(chartW, chartH);
   g_panelAutoMinimized = (chartW < CUI_PANEL_MIN_AT)
                          || (g_panelTier == PANEL_TIER_XS);

   if(!g_panelCompact)
     {
      //--- Normal Mode: ขยาย Panel เพื่อให้ตัวหนังสือฝั่งซ้ายอ่านสบาย
      g_panelW        = CUI_PANEL_W_NORMAL;
      g_panelHFull    = PanelTierHeight();

      //--- ขยับฝั่งปุ่มไปขวา และขยายปุ่มเล็กน้อย
      g_panelBtnX     = 252;
      g_panelBtnW     = 168;

      //--- เพิ่มพื้นที่ให้ชื่อและค่าฝั่งซ้าย
      g_panelNameX    = 14;
      g_panelValueX   = 132;

      //--- Font ปกติและ Header ใหญ่ขึ้น
      g_panelFont     = CUI_FONT_NORMAL;
      g_panelHeadFont = CUI_FONT_HEADER;
     }
   else
     {
      //--- เว้นขอบซ้าย/ขวา 8 px เสมอ แต่ไม่เล็กกว่า 300 px
      g_panelW        = chartW - 16;
      if(g_panelW < 300)
         g_panelW = 300;
      if(g_panelW > 360)
         g_panelW = 360;

      g_panelHFull    = PanelTierHeight();
      g_panelBtnX     = 192;
      g_panelBtnW     = g_panelW - g_panelBtnX - 8;
      g_panelNameX    = 12;
      g_panelValueX   = 104;

      //--- Compact ยังต้องอ่านได้ ไม่ลดเล็กเกินไป
      g_panelFont     = CUI_FONT_NORMAL_C;
      g_panelHeadFont = CUI_FONT_HEADER_C;
     }

   g_panelX = CUI_PANEL_X;
   g_panelY = CUI_PANEL_Y;

   return(oldCompact != g_panelCompact ||
          oldAutoMin != g_panelAutoMinimized ||
          oldW != g_panelW ||
          oldH != g_panelHFull ||
          oldTier != g_panelTier);
  }

//+------------------------------------------------------------------+
//| ลบ Object เฉพาะของ Panel นี้                                     |
//+------------------------------------------------------------------+
void PanelDeleteObjects()
  {
   ObjectsDeleteAll(0, PanelPrefix(), -1, -1);
  }

//+------------------------------------------------------------------+
//| สร้าง/อัปเดต Label                                                |
//+------------------------------------------------------------------+
void PanelLabel(string id,
                string text,
                int x,
                int y,
                color clr,
                int fontSize = 8,
                string font = CUI_FONT)
  {
   string name = PName(id);

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//| สร้างกรอบสีหนารอบปุ่ม เพื่อแยก Buy / Sell ให้เห็นชัด              |
//+------------------------------------------------------------------+
void PanelFrame(string id,
                int x,
                int y,
                int w,
                int h,
                color frameColor)
  {
   string name = PName(id);

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, frameColor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, frameColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 5);
  }

//+------------------------------------------------------------------+
//| สร้าง/อัปเดต Button                                               |
//+------------------------------------------------------------------+
void PanelButton(string id,
                 string text,
                 int x,
                 int y,
                 int w,
                 int h,
                 color bg,
                 color border,
                 int fontSize = 9)
  {
   string name = PName(id);

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, CUI_FONT);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

//+------------------------------------------------------------------+
//| เลือกสีตามสถานะตัวเลข                                            |
//| บวก = เขียว / ลบ = แดง / ศูนย์ = ขาว                            |
//+------------------------------------------------------------------+
color PanelSignColor(double value)
  {
   if(value > 0.0)
      return(COL_PROFIT);

   if(value < 0.0)
      return(COL_WARN);

   return(COL_TEXT);
  }

//+------------------------------------------------------------------+
//| อัปเดตข้อความและสี Label                                         |
//+------------------------------------------------------------------+
void PanelSet(string id, string text, color clr)
  {
   string name = PName(id);
   if(ObjectFind(0, name) < 0)
      return;

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

//+------------------------------------------------------------------+
//| ซ่อน/แสดง Object บนกราฟจริง                                      |
//| ใช้ Timeframes = 0 เพื่อซ่อนจริง ไม่ใช่แค่ซ่อนจาก Object List     |
//+------------------------------------------------------------------+
void PanelSetVisible(string id, bool show)
  {
   string name = PName(id);
   if(ObjectFind(0, name) < 0)
      return;

   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES,
                    show ? OBJ_ALL_PERIODS : 0);
  }

//+------------------------------------------------------------------+
//| เปลี่ยนข้อความ Footer ให้ขึ้นบรรทัดใหม่ก่อน [ ... ]              |
//+------------------------------------------------------------------+
string PanelFooterText()
  {
   string footer = InpTradeComment;

   int bracketPos = StringFind(footer, "[");
   if(bracketPos > 0)
     {
      string leftPart  = StringSubstr(footer, 0, bracketPos);
      string rightPart = StringSubstr(footer, bracketPos);
      StringTrimRight(leftPart);
      footer = leftPart + "\n" + rightPart;
     }

   return(footer);
  }

//+------------------------------------------------------------------+
//| กำไรลอยตัวรวมของ EA นี้                                           |
//+------------------------------------------------------------------+
double GetFloatingPL()
  {
   double sum = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      sum += PositionGetDouble(POSITION_PROFIT);
      sum += PositionGetDouble(POSITION_SWAP);
     }

   return(sum);
  }

//+------------------------------------------------------------------+
//| Cycle Loss: ขาดทุนปิดแล้วในรอบ Basket ปัจจุบัน                   |
//+------------------------------------------------------------------+
bool TryGetCycleLoss(double &loss)
  {
   loss = 0.0;

   string netName = CoreStateGVName("RNET");
   string startName = CoreStateGVName("CSTART");

   double baseline = 0.0;
   double startedAt = 0.0;

   //--- ไม่มีข้อมูลเริ่ม Cycle ที่ยืนยันได้ ให้แสดง N/A
   if(!GlobalVariableCheck(netName)
      || !GlobalVariableCheck(startName))
      return(false);

   if(!GlobalVariableGet(startName, startedAt)
      || !MathIsValidNumber(startedAt)
      || startedAt <= 0.0)
      return(false);

   if(!GlobalVariableGet(netName, baseline)
      || !MathIsValidNumber(baseline))
      return(false);

   double closedNet = 0.0;

   if(!TryGetClosedNet(closedNet))
      return(false);

   double cycleNet = closedNet - baseline;

   if(!MathIsValidNumber(cycleNet))
      return(false);

   //--- แสดงเฉพาะผลขาดทุนที่บันทึกเป็นดีลแล้ว
   loss = MathMin(cycleNet, 0.0);

   return(true);
  }

//+------------------------------------------------------------------+
//| ปุ่ม ON/OFF: อัปเดตข้อความและสีตามสถานะ (ON = เขียว / OFF = แดง)   |
//+------------------------------------------------------------------+
//--- สีเทาของปุ่ม ON/OFF เมื่อ EA เทรดไม่ได้ (ธีมไม่ได้กำหนด)
#ifndef CUI_BTN_DISABLED
   #define CUI_BTN_DISABLED C'128,128,128'
#endif

//+------------------------------------------------------------------+
//| เหตุผลที่ EA เทรดไม่ได้ (ว่าง = เทรดได้)                          |
//+------------------------------------------------------------------+
string CorePanelTradeBlockReason()
  {
   if(!(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return("AutoTrading ในโปรแกรมปิดอยู่");

   if(!(bool)MQLInfoInteger(MQL_TRADE_ALLOWED))
      return("Allow Algo Trading ของ EA นี้ปิดอยู่");

   if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      return("บัญชีนี้ปิดการเทรด");

   if(!(bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      return("โบรกเกอร์ไม่อนุญาตให้ EA เทรดบนบัญชีนี้");

   return("");
  }

void PanelUpdatePower()
  {
   string name = PName("B_PWR");

   if(ObjectFind(0, name) < 0)
      return;

   bool paused = CoreIsPaused();
   string blocked = CorePanelTradeBlockReason();
   color bg = (blocked != "") ? CUI_BTN_DISABLED
                              : (paused ? CUI_RED : CUI_GREEN);

   ObjectSetString(0, name, OBJPROP_TEXT, paused ? "OFF" : "ON");
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, CUI_BG);
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
                   paused ? "Entry OFF: no new orders. Click to turn ON."
                          : "Entry ON. Click to turn OFF (no new orders).");
   if(blocked != "")
      ObjectSetString(0, name, OBJPROP_TOOLTIP,
                      "EA ไม่ทำงาน: " + blocked
                      + " | Entry " + (paused ? "OFF" : "ON"));
  }

//+------------------------------------------------------------------+
//| ใช้สถานะ Minimize / Responsive กับ Object ทุกตัว                 |
//| หมายเหตุ: HDR, MIN, B_PWR ไม่อยู่ในรายการ จึงเห็นเสมอแม้ย่อ Panel  |
//+------------------------------------------------------------------+
void PanelApplyVisibility()
  {
   bool showDetail = !PanelIsMinimized();

   string detailObjects[] =
     {
      "S1",
      "N_SESS", "V_SESS",
      "N_SPRD", "V_SPRD",
      "N_TIME", "V_TIME",

      "S2",
      "N_BASE", "V_BASE",
      "N_STEP", "V_STEP",
      "N_LOT",  "V_LOT",
      "N_EQ",   "V_EQ",
      "N_NET",  "V_NET",
      "N_CYC",  "V_CYC",

      "S3",
      "N_FLOAT", "V_FLOAT",

      "N_ACT",
      "V_ACT_TOTAL",
      "V_ACT_BUY",
      "V_ACT_SELL",

      "N_CUT",   "V_CUT",
      "N_GATE",  "V_GATE",
      "V_ID",

      "SB1",
      "SB2",
      "SB3",

      "F_CLBUY",
      "B_CLBUY",

      "F_CLSELL",
      "B_CLSELL",

      "B_REFILL",
      "B_CLALL",
      "FOOT"
     };

   for(int i = 0; i < ArraySize(detailObjects); i++)
      PanelSetVisible(detailObjects[i], showDetail);

   PanelSetVisible("B_RESET", showDetail);
   PanelSetVisible("LK1", showDetail);
   PanelSetVisible("LK2", showDetail);
   PanelSetVisible("LK3", showDetail);

   string bg = PName("BG");
   if(ObjectFind(0, bg) >= 0)
     {
      ObjectSetInteger(0, bg, OBJPROP_YSIZE,
                       showDetail ? g_panelHFull : g_panelHMin);
     }

   string minButton = PName("MIN");
   if(ObjectFind(0, minButton) >= 0)
      ObjectSetString(0, minButton, OBJPROP_TEXT,
                      showDetail ? "-" : "+");

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| สร้าง Panel ตาม Layout ปัจจุบัน                                   |
//+------------------------------------------------------------------+


#include "Core_PanelLayout.mqh"

//+------------------------------------------------------------------+
//| เริ่ม Panel                                                       |
//+------------------------------------------------------------------+
void PanelInit()
  {
   g_panelReady = false;
   PanelBuild();
  }

//+------------------------------------------------------------------+
//| ตรวจว่าต้อง Rebuild Panel หรือไม่ เมื่อกราฟถูกย่อ/ขยาย            |
//+------------------------------------------------------------------+
void PanelCheckResponsiveLayout()
  {
   if(!g_panelReady)
      return;

   if(PanelRefreshLayoutMetrics())
      PanelBuild();
  }

//+------------------------------------------------------------------+
//| อัปเดตข้อมูลใน Panel                                              |
//+------------------------------------------------------------------+
void PanelUpdate()
  {
   if(!g_panelReady)
      return;

   //--- STATUS
   //--- สีทั้งแถว: เขียว = ระบบเปิด/พร้อมใช้งาน, แดง = ปิดหรือถูก Block

   //--- Session: OPEN = เขียว / BLOCK = แดง
   string sessionStatus = GetSessionStatusText();
   color sessionColor = (sessionStatus == "OPEN") ? COL_PROFIT : COL_WARN;

   PanelSet("N_SESS", "Session:", sessionColor);
   PanelSet("V_SESS", sessionStatus, sessionColor);

   //--- Spread Check: ON = เขียว / OFF = แดง
   string spreadText = DoubleToString(GetSpreadPoints(), 0)
                       + (g_panelCompact ? "/" : " / Trigger ")
                       + IntegerToString(InpMaxSpreadPoints)
                       + (g_panelCompact
                          ? (InpUseSpreadCheck ? " ON" : " OFF")
                          : (InpUseSpreadCheck ? " (ON)" : " (OFF)"));

   color spreadStatusColor = InpUseSpreadCheck ? COL_PROFIT : COL_WARN;

   PanelSet("N_SPRD", "Spread:", spreadStatusColor);
   PanelSet("V_SPRD", spreadText, spreadStatusColor);

   //--- Timeout / Refill Timer: ON = เขียว / OFF = แดง
   string timerText = IntegerToString(GetTimeoutRemaining())
                      + (g_panelCompact ? "/" : " / ")
                      + IntegerToString(InpTimeoutSeconds)
                      + (g_panelCompact ? "s" : " sec")
                      + (g_panelCompact
                         ? (InpUseTimeout ? " ON" : " OFF")
                         : (InpUseTimeout ? " (ON)" : " (OFF)"));

   color timerStatusColor = InpUseTimeout ? COL_PROFIT : COL_WARN;

   PanelSet("N_TIME", "Refill Timer:", timerStatusColor);
   PanelSet("V_TIME", timerText, timerStatusColor);

   //--- LOT & CAPITAL: ไม่แสดง Error เป็นยอดเงิน 0
   double equity = 0.0;
   bool equityKnown = TryGetVirtualEquity(equity);

   double steps = 1.0;

   if(equityKnown && InpLotStepMoney > 0.0)
      steps = MathMax(1.0, MathFloor(equity / InpLotStepMoney));

   PanelSet("V_BASE", DoubleToString(InpBaseLot, 2), COL_TEXT);

   PanelSet("V_STEP",
            "+" + DoubleToString(InpLotIncrement, 2)
            + (g_panelCompact ? "/$" : " / $")
            + DoubleToString(InpLotStepMoney, 0)
            + (g_panelCompact ? " s" : " (step ")
            + (equityKnown ? DoubleToString(steps, 0) : "N/A")
            + (g_panelCompact ? "" : ")"),
            equityKnown ? COL_TEXT : COL_DIM);

   if(equityKnown)
     {
      double effectiveLot = GetEffectiveLotForEquity(equity);

      if(equity > 0.0 && effectiveLot <= 0.0)
         PanelSet("V_LOT", "INVALID", COL_WARN);
      else
         PanelSet("V_LOT",
                  DoubleToString(effectiveLot, 3),
                  COL_CYAN);

      color equityColor = PanelSignColor(equity);

      PanelSet("N_EQ", InpLockProfit ? "Trading Cap:" : "Virtual Equity:", equityColor);
      PanelSet("V_EQ",
               (equity < 0.0 ? "-$" : "$") + DoubleToString(MathAbs(equity), 2),
               equityColor);
     }
   else
     {
      PanelSet("V_LOT", "N/A", COL_DIM);
      PanelSet("N_EQ", InpLockProfit ? "Trading Cap:" : "Virtual Equity:", COL_DIM);
      PanelSet("V_EQ", "N/A", COL_DIM);
     }

   double closedNet = 0.0;
   bool closedKnown = TryGetClosedNet(closedNet);

   if(closedKnown)
     {
      color closedNetColor =
         (closedNet >= 0.0) ? COL_PROFIT : COL_WARN;

      PanelSet("N_NET", "Closed Net:", closedNetColor);
      PanelSet("V_NET", FormatMoney(closedNet), closedNetColor);
     }
   else
     {
      PanelSet("N_NET", "Closed Net:", COL_DIM);
      PanelSet("V_NET", "N/A", COL_DIM);
     }

   //--- Cycle Loss: อ่านจากฐานที่ Engine บันทึกก่อนเปิด Order
   double cycleLoss = 0.0;
   bool cycleKnown = TryGetCycleLoss(cycleLoss);

   if(InpLockProfit)
     {
      double lkProfit = 0.0;
      double lkLoss = 0.0;

      PanelSet("N_CYC", "Locked Profit:", COL_DIM);

      if(TryGetLockStats(lkProfit, lkLoss))
        {
         PanelSet("V_CYC", FormatMoney(lkProfit), PanelSignColor(lkProfit));
         PanelSet("LK1", "Loss " + FormatMoney(lkLoss), PanelSignColor(lkLoss));
        }
      else
        {
         PanelSet("V_CYC", "N/A", COL_DIM);
         PanelSet("LK1", "Loss N/A", COL_DIM);
        }

      int rfCount = GetRefillCount();
      int rsCount = GetResetCount();
      double rfSum = GetTotalRefill();
      double rsSum = GetTotalReset();

      if(g_panelTier == PANEL_TIER_L)
        {
         PanelSet("LK2",
                  "Refill " + IntegerToString(rfCount) + "x = $" + DoubleToString(rfSum, 2),
                  COL_TEXT);
         PanelSet("LK3",
                  "Reset " + IntegerToString(rsCount) + "x = $" + DoubleToString(rsSum, 2),
                  COL_TEXT);
        }
      else
         PanelSet("LK2",
                  "RF " + IntegerToString(rfCount) + "x $" + DoubleToString(rfSum, 0)
                  + " | RS " + IntegerToString(rsCount) + "x $" + DoubleToString(rsSum, 0),
                  COL_TEXT);
     }
   else if(cycleKnown)
     {
      PanelSet("V_CYC",
               FormatMoney(cycleLoss),
               PanelSignColor(cycleLoss));
     }
   else
     {
      PanelSet("V_CYC", "N/A", COL_DIM);
     }

   //--- POSITIONS
   double floatingPL = GetFloatingPL();

   //--- Floating: บวกเขียว / ลบแดง / ศูนย์ขาว
   PanelSet("V_FLOAT",
            FormatMoney(floatingPL),
            PanelSignColor(floatingPL));

   int buys  = CoreCountSide(POSITION_TYPE_BUY);
   int sells = CoreCountSide(POSITION_TYPE_SELL);
   int activeTotal = buys + sells;

   //--- Active: มีออเดอร์ = เหลือง / ไม่มี = ขาว
   PanelSet("V_ACT_TOTAL",
            IntegerToString(activeTotal),
            (activeTotal > 0) ? COL_ACTIVE : COL_TEXT);

   //--- Buy: มี Buy = น้ำเงิน / ไม่มี = ขาว
   PanelSet("V_ACT_BUY",
            "Buy:" + IntegerToString(buys),
            (buys > 0) ? COL_BUY_TEXT : COL_TEXT);

   //--- Sell: มี Sell = แดง / ไม่มี = ขาว
   PanelSet("V_ACT_SELL",
            "Sell:" + IntegerToString(sells),
            (sells > 0) ? COL_SELL_TEXT : COL_TEXT);

   PanelSet("V_CUT", FormatPoints(InpCutLossPoints), COL_TEXT);

   //--- Entry: OFF = แดง (แยกกรณีมี Position ค้าง) / ON = เหตุผลจากกลยุทธ์
   string gateText = "";
   color gateColor = COL_TEXT;

   if(CoreIsPaused())
     {
      gateText = (activeTotal > 0) ? "PAUSED (positions open)"
                                   : "PAUSED by user";
      gateColor = COL_WARN;
     }
   else
     {
      gateText = Strategy_GateText();

      if(gateText == "READY")
         gateColor = COL_PROFIT;
     }

   PanelSet("V_GATE", gateText, gateColor);

   //--- Identity: ข้อความเตือนสีแดง (ย่อให้พอดีความกว้าง)
   string idText = g_identityWarning;
   int maxChars = g_panelCompact ? 40 : 56;

   if(StringLen(idText) > maxChars)
      idText = StringSubstr(idText, 0, maxChars - 3) + "...";

   if(idText == "")
      idText = " ";

   PanelSet("V_ID", idText, COL_WARN);

   PanelUpdatePower();

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| จัดการ Event ของกราฟและปุ่ม                                      |
//+------------------------------------------------------------------+
void PanelOnChartEvent(int id,
                       long lparam,
                       double dparam,
                       string sparam)
  {
   //--- เมื่อย่อ/ขยายกราฟ หรือเปลี่ยน Template ให้คำนวณ Layout ใหม่
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      PanelCheckResponsiveLayout();
      PanelUpdate();
      return;
     }

   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(StringFind(sparam, PanelPrefix()) != 0)
      return;

   bool handled = true;

   if(sparam == PName("B_CLBUY"))
      CloseOneSide(POSITION_TYPE_BUY, "CLOSE-BUY");

   else if(sparam == PName("B_CLSELL"))
      CloseOneSide(POSITION_TYPE_SELL, "CLOSE-SELL");

   else if(sparam == PName("B_CLALL"))
      Strategy_CloseAll("CLOSE-ALL");

   else if(sparam == PName("B_PWR"))
      CoreTogglePause();

   else if(sparam == PName("B_REFILL"))
     {
      if(AddRefill())
        {
         double equity = 0.0;

         if(TryGetVirtualEquity(equity))
            Print(CORE_LOG_PREFIX, " REFILL SAVED +$",
                  DoubleToString(InpRefillAmount, 2),
                  " | Virtual Equity=$",
                  DoubleToString(equity, 2));
         else
            Print(CORE_LOG_PREFIX, " REFILL SAVED +$",
                  DoubleToString(InpRefillAmount, 2),
                  " | Virtual Equity=N/A");
        }
      else
         Print(CORE_LOG_PREFIX, " REFILL NOT SAVED",
               " | ตรวจ Experts Log ก่อนกดซ้ำ");
     }

   else if(sparam == PName("B_RESET"))
     {
      DoCapitalReset();
     }

   else if(sparam == PName("MIN"))
     {
      //--- ถ้าจอเล็กมาก Auto Minimize จะเป็นตัวบังคับ
      //--- แต่ผู้ใช้ยังสามารถกดย่อ/ขยายเองได้เมื่อจอมีพื้นที่พอ
      if(!g_panelAutoMinimized)
         g_panelMinimized = !g_panelMinimized;

      PanelApplyVisibility();
     }

   else
     {
      //--- ปุ่มของกลยุทธ์ช่อง 1-3
      handled = false;

      for(int s = 0; s < 3; s++)
        {
         if(g_stratBtnId[s] != ""
            && sparam == PName("SB" + IntegerToString(s + 1)))
           {
            Strategy_OnButton(g_stratBtnId[s]);
            handled = true;
            break;
           }
        }
     }

   if(handled)
     {
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

      PanelUpdate();
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| ปิด Panel และลบ Object ทั้งหมด                                   |
//+------------------------------------------------------------------+
void PanelDeinit()
  {
   PanelDeleteObjects();
   g_panelReady = false;
   ChartRedraw();
  }

#endif // CORE_PANEL_MQH