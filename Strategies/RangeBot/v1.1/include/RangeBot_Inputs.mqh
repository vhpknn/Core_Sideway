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

input group "=== R1. RangeBot General ==="
#ifdef INPUT_LANG_EN
input ENUM_TIMEFRAMES InpRbEntryTF = PERIOD_H1;   // InpRbEntryTF - Entry timeframe (decisions are made on a new bar of this TF)
input int    InpRbAtrPeriod        = 14;          // InpRbAtrPeriod - ATR period (range and SL/TP)
input bool   InpRbLogBar           = true;        // InpRbLogBar - Print one summary log line per new bar
input bool   InpRbDrawRange        = true;        // InpRbDrawRange - Draw range high/low lines on the chart
#else
input ENUM_TIMEFRAMES InpRbEntryTF = PERIOD_H1;   // ไทม์เฟรมเข้าเทรด (ตัดสินใจเมื่อเกิดแท่งใหม่ของ TF นี้)
input int    InpRbAtrPeriod        = 14;          // ช่วง ATR (ใช้กับกรอบและ SL/TP)
input bool   InpRbLogBar           = true;        // พิมพ์ Log สรุป 1 บรรทัดต่อแท่งใหม่
input bool   InpRbDrawRange        = true;        // วาดเส้นบน/ล่างของกรอบบนกราฟ
#endif

input group "=== R2. Regime ==="
#ifdef INPUT_LANG_EN
input int    InpRbAdxPeriod        = 14;          // InpRbAdxPeriod - ADX period
input double InpRbAdxRangeMax      = 20.0;        // InpRbAdxRangeMax - ADX at or below this can be RANGE
input double InpRbAdxTrendMin      = 25.0;        // InpRbAdxTrendMin - ADX at or above this can be TREND
input int    InpRbAdxRisingBars    = 3;           // InpRbAdxRisingBars - ADX must rise for this many bars to be TREND
input int    InpRbBbPeriod         = 20;          // InpRbBbPeriod - Bollinger period
input double InpRbBbDev            = 2.0;         // InpRbBbDev - Bollinger deviation
input int    InpRbBbwAvgPeriod     = 50;          // InpRbBbwAvgPeriod - Bars used for average Bollinger width
input double InpRbSqueezeFactor    = 1.0;         // InpRbSqueezeFactor - RANGE needs width <= factor x average width
input int    InpRbEmaFast          = 20;          // InpRbEmaFast - Fast EMA
input int    InpRbEmaMid           = 50;          // InpRbEmaMid - Mid EMA
input int    InpRbEmaSlow          = 200;         // InpRbEmaSlow - Slow EMA
input int    InpRbRegimeConfirmBars = 2;          // InpRbRegimeConfirmBars - Bars the same result must hold before switching regime
#else
input int    InpRbAdxPeriod        = 14;          // ช่วง ADX
input double InpRbAdxRangeMax      = 20.0;        // ADX ไม่เกินค่านี้ จึงเป็น RANGE ได้
input double InpRbAdxTrendMin      = 25.0;        // ADX ตั้งแต่ค่านี้ขึ้นไป จึงเป็น TREND ได้
input int    InpRbAdxRisingBars    = 3;           // ADX ต้องเพิ่มต่อเนื่องกี่แท่ง จึงเป็น TREND
input int    InpRbBbPeriod         = 20;          // ช่วง Bollinger
input double InpRbBbDev            = 2.0;         // ค่าเบี่ยงเบน Bollinger
input int    InpRbBbwAvgPeriod     = 50;          // จำนวนแท่งที่ใช้เฉลี่ยความกว้าง Bollinger
input double InpRbSqueezeFactor    = 1.0;         // RANGE ต้องมีความกว้าง <= ค่านี้ x ความกว้างเฉลี่ย
input int    InpRbEmaFast          = 20;          // EMA เร็ว
input int    InpRbEmaMid           = 50;          // EMA กลาง
input int    InpRbEmaSlow          = 200;         // EMA ช้า
input int    InpRbRegimeConfirmBars = 2;          // ผลต้องตรงกันกี่แท่งติดกัน จึงเปลี่ยนสภาพตลาด
#endif

