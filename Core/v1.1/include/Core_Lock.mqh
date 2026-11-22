//+------------------------------------------------------------------+
//|                                                    Core_Lock.mqh |
//|  ป้องกันแนบ EA ซ้ำบนชุด (บัญชี, Symbol, Magic) เดียวกัน (D-27)    |
//|  กลไก: ตัวแปรกลางชั่วคราว <TAG>S_<บัญชี>_<Symbol>_<Magic>_LOCK    |
//|    ค่า 0 = ว่าง | ค่าอื่น = รหัสเจ้าของ (52 บิตล่างของ ChartID)   |
//|    จอง/ปล่อยด้วย GlobalVariableSetOnCondition (ตรวจและเขียนพร้อมกัน)|
//|  พบซ้ำ = คืน false (CoreOnInit คืน INIT_FAILED) ตัวแรกทำงานต่อ    |
//|  Strategy Tester ข้ามการล็อก | ไม่มี heartbeat ไม่มีตัวจับเวลา     |
//|  ข้อจำกัด: ตัวแปรกลางแยกต่อเทอร์มินัล ไม่เห็นข้ามเทอร์มินัล         |
//+------------------------------------------------------------------+
#ifndef CORE_LOCK_MQH
#define CORE_LOCK_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"

//--- 2^52 - 1 : double เก็บจำนวนเต็มได้แม่นถึงค่านี้
const long CORE_LOCK_MASK52 = 4503599627370495;

//--- รหัส error ที่ยืนยันจากสคริปต์ทดสอบ 1A (Build 6230)
#define CORE_LOCK_ERR_EXISTS 4502   // สร้างตัวแปรที่มีอยู่แล้ว

//--- ชื่อคีย์ที่จองจริง เก็บไว้ปล่อยให้ตรงคีย์เดิม แม้ Symbol/Magic เปลี่ยนทีหลัง
string g_lockName  = "";
double g_lockOwner = 0.0;
bool   g_lockHeld  = false;

//+------------------------------------------------------------------+
//| รหัสเจ้าของจาก ChartID (ห้ามเป็น 0 เพราะ 0 = ว่าง)                 |
//+------------------------------------------------------------------+
double CoreLockCodeOf(long chartId)
  {
   long masked = chartId & CORE_LOCK_MASK52;

   if(masked == 0)
      masked = 1;

   return((double)masked);
  }

//+------------------------------------------------------------------+
//| บอกว่ารหัสเจ้าของคือกราฟไหน (ว่าง = ไม่พบกราฟนั้นในเทอร์มินัลนี้)  |
//+------------------------------------------------------------------+
string CoreLockOwnerText(double code)
  {
   for(long id = ChartFirst(); id >= 0; id = ChartNext(id))
     {
      if(CoreLockCodeOf(id) == code)
         return(ChartSymbol(id) + ","
                + EnumToString((ENUM_TIMEFRAMES)ChartPeriod(id)));
     }

   return("");
  }

