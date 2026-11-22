//+------------------------------------------------------------------+
//|                                                   Core_Pause.mqh |
//|  สวิตช์ ON/OFF ต่อกราฟ (มติ D-13)                                |
//|  OFF = หยุดเปิดออเดอร์ใหม่ทุกแบบ แต่ Protect / Report / ปุ่มปิด   |
//|        ยังทำงานตามปกติ ไม่ปิด Position ที่ถืออยู่                  |
//|  เก็บสถานะเป็น GV ผูกกับ Magic: <TAG>S_<บัญชี>_<Symbol>_<Magic>_PAUSE |
//|  ค่า 1 = OFF, ไม่มีค่า = ON, Strategy Tester เริ่ม ON เสมอ        |
//+------------------------------------------------------------------+
#ifndef CORE_PAUSE_MQH
#define CORE_PAUSE_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"

//--- true = OFF (ห้ามเปิดออเดอร์ใหม่)
bool g_corePaused = false;

string PauseGVName()
  {
   return(CoreStateGVName("PAUSE"));
  }

//+------------------------------------------------------------------+
//| โหลดสถานะตอนเริ่มระบบ (เรียกจาก OnInit)                           |
//+------------------------------------------------------------------+
void CorePauseInit()
  {
   g_corePaused = false;

   //--- Strategy Tester เริ่ม ON เสมอ ไม่อ่านสถานะที่ค้างจากการใช้งานจริง
   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   string name = PauseGVName();

   //--- ไม่มี State = ON
   if(!GlobalVariableCheck(name))
      return;

   double value = 0.0;

   //--- อ่านไม่ได้หรือค่าผิด: ถือเป็น OFF เพื่อไม่เปิดออเดอร์โดยไม่ตั้งใจ
   if(!GlobalVariableGet(name, value)
      || !MathIsValidNumber(value))
     {
      g_corePaused = true;

      Print(CORE_LOG_PREFIX,
            " PAUSE State อ่านไม่ได้หรือไม่ถูกต้อง",
            " -> ถือเป็น OFF (ไม่เปิดออเดอร์ใหม่)");
      return;
     }

   g_corePaused = (value >= 0.5);

   if(g_corePaused)
      Print(CORE_LOG_PREFIX,
            " ENTRY OFF (กู้สถานะที่บันทึกไว้) | ปุ่มบน Panel เพื่อเปิด ON");
  }

bool CoreIsPaused()
  {
   return(g_corePaused);
  }

//+------------------------------------------------------------------+
//| ตั้งสถานะ ON/OFF คืน false ถ้าบันทึกลง GV ไม่สำเร็จ                |
//| (สถานะใน RAM ยังมีผลจนกว่าจะรีสตาร์ท)                            |
//+------------------------------------------------------------------+
bool CoreSetPaused(bool paused)
  {
   g_corePaused = paused;

   Print(CORE_LOG_PREFIX, " ENTRY ", (paused ? "OFF" : "ON"), " (by user)");

   //--- ใน Strategy Tester ไม่เขียน GV
   if((bool)MQLInfoInteger(MQL_TESTER))
      return(true);

   ResetLastError();

   if(GlobalVariableSet(PauseGVName(), paused ? 1.0 : 0.0) == 0)
     {
      Print(CORE_LOG_PREFIX, " บันทึก PAUSE State ไม่สำเร็จ",
            " | error=", GetLastError(),
            " | สถานะมีผลจนกว่าจะรีสตาร์ท");
      return(false);
     }

   GlobalVariablesFlush();
   return(true);
  }

bool CoreTogglePause()
  {
   return(CoreSetPaused(!g_corePaused));
  }

#endif // CORE_PAUSE_MQH