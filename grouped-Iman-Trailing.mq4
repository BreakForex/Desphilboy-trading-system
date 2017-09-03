// simple trailing stop
#property copyright "Iman Dezfuly"
#property link      "http://www.Iman.ir"

#define version      "201704171"

#include "./desphilboy.mqh"

extern bool   AllPositions  =True;         
extern int    TrailingStopVL = 300, TrailingStopL = 200, TrailingStopM = 110, TrailingStopS = 70, TrailingStopU = 40;            
extern int    TrailingStepVL  =30, TrailingStepL  =30, TrailingStepM = 30, TrailingStepS = 20, TrailingStepU = 20;             
extern FiboRetrace  RetraceFactorVL=MaxRetrace, RetraceFactorL=MaxRetrace, RetraceFactorM = HalfRetrace, RetraceFactorS = LowRetrace, RetraceFactorU = MinRetrace;
extern LifeTimes TimeFrameVL=ThreeDays, TimeFrameL=SixteenHours, TimeFrameM=FourHours, TimeFrameS=Hour, TimeFrameU=Quarter;

int fillTrailingInfo( int& tinfo[][])
{
tinfo[gid_NoGroup][0] = tinfo[gid_NoGroup][1] = tinfo[gid_NoGroup][2] = tinfo[gid_NoGroup][3] = 0;
tinfo[gid_VeryLongTerm][TrailingStop]=TrailingStopVL; tinfo[gid_VeryLongTerm][Step]=TrailingStepVL; tinfo[gid_VeryLongTerm][Retrace]=RetraceFactorVL; tinfo[gid_VeryLongTerm][LifePeriod]=TimeFrameVL;
tinfo[gid_LongTerm][TrailingStop]=TrailingStopL; tinfo[gid_LongTerm][Step]=TrailingStepL; tinfo[gid_LongTerm][Retrace]=RetraceFactorL; tinfo[gid_LongTerm][LifePeriod]=TimeFrameL;
tinfo[gid_MediumTerm][TrailingStop]=TrailingStopM; tinfo[gid_MediumTerm][Step]=TrailingStepM; tinfo[gid_MediumTerm][Retrace]=RetraceFactorM; tinfo[gid_MediumTerm][LifePeriod]=TimeFrameM;
tinfo[gid_ShortTerm][TrailingStop]=TrailingStopS; tinfo[gid_ShortTerm][Step]=TrailingStepS; tinfo[gid_ShortTerm][Retrace]=RetraceFactorS; tinfo[gid_ShortTerm][LifePeriod]=TimeFrameS;
tinfo[gid_UserGroup][TrailingStop]=TrailingStopU; tinfo[gid_UserGroup][Step]=TrailingStepU; tinfo[gid_UserGroup][Retrace]=RetraceFactorU; tinfo[gid_UserGroup][LifePeriod]=TimeFrameU;
return 0;
}


int init()
{
  Print("Grouped trailing stop version ",version);
  Print("stops(VL,L,M,S,U):", TrailingStopVL, ",",TrailingStopL, ",", TrailingStopM, ",", TrailingStopS, ",", TrailingStopU); 
  Print("steps(VL,L,M,S,U):", TrailingStepVL, ",", TrailingStepL, ",", TrailingStepM, ",", TrailingStepS, ",", TrailingStepU);
  Print("Retraces(VL,L,M,S,U):", RetraceFactorVL, ",", RetraceFactorL, ",", RetraceFactorM, ",", RetraceFactorS, ",", RetraceFactorU);
  Print("LifeTimes(VL,L,M,S,U):", TimeFrameVL, ",", TimeFrameL, ",", TimeFrameM, ",", TimeFrameS, ",", TimeFrameU);
  fillTrailingInfo(TrailingInfo);
  return(0); 
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
  void start() 
  {
     for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (AllPositions || OrderSymbol()==Symbol()) 
           {
           if(isVeryLongTerm(OrderMagicNumber())) {TrailingPositions(getCurrentTrailingStop(OrderTicket(),TrailingInfo), TrailingStepVL, RetraceFactorVL);}
                  else if(isLongTerm(OrderMagicNumber())) {TrailingPositions(getCurrentTrailingStop(OrderTicket(),TrailingInfo), TrailingStepL, RetraceFactorL);}
                        else if(isMediumTerm(OrderMagicNumber())){TrailingPositions(getCurrentTrailingStop(OrderTicket(),TrailingInfo), TrailingStepM, RetraceFactorM);}
                            else if(isShortTerm(OrderMagicNumber())){TrailingPositions(getCurrentTrailingStop(OrderTicket(),TrailingInfo), TrailingStepS, RetraceFactorS);}
                                 else if(isUserGroup(OrderMagicNumber())){TrailingPositions(getCurrentTrailingStop(OrderTicket(),TrailingInfo), TrailingStepU, RetraceFactorU);}
           }
        }
     }
  }
  
   
