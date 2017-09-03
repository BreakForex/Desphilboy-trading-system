//version  20170301
// heaer file for desphilboy
//+------------------------------------------------------------------+
//|                                                   desphilboy.mqh |
//|                                                       Desphilboy |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Desphilboy"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// desphilboy system unique Identifier is Mahmaraza Rahvareh My best friend who died in Motorcycle accident
#define     MAHMARAZA_RAHVARA_ID 1921              // He loved this number, was his magic number
#define     GROUP_SHIFT_CONSTANT 10000

// 3 default groups IDs long term, medium term and short term positions plus one custom group for user
#define     VERYLONGTERMGROUP 10000
#define     LONGTERMGROUP     20000
#define     MEDTERMGROUP      30000
#define     SHORTTERMGROUP    40000
#define     USERGROUP         50000

enum Groups          { NoGroup=0, VeryLongTerm=VERYLONGTERMGROUP, LongTerm=LONGTERMGROUP, MediumTerm=MEDTERMGROUP, ShortTerm=SHORTTERMGROUP, UserGroup=USERGROUP };
enum BuyTypes        { Buy, BuyLimit, BuyStop};
enum SellTypes       { Sell, SellLimit, SellStop}; 
enum TradeActs       { Initialize, Repair, Append, Terminate, NoAction };
enum GroupIds        { gid_NoGroup=0, gid_VeryLongTerm=1, gid_LongTerm=2, gid_MediumTerm=3, gid_ShortTerm=4, gid_UserGroup=5 };
enum TrailingFields  { TrailingStop=0, Step=1, Retrace=2, LifePeriod=3 };
enum LifeTimes       { FiveMinutes=5, TenMinutes=10, Quarter=15, Hour=60, TwoHours=120, FourHours=240, EightHours=480, SixteenHours=960, Day=1440, TwoDays=2880, SixtyFourHours=3840, ThreeDays=4320, FiveDays=7200 };

 

// EA signature on the position
#define     ImanTrailing_ID               100000
#define     GroupedImanTrailing_ID        200000
#define     DesphilboyPositionCreator_ID  300000
#define     DAPositionCreator_ID          400000

// fibonacci
enum FiboRetrace {NoRetrace=0, MinRetrace, LowRetrace, HalfRetrace, MaxRetrace};
double Fibo[]={0.000, 0.236, 0.382, 0.500, 0.618};

static int TrailingInfo[gid_UserGroup +1][LifePeriod + 1]; 

// common functions to work with Magic Numbers
int createMagicNumber( int eaId, int groupId)
{
   return eaId + groupId + MAHMARAZA_RAHVARA_ID;
}

bool isDesphilboy( int magicNumber)
{
   return (magicNumber % 10000) == MAHMARAZA_RAHVARA_ID;
}

bool isVeryLongTerm( int magicNumber)
{
   if(isDesphilboy(magicNumber)){
      return ((magicNumber % 100000) - MAHMARAZA_RAHVARA_ID) == VERYLONGTERMGROUP;
   }
   return false;
}


bool isLongTerm( int magicNumber)
{
   if(isDesphilboy(magicNumber)){
      return ((magicNumber % 100000) - MAHMARAZA_RAHVARA_ID) == LONGTERMGROUP;
   }
   return false;
}

bool isShortTerm( int magicNumber)
{
   if(isDesphilboy(magicNumber)){
      return ((magicNumber % 100000) - MAHMARAZA_RAHVARA_ID) == SHORTTERMGROUP;
   }
   return false;
}


bool isMediumTerm( int magicNumber)
{
   if(isDesphilboy(magicNumber)){
      return ((magicNumber % 100000)- MAHMARAZA_RAHVARA_ID) == MEDTERMGROUP;
   }
   return false;
}


bool isUserGroup( int magicNumber)
{
   if(isDesphilboy(magicNumber)){
      return ((magicNumber % 100000)- MAHMARAZA_RAHVARA_ID) == USERGROUP;
   }
   return false;
}

bool isManual(int magicNumber)
{
return magicNumber == 0;
}


string getGroupName( int magicNumber)
{
   if(isVeryLongTerm(magicNumber)) { return "VeryLongTerm"; }
         else if(isLongTerm(magicNumber)) { return "LongTerm"; }
               else if(isMediumTerm(magicNumber)){return "MediumTerm";}
                     else if(isShortTerm(magicNumber)){return "ShortTerm";}
                           else if(isUserGroup(magicNumber)){return "UserGroup";}
                                    else if(isManual(magicNumber)){ return "Manual";}
                                             else return "Unknown";

}


