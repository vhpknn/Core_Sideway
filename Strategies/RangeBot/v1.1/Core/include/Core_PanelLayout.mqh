//+------------------------------------------------------------------+
//|                                             Core_PanelLayout.mqh |
//|  สร้าง Panel แบบปรับขนาดอัตโนมัติ 4 ระดับ (L / M / S / XS)         |
//|  include จาก Core_Panel.mqh เท่านั้น (ใช้ฟังก์ชันของ Panel)         |
//+------------------------------------------------------------------+
#ifndef CORE_PANEL_LAYOUT_MQH
#define CORE_PANEL_LAYOUT_MQH

//--- แถว: ชื่อ + ค่า
void PanelAddRow(string nId, string vId, string title, int y,
                 color nClr, color vClr, int fontSize)
  {
   int yy = g_panelY + y;

   PanelLabel(nId, title, g_panelX + g_panelNameX,  yy, nClr, fontSize, CUI_FONT);
   PanelLabel(vId, "-",   g_panelX + g_panelValueX, yy, vClr, fontSize, CUI_FONT);
  }

//--- แถว Active: ยอดรวม / Buy / Sell แยก Label เพื่อใช้คนละสี
void PanelAddActiveRow(int y, int fontSize)
  {
   int yy = g_panelY + y;
   int nx = g_panelX + g_panelNameX;
   int vx = g_panelX + g_panelValueX;

   int dxBuy  = (g_panelCompact ? 16 : 22);
   int dxSell = (g_panelCompact ? 50 : 72);

   PanelLabel("N_ACT",       "Active:", nx,         yy, COL_DIM,  fontSize);
   PanelLabel("V_ACT_TOTAL", "-",       vx,         yy, COL_TEXT, fontSize, CUI_FONT);
   PanelLabel("V_ACT_BUY",   "-",       vx + dxBuy,  yy, COL_TEXT, fontSize, CUI_FONT);
   PanelLabel("V_ACT_SELL",  "-",       vx + dxSell, yy, COL_TEXT, fontSize, CUI_FONT);
  }