input group "=== R3. Range ==="
#ifdef INPUT_LANG_EN
input int    InpRbRangeLookback      = 30;        // InpRbRangeLookback - Bars used to build the range
input int    InpRbRangeExcludeBars   = 1;         // InpRbRangeExcludeBars - Latest closed bars excluded (so a sweep wick does not widen the range)
input double InpRbRangeMinHeightAtr  = 2.0;       // InpRbRangeMinHeightAtr - Minimum range height (x ATR)
input double InpRbRangeMaxHeightAtr  = 6.0;       // InpRbRangeMaxHeightAtr - Maximum range height (x ATR)
input int    InpRbRangeMinTouches    = 2;         // InpRbRangeMinTouches - Minimum touches on each edge
input double InpRbRangeTouchTolAtr   = 0.25;      // InpRbRangeTouchTolAtr - Touch tolerance (x ATR)
input bool   InpRbUseRangeLock       = true;      // InpRbUseRangeLock - Keep the edges locked until break or expiry
#else
input int    InpRbRangeLookback      = 30;        // จำนวนแท่งที่ใช้สร้างกรอบ
input int    InpRbRangeExcludeBars   = 1;         // ไม่นับแท่งล่าสุดที่ปิดแล้วกี่แท่ง (ไส้ Sweep จะได้ไม่ขยายกรอบ)
input double InpRbRangeMinHeightAtr  = 2.0;       // ความสูงกรอบขั้นต่ำ (เท่าของ ATR)
input double InpRbRangeMaxHeightAtr  = 6.0;       // ความสูงกรอบสูงสุด (เท่าของ ATR)
input int    InpRbRangeMinTouches    = 2;         // จำนวนครั้งที่แตะขอบแต่ละด้านขั้นต่ำ
input double InpRbRangeTouchTolAtr   = 0.25;      // ระยะที่นับว่าแตะขอบ (เท่าของ ATR)
input bool   InpRbUseRangeLock       = true;      // ล็อกขอบกรอบไว้จนกว่าจะเบรกหรือหมดอายุ
#endif

//--- ทิศทาง / ชนิดจุดเข้า / Trigger
#ifdef INPUT_LANG_EN
enum ENUM_RB_DIRECTION
  {
   RB_DIR_FOLLOW_HTF = 0,   // FOLLOW_HTF (trade with the higher-timeframe bias only)
   RB_DIR_BOTH_EDGES = 1    // BOTH_EDGES (buy at the low edge, sell at the high edge)
  };
enum ENUM_RB_ENTRY_TYPE
  {
   RB_ENTRY_ZONE  = 0,      // ZONE
   RB_ENTRY_SWEEP = 1,      // SWEEP
   RB_ENTRY_BOTH  = 2       // BOTH (SWEEP wins when both appear)
  };
enum ENUM_RB_TRIGGER
  {
   RB_TRIG_RSI    = 0,      // RSI
   RB_TRIG_STOCH  = 1,      // STOCH
   RB_TRIG_CANDLE = 2,      // CANDLE (pin bar / engulfing)
   RB_TRIG_NONE   = 3       // NONE
  };
#else
enum ENUM_RB_DIRECTION
  {
   RB_DIR_FOLLOW_HTF = 0,   // ตามทิศ HTF เท่านั้น
   RB_DIR_BOTH_EDGES = 1    // ทั้งสองขอบ (Buy ขอบล่าง Sell ขอบบน)
  };
enum ENUM_RB_ENTRY_TYPE
  {
   RB_ENTRY_ZONE  = 0,      // ZONE (โซนขอบกรอบ)
   RB_ENTRY_SWEEP = 1,      // SWEEP (แทงไส้ออกนอกแล้วปิดกลับ)
   RB_ENTRY_BOTH  = 2       // BOTH (ถ้าเกิดทั้งคู่ใช้ SWEEP)
  };
enum ENUM_RB_TRIGGER
  {
   RB_TRIG_RSI    = 0,      // RSI
   RB_TRIG_STOCH  = 1,      // STOCH
   RB_TRIG_CANDLE = 2,      // CANDLE (Pin Bar / Engulfing)
   RB_TRIG_NONE   = 3       // ไม่ใช้ Trigger
  };
#endif