Groups getGroup( int magicNumber )
{
if(isVeryLongTerm(magicNumber)) { return VeryLongTerm; }
      else if(isLongTerm(magicNumber)) { return LongTerm; }
            else if(isMediumTerm(magicNumber)){return MediumTerm;}
                  else if(isShortTerm(magicNumber)){return ShortTerm;}
                        else if(isUserGroup(magicNumber)){return UserGroup;}
return NoGroup;
}

GroupIds getGroupId( int magicNumber )
{
if(isVeryLongTerm(magicNumber)) { return gid_VeryLongTerm; }
      else if(isLongTerm(magicNumber)) { return gid_LongTerm; }
            else if(isMediumTerm(magicNumber)){return gid_MediumTerm;}
                  else if(isShortTerm(magicNumber)){return gid_ShortTerm;}
                        else if(isUserGroup(magicNumber)){return gid_UserGroup;}
return gid_NoGroup;
}


int getPositionsInterval(string symbol, int operation, double rangeLow, double rangeHi,int &results[])
{
   int resultCounter = 0;
   
     for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()==symbol && OrderType()==operation && OrderOpenPrice() > rangeLow && OrderOpenPrice() < rangeHi) 
           {
               results[resultCounter] = OrderTicket();
               resultCounter++;
           }
        }
     }
     
     return resultCounter;
} 


int getPositionsInterval(string symbol, int operation, double rangeLow, double rangeHi,int &results[], bool spaceOpenPositions=false, int group = NoGroup)
{
   int resultCounter = 0;
   
   int openPosType = (operation == OP_SELLSTOP || operation == OP_SELLLIMIT ) ? OP_SELL : OP_BUY ; 
   
     for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()==symbol 
           && (OrderType()==operation || (OrderType() == openPosType && spaceOpenPositions)) 
           && OrderOpenPrice() > rangeLow 
           && OrderOpenPrice() < rangeHi
           && ( group == NoGroup || getGroup(OrderMagicNumber()) <= group || (OrderType() == openPosType && spaceOpenPositions)))
           {
               results[resultCounter] = OrderTicket();
               resultCounter++;
           }
        }
     }
     
     return resultCounter;
} 


int getPositionsInRange(string symbol, int operation, double center, int PIPsMargin, int &results[], bool spaceOpenPositions=false, int group = NoGroup)
{
   double pip = MarketInfo(symbol, MODE_POINT);
   double l = center - PIPsMargin * pip;
   double h = center + PIPsMargin * pip;
 return getPositionsInterval(symbol,operation, l, h, results, spaceOpenPositions, group);
}


int getPositionsIntervalSameGroup(string symbol, int operation, double rangeLow, double rangeHi,int &results[], bool spaceOpenPositions=false, int group = NoGroup)
{
   int resultCounter = 0;
   
   int openPosType = (operation == OP_SELLSTOP || operation == OP_SELLLIMIT ) ? OP_SELL : OP_BUY ; 
   
     for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()==symbol 
           && (OrderType()==operation || (OrderType() == openPosType && spaceOpenPositions)) 
           && OrderOpenPrice() > rangeLow 
           && OrderOpenPrice() < rangeHi
           && ( group == NoGroup || getGroup(OrderMagicNumber()) == group ))
           {
               results[resultCounter] = OrderTicket();
               resultCounter++;
           }
        }
     }
     
     return resultCounter;
} 


int getPositionsInRangeSameGroup(string symbol, int operation, double center, int PIPsMargin, int &results[], bool spaceOpenPositions=false, int group = NoGroup)
{
   double pip = MarketInfo(symbol, MODE_POINT);
   double l = center - PIPsMargin * pip;
   double h = center + PIPsMargin * pip;
 return getPositionsIntervalSameGroup(symbol,operation, l, h, results, spaceOpenPositions, group);
}


int getCurrentTrailingStop( int tradeTicket, int& trailingInfo[][])
{

if( !OrderSelect(tradeTicket, SELECT_BY_TICKET, MODE_TRADES) ) { return 0; }

GroupIds orderGroup = getGroupId(OrderMagicNumber());

if( OrderStopLoss() != 0) {
   
   return trailingInfo[orderGroup][TrailingStop];
}
 
if( trailingInfo[orderGroup][LifePeriod] == PERIOD_CURRENT) {
   
   return trailingInfo[orderGroup][TrailingStop];
}

int minutesElapsed = getMinutesOld(OrderOpenTime());
int lifeTimeInMinutes = trailingInfo[orderGroup][LifePeriod];
int timesLifeTimeElapsed = (int) (minutesElapsed / lifeTimeInMinutes);
int orderTrailingStop = (int) (trailingInfo[orderGroup][TrailingStop] / (1+timesLifeTimeElapsed));
return  orderTrailingStop;
}


int getMinutesOld( datetime creationTime) {

int diff = (int) (TimeCurrent() -  creationTime);

return (int) diff / 60 ;
}