//+------------------------------------------------------------------+
//|This function trails the position which is selected.                        |
//+------------------------------------------------------------------+
  void TrailingPositions(int TrailingStop, int TrailingStep,FiboRetrace RetraceFactor) 
  {
   double pBid, pAsk, pp, pDiff, pRef, pStep, pRetraceTrail, pDirectTrail;
//----

   double RetraceValue=Fibo[RetraceFactor];
   pp=MarketInfo(OrderSymbol(), MODE_POINT);
   pDirectTrail = TrailingStop * pp;
   pStep = TrailingStep * pp;
   
     if (OrderType()==OP_BUY) 
     {
      pBid = MarketInfo(OrderSymbol(), MODE_BID);
      pDiff = pBid - OrderOpenPrice();
      pRetraceTrail = pDiff > pDirectTrail ? (pDiff - pDirectTrail) * RetraceValue : 0;
      pRef = pBid - pDirectTrail - pRetraceTrail; 
      
        if (pRef - OrderOpenPrice() > 0 ) 
        {// order is in profit.
           if ((OrderStopLoss() != 0.0 && pRef - OrderStopLoss() > pStep && pRef - OrderOpenPrice() > pStep)  || (OrderStopLoss() == 0.0 && pRef - OrderOpenPrice() > pStep)) 
           {
            ModifyStopLoss(pRef);
            return;
           }
        }
     }
     
     if (OrderType()==OP_SELL) 
     {
      pAsk = MarketInfo(OrderSymbol(), MODE_ASK);
      pDiff = OrderOpenPrice() - pAsk;
      pRetraceTrail = pDiff > pDirectTrail ? (pDiff - pDirectTrail) * RetraceValue : 0;
      pRef = pAsk + pDirectTrail + pRetraceTrail; 
      
        if (OrderOpenPrice()- pRef > 0) 
        {// order is in profit.
           if ((OrderStopLoss() != 0.0 && OrderStopLoss() - pRef > pStep && OrderOpenPrice() - pRef > pStep) || (OrderStopLoss() == 0.0 && OrderOpenPrice() - pRef > pStep))
           {
            ModifyStopLoss(pRef);
            return;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|   this modifies a selected order and chages its stoploss                                      |
//|                                           
//|   Params: ldStopLoss  , double is the new value for stoploss                          
//+------------------------------------------------------------------+
  void ModifyStopLoss(double ldStopLoss) 
  {
   bool fm;
   fm=OrderModify(OrderTicket(),OrderOpenPrice(),ldStopLoss,OrderTakeProfit(),0,CLR_NONE);
   
   if (fm){
   Print("Order ", OrderTicket(), " modified to Stoploss=",ldStopLoss," group:", getGroupName(OrderMagicNumber()));
   } else{
   Print("could not modify order:",OrderTicket(), " group:", getGroupName(OrderMagicNumber()));
   }
  }
//+------------------------------------------------------------------+