//+------------------------------------------------------------------+
//| จองล็อก (เรียกจาก CoreOnInit) คืน false = ต้องหยุดโหลด EA           |
//+------------------------------------------------------------------+
bool CoreLockAcquire()
  {
   g_lockHeld  = false;
   g_lockName  = "";
   g_lockOwner = 0.0;

   //--- Strategy Tester: ข้ามการล็อก ไม่เขียนตัวแปรจริง
   if((bool)MQLInfoInteger(MQL_TESTER))
      return(true);

   string name = CoreStateGVName("LOCK");

   if(StringLen(name) > 63)
     {
      Alert(CORE_LOG_PREFIX, " LOCK State Key ยาวเกิน 63 ตัวอักษร: ", name);
      return(false);
     }

   double me = CoreLockCodeOf(ChartID());

   //--- สร้างตัวแปรชั่วคราวถ้ายังไม่มี
   //--- error 4502 = มีอยู่แล้ว (กราฟอื่นสร้างไปก่อนพอดี) ถือว่าปกติ
   if(!GlobalVariableCheck(name))
     {
      ResetLastError();

      if(!GlobalVariableTemp(name))
        {
         int tempErr = GetLastError();

         if(tempErr != CORE_LOCK_ERR_EXISTS)
           {
            Alert(CORE_LOG_PREFIX, " LOCK: สร้างตัวแปรล็อกไม่สำเร็จ",
                  " | error=", tempErr);
            return(false);
           }
        }
     }

   for(int attempt = 1; attempt <= 3; attempt++)
     {
      ResetLastError();

      //--- 0 -> รหัสเรา (ตรวจและเขียนพร้อมกัน ชนกันสองตัว ชนะได้ตัวเดียว)
      if(GlobalVariableSetOnCondition(name, me, 0.0))
        {
         g_lockName  = name;
         g_lockOwner = me;
         g_lockHeld  = true;

         Print(CORE_LOG_PREFIX, " LOCK ACQUIRED | ", name);
         return(true);
        }

      int claimErr = GetLastError();
      double owner = 0.0;

      if(!GlobalVariableGet(name, owner))
        {
         Alert(CORE_LOG_PREFIX, " LOCK: อ่านเจ้าของล็อกไม่สำเร็จ",
               " | claim error=", claimErr,
               " | read error=", GetLastError());
         return(false);
        }

      //--- เจ้าของคือกราฟนี้เอง (เช่น init ซ้ำโดยไม่ได้ปล่อย)
      if(owner == me)
        {
         g_lockName  = name;
         g_lockOwner = me;
         g_lockHeld  = true;

         Print(CORE_LOG_PREFIX, " LOCK RE-OWNED | ", name);
         return(true);
        }

      //--- ถูกปล่อยพอดีระหว่างสองคำสั่ง ลองจองใหม่
      if(owner == 0.0)
         continue;

      //--- กราฟอื่นถืออยู่ = หยุดตัวที่แนบทีหลัง
      string ownerChart = CoreLockOwnerText(owner);
      string msg = "หยุดโหลด: มี EA ใช้ Magic " + IntegerToString(InpMagicNumber)
                   + " บน " + _Symbol + " (บัญชีเดียวกัน) ทำงานอยู่แล้ว";

      if(ownerChart != "")
         msg += " | กราฟเจ้าของ: " + ownerChart
                + " | ถอด EA ตัวเดิมออกก่อน หรือเปลี่ยน Magic";
      else
         msg += " | ไม่พบกราฟเจ้าของในเทอร์มินัลนี้ (ล็อกค้าง)"
                " | รีสตาร์ท MT5 เพื่อล้างล็อก";

      Print(CORE_LOG_PREFIX, " LOCK DENIED | ", name, " | ", msg);
      Alert(CORE_LOG_PREFIX, " ", msg);
      return(false);
     }

   Alert(CORE_LOG_PREFIX, " LOCK: จองล็อกไม่สำเร็จหลังลอง 3 ครั้ง | ", name);
   return(false);
  }

//+------------------------------------------------------------------+
//| ปล่อยล็อก (เรียกจาก CoreOnDeinit) ปล่อยได้เฉพาะเจ้าของเท่านั้น      |
//| ตัวที่ถูกบล็อกตอน init ไม่ได้ถือล็อก จึงไม่แตะล็อกของตัวแรก         |
//+------------------------------------------------------------------+
void CoreLockRelease()
  {
   if(!g_lockHeld)
      return;

   ResetLastError();

   if(GlobalVariableSetOnCondition(g_lockName, 0.0, g_lockOwner))
      Print(CORE_LOG_PREFIX, " LOCK RELEASED | ", g_lockName);
   else
      Print(CORE_LOG_PREFIX, " LOCK RELEASE SKIPPED | ", g_lockName,
            " | error=", GetLastError());

   g_lockHeld  = false;
   g_lockName  = "";
   g_lockOwner = 0.0;
  }

#endif // CORE_LOCK_MQH