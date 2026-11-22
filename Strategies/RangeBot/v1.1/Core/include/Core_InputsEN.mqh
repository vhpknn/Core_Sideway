//+------------------------------------------------------------------+
//|                                               Core_InputsEN.mqh  |
//|  Input ของ Core ป้ายภาษาอังกฤษ (ชื่อตัวแปรและค่าเริ่มต้นเหมือน     |
//|  Core_Inputs.mqh ทุกตัว) ใช้เมื่อ define INPUT_LANG_EN ใน EA      |
//|  include จาก Core_Inputs.mqh เท่านั้น                             |
//+------------------------------------------------------------------+
#ifndef CORE_INPUTS_EN_MQH
#define CORE_INPUTS_EN_MQH

//--- Auto Break-even mode (3 options)
enum ENUM_BE_MODE
  {
   BE_OFF      = 0,   // false (Off)
   BE_FIXED    = 1,   // Fixed (set SL once, then stop)
   BE_TRAILING = 2    // Trailing (SL follows price)
  };

//====================== 1. Virtual Capital Auto-Lot ==============
input group "=== 1. Virtual Capital Auto-Lot ==="
input int    InpPointDigits     = 2;      // InpPointDigits - Point decimals of the symbol per broker (XAUUSD = 2: 1 Point = $0.01)
input double InpInitialCapital  = 50.0;   // InpInitialCapital - Initial virtual capital per bot ($)
input double InpRefillAmount    = 10.0;   // InpRefillAmount - One REFILL click adds this virtual capital ($)
input double InpBaseLot         = 0.01;   // InpBaseLot - Starting lot size
input bool   InpAutoLot         = true;   // InpAutoLot - Enable automatic lot calculation
input double InpLotStepMoney    = 50.0;   // InpLotStepMoney - Lot goes up one step for every ($)
input double InpLotIncrement    = 0.01;   // InpLotIncrement - Lot added per step
input bool   InpLockProfit      = false;  // InpLockProfit - Lock profit: profit does not add to trading capital (only losses reduce it)
input int    InpMaxLotStep      = 4;      // InpMaxLotStep - Max lot x 0.01 (4 = up to 0.04 / 0 = unlimited)

//====================== 2. Entry Gates & Auto Refill ==============
input group "=== 2. Entry Gates & Auto Refill ==="
input bool   InpUseTimeout      = true;   // InpUseTimeout - Use timeout to force a new round
input int    InpTimeoutSeconds  = 300;    // InpTimeoutSeconds - Timeout before a new round (seconds)
input bool   InpUseSpreadCheck  = true;   // InpUseSpreadCheck - Check spread before opening
input int    InpMaxSpreadPoints = 25;     // InpMaxSpreadPoints - Max spread allowed to open (Points)
input int    InpDeviationPoints = 10;     // InpDeviationPoints - Max price deviation when sending orders (Points)

//====================== 3. Profit Protection & TP Controls =========
input group "=== 3. Profit Protection & TP Controls ==="
input int    InpCutLossPoints   = 1000;   // InpCutLossPoints - Cut loss per order when price goes against (Points)
input ENUM_BE_MODE InpBreakEvenMode = BE_TRAILING; // InpBreakEvenMode - Auto Break-even mode
input double InpBreakEvenPct    = 20.0;   // InpBreakEvenPct - % of Trigger to lock as profit
input int    InpBreakEvenTrigger= 1000;   // InpBreakEvenTrigger - Start protecting when price is in profit by (Points)
input int    InpBreakEvenStep   = 100;    // InpBreakEvenStep - Move SL every (Points) - Trailing mode only
input double InpRRPercent       = 200.0;  // InpRRPercent - R:R target (% of BE Trigger) | 200% = close at +2000 Points | 0 = off
input bool   InpUseTrailingTP   = true;   // InpUseTrailingTP - Enable Trailing TP from best price
input int    InpTrailingPullback= 500;    // InpTrailingPullback - Pullback from best price before closing (Points)

//====================== 4. Sessions ===============================
input group "=== 4. Sessions (true = no new entries in this window) ==="
input bool   InpSession1Block   = false;  // InpSession1Block - Session 1: enable this block window
input string InpSession1Start   = "01:00";// InpSession1Start - Start time (server)
input string InpSession1End     = "04:00";// InpSession1End - End time (next day starts)
input bool   InpSession2Block   = false;  // InpSession2Block - Session 2: enable this block window
input string InpSession2Start   = "07:00";// InpSession2Start - Start time (server)
input string InpSession2End     = "12:00";// InpSession2End - End time
input bool   InpSession3Block   = false;  // InpSession3Block - Session 3: enable this block window
input string InpSession3Start   = "21:00";// InpSession3Start - Start time (server)
input string InpSession3End     = "24:00";// InpSession3End - End time (end of day)

//====================== 5. System Identity & Blackbox =============
input group "=== 5. System Identity & Blackbox ==="
input long   InpMagicNumber     = STRATEGY_MAGIC_BASE;     // InpMagicNumber - Magic number (range per MAGIC_REGISTRY)
input string InpTradeComment    = STRATEGY_DEFAULT_COMMENT; // InpTradeComment - Comment format <TAG><Magic> <text> (shown on Panel)
input bool   InpIdentityCheck   = false;  // InpIdentityCheck - Identity check: true = warn when Comment/Magic do not match <TAG><Magic> | false = off, no warnings at all (free Magic allowed)
input bool   InpEnableReport    = true;   // InpEnableReport - Write profit/loss summary to a CSV file
input int    InpReportDays      = 5;      // InpReportDays - Create CSV every N days (when basket is empty)

#endif // CORE_INPUTS_EN_MQH