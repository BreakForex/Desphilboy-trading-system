// Desphilboy Advanced Position Creator
#property copyright "Iman Dezfuly"
#property link      "http://www.Iman.ir"
#define version      "201701121"

#include "./desphilboy.mqh"
#include "./panic.mqh"

extern bool    CreatePositions = false;
extern int     NumberOfBuyStops  = 5;
extern int     NumberOfSellStops  = 5;
extern double  BuyLots = 0.01;
extern double  SellLots = 0.01;
extern double  StartingPrice = 0.0;
extern int     PIPsToStartBuyStops = 100;
extern int     PIPsToStartSellStops = 100;
extern int     DistanceBetweenBuyStops = 250;
extern int     DistanceBetweenSellStops = 250;
extern Groups  BuyStopsGroup = ShortTerm;
extern Groups  SellStopsGroup = ShortTerm;

extern int StopLossBuys = 0;
extern int TakeProfitBuys = 0;
extern int StopLossSells = 0;
extern int TakeProfitSells = 0;
extern int TradesExpireAfterHours = 0;
extern color ColourBuys = clrNONE;
extern color ColourSells = clrNONE;
extern int Slippage = 20;
extern bool PaintPositions = true;
extern color LongTermColour = clrAqua;
extern color MediumTermColour = clrGreen;
extern color ShortTermColour = clrOrangeRed;
extern color UserGroupColour = clrBlue;

static bool once = false;

#define delaySecondsBeforeConfirm 2

void init()
{
   Print("Desphilboy Advanced position creator ",version, " on ", Symbol());
   
   if (PaintPositions) paintPositions();
   
   if ( CreatePositions ) { 
      EventSetTimer(delaySecondsBeforeConfirm); 
      CreatePositions = false;
   }
   
return;
}


void OnTimer() {
   EventKillTimer();
   int result = MessageBox("Are you sure you want to create " + Symbol() +" positions according to params?",
                              "Confirm creation of positions:",
                              MB_OKCANCEL + MB_ICONWARNING +MB_DEFBUTTON2
                              );
   if( result == IDOK){
      once = true;
   }

}



//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
void start() 
{
  if(once) 
   {  
      doPositions();
      once = false;
   }
  return;

}


int doPositions()
{
   
   for(int i=0; i< NumberOfBuyStops; ++i){
      createBuyStop(i);
      }

   for(int j=0; j< NumberOfSellStops; ++j){
       createSellStop(j);             
   }

   return(0); 
}





int createBuyStop( int index)
{

datetime now = TimeCurrent();
datetime expiry = TradesExpireAfterHours != 0 ? now + TradesExpireAfterHours * 3600 : 0;
double baseprice = StartingPrice == 0.0 ? Ask : StartingPrice;
double pip = MarketInfo(Symbol(), MODE_POINT);
double price = baseprice + ( DistanceBetweenBuyStops * index + PIPsToStartBuyStops) * pip;
double stopLoss = StopLossBuys !=0 ? price - StopLossBuys * pip : 0;
double takeProfit = TakeProfitBuys != 0 ? price + TakeProfitBuys * pip : 0;

int result = OrderSend(
                        Symbol(),                   // symbol
                        OP_BUYSTOP,                 // operation
                        BuyLots,                    // volume   
                        price,                      // price
                        Slippage,                   // slippage
                        stopLoss,                  // stop loss
                        takeProfit,                 // take profit
                        NULL,                      // comment
                        createMagicNumber(DAPositionCreator_ID, BuyStopsGroup),           // magic number
                        expiry,                       // pending order expiration
                        ColourBuys                    // color
   );
   
if( result == -1 ) {
   Print( "Order ", index, " creation failed for BuyStop at:", price);
   }
   else {
            if(OrderSelect(result, SELECT_BY_TICKET))
            Print("BuyStop ", index," created at ", price, " with ticket ", OrderTicket(), " Group ", getGroupName(OrderMagicNumber()));    
        }
return result;
}




int createSellStop( int index)
{
datetime now = TimeCurrent();
datetime expiry = TradesExpireAfterHours != 0 ? now + TradesExpireAfterHours * 3600 : 0;
double pip = MarketInfo(Symbol(), MODE_POINT);
double baseprice = StartingPrice == 0.0 ? Bid : StartingPrice;
double price =  baseprice - ( DistanceBetweenSellStops * index + PIPsToStartSellStops) * pip;
double stopLoss = StopLossSells !=0 ? price + StopLossSells * pip : 0;
double takeProfit = TakeProfitSells != 0 ? price - TakeProfitSells * pip : 0;

int result = OrderSend(
                        Symbol(),                   // symbol
                        OP_SELLSTOP,                 // operation
                        SellLots,                    // volume   
                        price,                      // price
                        Slippage,                   // slippage
                        stopLoss,                  // stop loss
                        takeProfit,                 // take profit
                        NULL,                      // comment
                        createMagicNumber(DAPositionCreator_ID, SellStopsGroup),           // magic number
                        expiry,                       // pending order expiration
                        ColourSells                    // color
   );
   
if( result == -1 ) {
   Print( "Order ", index, " creation failed for SellStop at:", price);
   }
   else {
            if(OrderSelect(result, SELECT_BY_TICKET))
            Print("SellStop ", index, " created at ", price, " with ticket ", OrderTicket(), " Group ", getGroupName(OrderMagicNumber()));    
        }
return result;
}  


int paintPositions()
{

color  colour; 
string name;
string symbol;
long chartId;
int subwindow = -1;
datetime xdatetime;
double yprice;
int x;
  
 x = 500;
   chartId = ChartID();
   symbol = Symbol();
   x = (int) (ChartWidthInPixels() * 0.9);
   
   if(ChartXYToTimePrice(
   ChartID(),     // Chart ID
   x,            // The X coordinate on the chart
   0,            // The Y coordinate on the chart
   subwindow,   // The number of the subwindow
   xdatetime,         // Time on the chart
   yprice         // Price on the chart
   ))
   {
      Print( "colouring positions");
   }
   else return 0;
   
  ObjectsDeleteAll(chartId,0, OBJ_ARROW);
           
  for(int i=0; i<OrdersTotal(); i++) {
          
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == symbol) {
         
             if(getGroup(OrderMagicNumber()) == UserGroup ) { colour = UserGroupColour; }
               else if(getGroup(OrderMagicNumber()) == ShortTerm ) { colour = ShortTermColour; }
                     else if(getGroup(OrderMagicNumber()) == MediumTerm ) { colour = MediumTermColour; }
                           else if(getGroup(OrderMagicNumber()) == LongTerm ) { colour = LongTermColour; }
                                 else {
                                    colour = clrNONE;
                                 }
            name = Symbol() + "-" + getGroupName(OrderMagicNumber()) + "-" + IntegerToString(i);
            bool bResult = ObjectCreate(
                              chartId
                              , name 
                              , OBJ_ARROW_BUY  
                              , 0  
                              , xdatetime  
                              , OrderOpenPrice());
            if(!bResult){
               Print (" could not paint arrow for position", OrderTicket());
            } else {
                  ObjectSetInteger(chartId, name, OBJPROP_COLOR, colour);
              }                                
           }
      }
   }
      
   return(0); 
}

int ChartWidthInPixels(const long chart_ID=0)
  {
//--- prepare the variable to get the property value
   long result=-1;
//--- reset the error value
   ResetLastError();
//--- receive the property value
   if(!ChartGetInteger(chart_ID,CHART_WIDTH_IN_PIXELS,0,result))
     {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
     }
//--- return the value of the chart property
   return((int)result);
  }