input group "=== R4. Direction (HTF) ==="
#ifdef INPUT_LANG_EN
input ENUM_RB_DIRECTION InpRbRangeDirection = RB_DIR_FOLLOW_HTF;   // InpRbRangeDirection - Which edges may be traded
input ENUM_TIMEFRAMES InpRbHigherTF = PERIOD_H4;   // InpRbHigherTF - Higher timeframe for the bias
input int    InpRbHtfEma            = 200;         // InpRbHtfEma - EMA period on the higher timeframe
input double InpRbHtfBufferAtr      = 0.25;        // InpRbHtfBufferAtr - Price closer to the EMA than this (x HTF ATR) = no bias
#else
input ENUM_RB_DIRECTION InpRbRangeDirection = RB_DIR_FOLLOW_HTF;   // ขอบที่อนุญาตให้เทรด
input ENUM_TIMEFRAMES InpRbHigherTF = PERIOD_H4;   // ไทม์เฟรมใหญ่ที่ใช้หาทิศ
input int    InpRbHtfEma            = 200;         // ช่วง EMA บนไทม์เฟรมใหญ่
input double InpRbHtfBufferAtr      = 0.25;        // ราคาห่าง EMA ไม่ถึงค่านี้ (เท่าของ ATR ไทม์เฟรมใหญ่) ถือว่าไม่มีทิศ
#endif

input group "=== R5. Entry ==="
#ifdef INPUT_LANG_EN
input ENUM_RB_ENTRY_TYPE InpRbEntryType = RB_ENTRY_BOTH;   // InpRbEntryType - Entry method
input double InpRbZoneEntryPct      = 25.0;        // InpRbZoneEntryPct - ZONE depth (% of range height from the edge)
input double InpRbSweepMinAtr       = 0.1;         // InpRbSweepMinAtr - SWEEP: minimum wick beyond the edge (x ATR)
input double InpRbSweepMaxAtr       = 1.0;         // InpRbSweepMaxAtr - SWEEP: deeper than this is a real break (x ATR)
input double InpRbSweepMinWickRatio = 1.5;         // InpRbSweepMinWickRatio - SWEEP: wick length / candle body
input bool   InpRbSweepRequireTrigger = false;     // InpRbSweepRequireTrigger - SWEEP also needs the trigger
#else
input ENUM_RB_ENTRY_TYPE InpRbEntryType = RB_ENTRY_BOTH;   // วิธีเข้า
input double InpRbZoneEntryPct      = 25.0;        // ความลึกโซน ZONE (% ของความสูงกรอบนับจากขอบ)
input double InpRbSweepMinAtr       = 0.1;         // SWEEP: ไส้ต้องแทงออกนอกขอบอย่างน้อย (เท่าของ ATR)
input double InpRbSweepMaxAtr       = 1.0;         // SWEEP: ลึกกว่านี้ถือเป็นการเบรกจริง ไม่เข้า (เท่าของ ATR)
input double InpRbSweepMinWickRatio = 1.5;         // SWEEP: ความยาวไส้ / เนื้อเทียน
input bool   InpRbSweepRequireTrigger = false;     // SWEEP ต้องมี Trigger ยืนยันด้วย
#endif

input group "=== R6. Trigger ==="
#ifdef INPUT_LANG_EN
input ENUM_RB_TRIGGER InpRbTriggerType = RB_TRIG_RSI;   // InpRbTriggerType - Confirmation trigger
input int    InpRbRsiPeriod         = 14;          // InpRbRsiPeriod - RSI period
input double InpRbRsiBuy            = 35.0;        // InpRbRsiBuy - RSI at or below this (bars 2-4) then turning up = buy trigger
input double InpRbRsiSell           = 65.0;        // InpRbRsiSell - RSI at or above this (bars 2-4) then turning down = sell trigger
input int    InpRbStochK            = 14;          // InpRbStochK - Stochastic %K
input int    InpRbStochD            = 3;           // InpRbStochD - Stochastic %D
input int    InpRbStochSlow         = 3;           // InpRbStochSlow - Stochastic slowing
input double InpRbStochLow          = 20.0;        // InpRbStochLow - Oversold level
input double InpRbStochHigh         = 80.0;        // InpRbStochHigh - Overbought level
input double InpRbCandlePinWickRatio = 2.0;        // InpRbCandlePinWickRatio - Pin bar: wick >= this x body
input bool   InpRbCandleUseEngulfing = true;       // InpRbCandleUseEngulfing - Also accept engulfing candles
#else
input ENUM_RB_TRIGGER InpRbTriggerType = RB_TRIG_RSI;   // Trigger ยืนยันจุดเข้า
input int    InpRbRsiPeriod         = 14;          // ช่วง RSI
input double InpRbRsiBuy            = 35.0;        // RSI (แท่ง 2-4) ต่ำกว่าหรือเท่ากับค่านี้แล้วเริ่มขึ้น = Trigger ฝั่ง Buy
input double InpRbRsiSell           = 65.0;        // RSI (แท่ง 2-4) สูงกว่าหรือเท่ากับค่านี้แล้วเริ่มลง = Trigger ฝั่ง Sell
input int    InpRbStochK            = 14;          // Stochastic %K
input int    InpRbStochD            = 3;           // Stochastic %D
input int    InpRbStochSlow         = 3;           // Stochastic slowing
input double InpRbStochLow          = 20.0;        // ระดับ Oversold
input double InpRbStochHigh         = 80.0;        // ระดับ Overbought
input double InpRbCandlePinWickRatio = 2.0;        // Pin Bar: ไส้ >= ค่านี้ x เนื้อเทียน
input bool   InpRbCandleUseEngulfing = true;       // รับ Engulfing ด้วย
#endif