//+------------------------------------------------------------------+
//| สร้าง Panel ตามระดับที่เลือกจากขนาดกราฟ                            |
//|  L  = เต็ม (เหมือนเดิม)                                           |
//|  M  = ซ่อนกลุ่ม STATUS ลดระยะแถว/ปุ่ม                             |
//|  S  = ค่าหลัก 5 แถว + ปุ่มเล็ก                                    |
//|  XS = ย่อเหลือหัว + ON/OFF (ใช้ระบบ Minimize เดิม)                |
//+------------------------------------------------------------------+
void PanelBuild()
  {
   PanelDeleteObjects();
   PanelRefreshLayoutMetrics();

   int  tier  = g_panelTier;
   bool small = (tier >= PANEL_TIER_S);

   int px = g_panelX;
   int py = g_panelY;

   int nameX = px + g_panelNameX;
   int btnX  = px + g_panelBtnX;
   int btnW  = g_panelBtnW;

   int lf = g_panelFont;
   int sf = CUI_FONT_SECTION;
   int bf = ((g_panelCompact || small) ? CUI_FONT_BUTTON_C : CUI_FONT_BUTTON);

   //--- พื้นหลัง
   string bg = PName("BG");
   ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, px);
   ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, py);
   ObjectSetInteger(0, bg, OBJPROP_XSIZE, g_panelW);
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, g_panelHFull);
   ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, COL_BG);
   ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bg, OBJPROP_COLOR, COL_BORDER);
   ObjectSetInteger(0, bg, OBJPROP_BACK, false);
   ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bg, OBJPROP_HIDDEN, true);

   //--- Header + ปุ่ม -/+ + ปุ่ม ON/OFF
   PanelLabel("HDR",
              Strategy_Title() + " | " + _Symbol + " [" + IntegerToString(InpMagicNumber) + "]",
              px + 12, py + 10, COL_HEADER, g_panelHeadFont, CUI_FONT);

   PanelButton("MIN", "-", px + g_panelW - 30, py + 6, 22, 18,
               COL_GRAY, COL_BORDER, 9);

   PanelButton("B_PWR", "ON", px + g_panelW - 80, py + 6, 46, 18,
               CUI_GREEN, CUI_GREEN, 9);

   //--- ฝั่งซ้าย: ข้อมูล
   int pitch = 18;
   int h2r   = 17;
   int r2h   = 23;

   if(tier == PANEL_TIER_M)
     {
      pitch = 17;
      h2r   = 16;
      r2h   = 21;
     }

   int y = 35;

   if(tier == PANEL_TIER_L)
     {
      PanelLabel("S1", "STATUS", nameX, py + y, COL_DIM, sf, CUI_FONT);
      y += h2r;
      PanelAddRow("N_SESS", "V_SESS", "Session:",      y, COL_DIM, COL_TEXT, lf);  y += pitch;
      PanelAddRow("N_SPRD", "V_SPRD", "Spread:",       y, COL_DIM, COL_TEXT, lf);  y += pitch;
      PanelAddRow("N_TIME", "V_TIME", "Refill Timer:", y, COL_DIM, COL_TEXT, lf);  y += r2h;
     }

   if(tier <= PANEL_TIER_M)
     {
      PanelLabel("S2", "LOT & CAPITAL", nameX, py + y, COL_DIM, sf, CUI_FONT);
      y += h2r;
      PanelAddRow("N_BASE", "V_BASE", "Base Lot:",       y, COL_DIM,    COL_TEXT,   lf);     y += pitch;
      PanelAddRow("N_STEP", "V_STEP", "Lot Step:",       y, COL_DIM,    COL_TEXT,   lf);     y += pitch;
      PanelAddRow("N_LOT",  "V_LOT",  "Effective Lot:",  y, COL_CYAN,   COL_CYAN,   lf + 1); y += pitch;
      PanelAddRow("N_EQ",   "V_EQ",   "Virtual Equity:", y, COL_EQUITY, COL_EQUITY, lf + 1); y += pitch;
      PanelAddRow("N_NET",  "V_NET",  "Closed Net:",     y, COL_PROFIT, COL_PROFIT, lf + 1); y += pitch;
      PanelAddRow("N_CYC",  "V_CYC",  (InpLockProfit ? "Locked Profit:" : "Cycle Loss:"),     y, COL_DIM,    COL_TEXT,   lf);     y += r2h;

      PanelLabel("S3", "POSITIONS", nameX, py + y, COL_DIM, sf, CUI_FONT);
      y += h2r;
      PanelAddRow("N_FLOAT", "V_FLOAT", "Open Floating:",   y, COL_DIM, COL_TEXT, lf);  y += pitch;
      PanelAddActiveRow(y, lf);                                                         y += pitch;
      PanelAddRow("N_CUT",   "V_CUT",   "Cut Loss Limit:",  y, COL_DIM, COL_TEXT, lf);  y += pitch;
      PanelAddRow("N_GATE",  "V_GATE",  "Entry:",           y, COL_DIM, COL_TEXT, lf);  y += pitch;
      PanelLabel("V_ID", " ", nameX, py + y, COL_WARN, lf);
     }
   else
     {
      //--- ระดับ S / XS: เฉพาะค่าหลัก
      y = 33;
      pitch = 16;
      PanelAddRow("N_EQ",    "V_EQ",    "Virtual Equity:", y, COL_EQUITY, COL_EQUITY, lf);  y += pitch;
      PanelAddRow("N_NET",   "V_NET",   "Closed Net:",     y, COL_PROFIT, COL_PROFIT, lf);  y += pitch;
      PanelAddRow("N_FLOAT", "V_FLOAT", "Open Floating:",  y, COL_DIM,    COL_TEXT,   lf);  y += pitch;
      PanelAddActiveRow(y, lf);                                                              y += pitch;
      PanelAddRow("N_GATE",  "V_GATE",  "Entry:",          y, COL_DIM,    COL_TEXT,   lf);  y += pitch;
      PanelLabel("V_ID", " ", nameX, py + y, COL_WARN, lf);
     }

   //--- ฝั่งขวา: ตำแหน่งปุ่มตามระดับ
   int bh = 26;
   int pad = CUI_CLOSE_FRAME_PAD;
   int ySB1 = 51, ySB2 = 83, yCB = 112, yCS = 144, yRF = 179, ySB3 = 211, yCA = 243, yFT = 280;

   if(tier == PANEL_TIER_M)
     {
      bh = 22;
      pad = CUI_CLOSE_FRAME_PAD;
      ySB1 = 33;  ySB2 = 59;  yCB = 87;  yCS = 117;
      yRF = 149;  ySB3 = 175; yCA = 201; yFT = 228;
     }
   else if(small)
     {
      bh = 18;
      pad = 0;
      ySB1 = 33;  ySB2 = 53;  yCB = 73;  yCS = 93;
      yRF = 113;  ySB3 = 133; yCA = 153; yFT = 174;
     }

   //--- ปุ่มของกลยุทธ์ 3 ช่อง
   int slotY[3];
   slotY[0] = ySB1;
   slotY[1] = ySB2;
   slotY[2] = ySB3;

   for(int s = 0; s < 3; s++)
      g_stratBtnId[s] = "";

   int stratCount = Strategy_ButtonCount();

   if(stratCount > 3)
     {
      Print(CORE_LOG_PREFIX, " Panel รองรับปุ่มกลยุทธ์สูงสุด 3 ปุ่ม",
            " (กลยุทธ์ขอ ", stratCount, ") ใช้สำเนา Panel เฉพาะกลยุทธ์");
      stratCount = 3;
     }

   for(int s = 0; s < stratCount; s++)
     {
      SStrategyButton def;
      def.textColor = CLR_NONE;

      if(!Strategy_ButtonDef(s, def))
         continue;

      string objId = "SB" + IntegerToString(s + 1);

      PanelButton(objId, def.text, btnX, py + slotY[s], btnW, bh,
                  def.bg, def.border, bf);

      if(def.textColor != CLR_NONE)
         ObjectSetInteger(0, PName(objId), OBJPROP_COLOR, def.textColor);

      ObjectSetString(0, PName(objId), OBJPROP_TOOLTIP, def.tooltip);

      g_stratBtnId[s] = def.id;
     }

   //--- CLOSE BUY / CLOSE SELL (ระดับ S ใช้ขอบสีแทนกรอบหนา)
   if(pad > 0)
     {
      PanelFrame("F_CLBUY", btnX - pad, py + yCB,
                 btnW + 2 * pad, bh + 2 * pad, COL_CLOSE_BUY_FRAME);
      PanelButton("B_CLBUY", "CLOSE BUY", btnX, py + yCB + pad, btnW, bh,
                  COL_CLOSE_BUY_BG, COL_CLOSE_BUY_BG, bf);

      PanelFrame("F_CLSELL", btnX - pad, py + yCS,
                 btnW + 2 * pad, bh + 2 * pad, COL_CLOSE_SELL_FRAME);
      PanelButton("B_CLSELL", "CLOSE SELL", btnX, py + yCS + pad, btnW, bh,
                  COL_CLOSE_SELL_BG, COL_CLOSE_SELL_BG, bf);
     }
   else
     {
      PanelButton("B_CLBUY", "CLOSE BUY", btnX, py + yCB, btnW, bh,
                  COL_CLOSE_BUY_BG, COL_CLOSE_BUY_FRAME, bf);
      PanelButton("B_CLSELL", "CLOSE SELL", btnX, py + yCS, btnW, bh,
                  COL_CLOSE_SELL_BG, COL_CLOSE_SELL_FRAME, bf);
     }

   if(InpLockProfit)
     {
      int halfW = (btnW - 4) / 2;

      PanelButton("B_REFILL",
                  "REFILL $" + DoubleToString(InpRefillAmount, 0),
                  btnX, py + yRF, halfW, bh, COL_GRAY, COL_BORDER, bf);

      PanelButton("B_RESET",
                  "RESET",
                  btnX + halfW + 4, py + yRF, btnW - halfW - 4, bh,
                  COL_GRAY, COL_BORDER, bf);

      ObjectSetString(0, PName("B_RESET"), OBJPROP_TOOLTIP,
                      "Reset: top up trading capital back to initial $"
                      + DoubleToString(InpInitialCapital, 2));
     }
   else
      PanelButton("B_REFILL",
                  "REFILL $" + DoubleToString(InpRefillAmount, 0),
                  btnX, py + yRF, btnW, bh, COL_GRAY, COL_BORDER, bf);

   PanelButton("B_CLALL", "CLOSE ALL", btnX, py + yCA, btnW, bh,
               COL_MUSTARD, COL_BORDER, bf);

   PanelLabel("FOOT", PanelFooterText(), btnX + 4, py + yFT, COL_HEADER,
              ((g_panelCompact || small) ? CUI_FONT_FOOTER_C : CUI_FONT_FOOTER),
              CUI_FONT);

   if(InpLockProfit)
     {
      int lkFont = CUI_FONT_FOOTER_C;
      int lkY = yFT + 17;

      PanelLabel("LK1", "-", btnX + 4, py + lkY, COL_TEXT, lkFont, CUI_FONT);
      lkY += 14;
      PanelLabel("LK2", "-", btnX + 4, py + lkY, COL_TEXT, lkFont, CUI_FONT);

      if(tier == PANEL_TIER_L)
        {
         lkY += 14;
         PanelLabel("LK3", "-", btnX + 4, py + lkY, COL_TEXT, lkFont, CUI_FONT);
        }
     }

   g_panelReady = true;
   PanelUpdatePower();
   PanelApplyVisibility();
   PanelUpdate();
   ChartRedraw();

   //--- บันทึกระดับที่ใช้ (พิมพ์เฉพาะตอนระดับเปลี่ยน)
   static int s_lastTier = -1;

   if(s_lastTier != tier)
     {
      s_lastTier = tier;
      Print(CORE_LOG_PREFIX, " Panel tier=", tier,
            " | chart=", PanelChartWidth(), "x", PanelChartHeight(),
            " | panel=", g_panelW, "x", g_panelHFull);
     }
  }

#endif // CORE_PANEL_LAYOUT_MQH