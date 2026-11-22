//+------------------------------------------------------------------+
//|                                                Core_Identity.mqh |
//|  ตรวจป้ายชื่อ EA (มติ D-12): เทียบ InpTradeComment กับ Magic จริง |
//|  รูปแบบ Comment: <TAG><Magic> <ข้อความ> เช่น HDG10019 H1 BE_FIXED |
//|  ไม่พบความไม่ตรง = คืน true  | พบ = เตือน (Print + Alert) คืน false|
//|  ไม่หยุดโหลด EA (แจ้งเตือนอย่างเดียว)                              |
//+------------------------------------------------------------------+
#ifndef CORE_IDENTITY_MQH
#define CORE_IDENTITY_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"
#include "Core_StrategyAPI.mqh"

//--- ความยาวสูงสุดของ Comment ใน .set (เผื่อข้อความที่โบรกเกอร์ต่อท้าย)
#define CORE_COMMENT_MAX_LEN 25

//--- ข้อความเตือนสำหรับ Panel (ว่าง = ไม่มีปัญหา)
string g_identityWarning = "";

//+------------------------------------------------------------------+
//| ช่วง Magic ของ EA ลำดับนี้ เช่น "10000-19999"                     |
//+------------------------------------------------------------------+
string CoreIdentityRangeText()
  {
   long lo = (long)STRATEGY_EA_ORDINAL * 10000;
   return(IntegerToString(lo) + "-" + IntegerToString(lo + 9999));
  }

//+------------------------------------------------------------------+
//| ตรวจความสอดคล้องของ TAG / Magic / Comment (เรียกจาก OnInit)       |
//+------------------------------------------------------------------+
bool CoreCheckIdentity()
  {
   g_identityWarning = "";

   //--- ปิดการตรวจ: เงียบทั้งหมด ไม่มี Alert ไม่มี Log ไม่มีแถวแดงบน Panel
   if(!InpIdentityCheck)
      return(true);

   string problem = "";

   string comment = InpTradeComment;
   StringTrimLeft(comment);
   StringTrimRight(comment);

   //--- คำแรกของ Comment = <TAG><Magic>
   int sp = StringFind(comment, " ");
   string token = (sp < 0) ? comment : StringSubstr(comment, 0, sp);

   long lo = (long)STRATEGY_EA_ORDINAL * 10000;
   long hi = lo + 9999;

   if(StringLen(comment) == 0)
      problem = "COMMENT_EMPTY";
   else
     {
      string tag    = StringSubstr(token, 0, 3);
      string digits = StringSubstr(token, 3);

      bool digitsOk = (StringLen(digits) > 0);

      for(int i = 0; i < StringLen(digits); i++)
        {
         int ch = (int)StringGetCharacter(digits, i);

         if(ch < 48 || ch > 57)
           {
            digitsOk = false;
            break;
           }
        }

      if(StringLen(token) < 4 || !digitsOk)
         problem = "COMMENT_FORMAT(expect <TAG><Magic>)";
      else if(tag != STRATEGY_TAG)
         problem = "TAG_MISMATCH(comment=" + tag
                   + " expected=" + STRATEGY_TAG + ")";
      else if(StringToInteger(digits) != InpMagicNumber)
         problem = "MAGIC_MISMATCH(comment=" + digits
                   + " input=" + IntegerToString(InpMagicNumber) + ")";
      else if(InpMagicNumber < lo || InpMagicNumber > hi)
         problem = "MAGIC_OUT_OF_RANGE(magic="
                   + IntegerToString(InpMagicNumber)
                   + " range=" + CoreIdentityRangeText() + ")";
      else if(StringLen(comment) > CORE_COMMENT_MAX_LEN)
         problem = "COMMENT_TOO_LONG(" + IntegerToString(StringLen(comment))
                   + ">" + IntegerToString(CORE_COMMENT_MAX_LEN) + ")";
     }

   if(problem == "")
      return(true);

   g_identityWarning = "ID MISMATCH: " + problem;

   string msg = "IDENTITY MISMATCH | " + problem
                + " | Range=" + CoreIdentityRangeText()
                + " | NextSuggested=" + IntegerToString(STRATEGY_MAGIC_NEXT)
                + " | Comment='" + InpTradeComment + "'"
                + " | Magic=" + IntegerToString(InpMagicNumber);

   Print(CORE_LOG_PREFIX, " ", msg);
   Alert(CORE_LOG_PREFIX, " ", msg);

   return(false);
  }

#endif // CORE_IDENTITY_MQH