input group "=== R7. Filters ==="
#ifdef INPUT_LANG_EN
input bool   InpRbUseAdxSlope       = true;        // InpRbUseAdxSlope - Skip when ADX is rising
input int    InpRbAdxSlopeBars      = 3;           // InpRbAdxSlopeBars - Bars used to measure the ADX slope
input bool   InpRbUsePercentB       = false;       // InpRbUsePercentB - ZONE needs Bollinger %B at an extreme
input double InpRbPercentBBuy       = 0.10;        // InpRbPercentBBuy - Buy needs %B at or below this
input double InpRbPercentBSell      = 0.90;        // InpRbPercentBSell - Sell needs %B at or above this
input bool   InpRbUseAtrVolFilter   = true;        // InpRbUseAtrVolFilter - ATR / average ATR must be inside the band
input int    InpRbAtrVolAvgPeriod   = 100;         // InpRbAtrVolAvgPeriod - Bars for average ATR
input double InpRbAtrVolMin         = 0.5;         // InpRbAtrVolMin - Minimum ATR ratio
input double InpRbAtrVolMax         = 2.5;         // InpRbAtrVolMax - Maximum ATR ratio
#else
input bool   InpRbUseAdxSlope       = true;        // ข้ามเมื่อ ADX กำลังชันขึ้น
input int    InpRbAdxSlopeBars      = 3;           // จำนวนแท่งที่ใช้วัดความชัน ADX
input bool   InpRbUsePercentB       = false;       // ZONE ต้องมี Bollinger %B อยู่ที่ขั้ว
input double InpRbPercentBBuy       = 0.10;        // Buy ต้องมี %B ไม่เกินค่านี้
input double InpRbPercentBSell      = 0.90;        // Sell ต้องมี %B ตั้งแต่ค่านี้ขึ้นไป
input bool   InpRbUseAtrVolFilter   = true;        // อัตรา ATR / ATR เฉลี่ย ต้องอยู่ในช่วงที่กำหนด
input int    InpRbAtrVolAvgPeriod   = 100;         // จำนวนแท่งที่ใช้เฉลี่ย ATR
input double InpRbAtrVolMin         = 0.5;         // อัตรา ATR ต่ำสุด
input double InpRbAtrVolMax         = 2.5;         // อัตรา ATR สูงสุด
#endif

input group "=== R8. SL / TP ==="
#ifdef INPUT_LANG_EN
input double InpRbZoneSlAtr         = 1.0;         // InpRbZoneSlAtr - ZONE: SL distance beyond the edge (x ATR)
input double InpRbSweepSlAtr        = 0.3;         // InpRbSweepSlAtr - SWEEP: SL distance beyond the wick tip (x ATR)
input double InpRbTp1BufferAtr      = 0.1;         // InpRbTp1BufferAtr - TP1 sits this far before the opposite edge (x ATR)
input bool   InpRbUseTp2            = true;        // InpRbUseTp2 - Broker TP = TP2 (opposite edge + range height); off = TP1
input double InpRbMinRrTp1          = 1.2;         // InpRbMinRrTp1 - Minimum reward/risk to TP1
#else
input double InpRbZoneSlAtr         = 1.0;         // ZONE: ระยะ SL นอกขอบ (เท่าของ ATR)
input double InpRbSweepSlAtr        = 0.3;         // SWEEP: ระยะ SL นอกปลายไส้ (เท่าของ ATR)
input double InpRbTp1BufferAtr      = 0.1;         // TP1 อยู่ก่อนถึงขอบตรงข้ามเท่านี้ (เท่าของ ATR)
input bool   InpRbUseTp2            = true;        // TP ของโบรก = TP2 (ขอบตรงข้าม + ความสูงกรอบ) ถ้าปิดจะใช้ TP1
input double InpRbMinRrTp1          = 1.2;         // อัตรากำไรต่อความเสี่ยงขั้นต่ำจนถึง TP1
#endif

#endif // RANGEBOT_INPUTS_MQH