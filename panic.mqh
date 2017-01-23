//+------------------------------------------------------------------+
//|                                                        Panic.mqh |
//|                                                       Desphilboy |
//+------------------------------------------------------------------+
#property copyright "Desphilboy"

#include "./desphilboy.mqh"

static double tickValue;
static double exTickIncrement[7];
static double AvgTickIncrement[7];
static double dpOdt[7];
#define  PANIC_PIPS  120
#define  MAX_LOTS_PER_1000AUD      0.15
#define  POSITION_SIZE_PER1000AUD  0.05
 

double getLotBalance( string symbol){

   double lots = 0;

   for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()== symbol) 
           {
            if( OrderType() == OP_BUY ) lots = lots + OrderLots();
            if(OrderType() == OP_SELL ) lots = lots - OrderLots();
           }
        }
      }
       
   return lots;
}

int getNearestBuyStop(string symbol){
   int ticket = 0;
   int nearestPIPs = 10000;
   double vask    = MarketInfo(symbol,MODE_ASK);
   
   for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()== symbol) 
           {
             if( OrderType() == OP_BUYSTOP ) {
                   double point = MarketInfo(symbol, MODE_POINT);
                   int priceChangePIPs = (int)(MathAbs(vask -OrderOpenPrice()) / (point *10));
                   if( priceChangePIPs < nearestPIPs ) {
                     ticket = OrderTicket();
                     nearestPIPs = priceChangePIPs;
                    }
                  
               }
           }
        }
      }
   return ticket;
}

int getNearestSellStop(string symbol){
   int ticket = 0;
   int nearestPIPs = 10000;
   double vbid    = MarketInfo(symbol, MODE_BID);
   
   for(int i=0; i<OrdersTotal(); i++) 
     {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
        {
           if (OrderSymbol()== symbol) 
           {
             if( OrderType() == OP_SELLSTOP ) {
                   double point = MarketInfo(symbol, MODE_POINT);
                   int priceChangePIPs = (int)(MathAbs(vbid -OrderOpenPrice()) / (point *10));
                   if( priceChangePIPs < nearestPIPs ) {
                     ticket = OrderTicket();
                     nearestPIPs = priceChangePIPs;
                    }
                  
               }
           }
        }
      }
   return ticket;
}

double getLotsAllowed(){
   double lots = NormalizeDouble((MAX_LOTS_PER_1000AUD * AccountEquity())/1000, 2);
   return lots;
}


double getPositionSize(){
   double lots = NormalizeDouble((POSITION_SIZE_PER1000AUD * AccountEquity())/1000, 2);
   return lots;
}



bool isPanic( string symbol, ENUM_TIMEFRAMES panicTimeFrame = PERIOD_M15){
   
   MqlRates rates[];
   int priceChangePIPs = 0;
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(symbol,panicTimeFrame,0,10,rates);
   if(copied>0)
     {
      double point = MarketInfo(symbol, MODE_POINT);
      priceChangePIPs = (int)((rates[0].high - rates[0].low) / (point *10));
       Print ("PIPS change is:", (string) priceChangePIPs);
      return priceChangePIPs >= PANIC_PIPS;
     
      }
      else {
         Print ("Error: Panic detector could not retrieve rates for " + symbol);
      }
    Print ("PIPS change is:", (string) priceChangePIPs);
    return false;
}
      
    
/*
* the following functions calculate a discontinuity index of price or gapIndex  exponential
* Params: 
* string pairName, is the symbol you want to calculate ga[p index for it.
* int depth, number of time frames to go back 
* expFactor, less than 1 and greater than zero is the amount of emphasis you put on previouse avg in calculation expFactor = 0 means less emphasis 
*/
double gapIndexExp(string pairName, ENUM_TIMEFRAMES timeFrame = PERIOD_M1 , int depth = 10, double expFactor = 0.5){
MqlRates priceData[100];
   ArraySetAsSeries(priceData, false);
   
   if(expFactor > 1 || expFactor < 0) expFactor = 0.5;
   double vpoint  = MarketInfo(pairName, MODE_POINT);
   
   int numPrices = CopyRates(
                           pairName,      // symbol name
                           timeFrame,        // period
                           0,        // start position
                           depth,            // data count to copy
                           priceData    // target array for tick volumes
                           );
   
   if(numPrices < 2) { 
                     Print( "Error getting ", depth, " price informations for gap index calculation."); 
                     return -1;
   }     
              
   double result = 0;
   for( int i= 1; i < numPrices; ++i){
         result = result * expFactor + MathAbs(priceData[i].open - priceData[i - 1].close)/vpoint * ( 1- expFactor);
   } 
   
   return result;
}

/*
* the following functions calculate a discontinuity index of price or gapIndex  simple
* Params: 
* string pairName, is the symbol you want to calculate ga[p index for it.
* int depth, number of time frames to go back 
*/
double gapIndex(string pairName, ENUM_TIMEFRAMES timeFrame = PERIOD_M1 , int depth = 10){
MqlRates priceData[100];
   ArraySetAsSeries(priceData, false);
   
   double vpoint  = MarketInfo(pairName, MODE_POINT);
   
   int numPrices = CopyRates(
                           pairName,      // symbol name
                           timeFrame,        // period
                           0,        // start position
                           depth,            // data count to copy
                           priceData    // target array for tick volumes
                           );
   
   if(numPrices < 2) { 
                     Print( "Error getting ", depth, " price informations for gap index calculation."); 
                     return -1;
   }     
              
   double sum = 0;
   for( int i= 1; i < numPrices; ++i){
         sum = sum  + MathAbs(priceData[i].open - priceData[i - 1].close)/vpoint;
   } 
   return sum/(numPrices -1);
}



/*
* the following functions calculate a discontinuity index of price or gapIndex  exponential
* Params: 
* string pairName, is the symbol you want to calculate ga[p index for it.
* int depth, number of time frames to go back 
* expFactor, less than 1 and greater than zero is the amount of emphasis you put on previouse avg in calculation expFactor = 0 means less emphasis 
*/
double volAvExp(string pairName, ENUM_TIMEFRAMES timeFrame = PERIOD_M1 , int depth = 10, double expFactor = 0.5){
long volData[100];
   ArraySetAsSeries(volData, false);
   
   if(expFactor > 1 || expFactor < 0) expFactor = 0.5;
   
   int numPrices = CopyTickVolume(
                           pairName,      // symbol name
                           timeFrame,        // period
                           0,        // start position
                           depth,            // data count to copy
                           volData    // target array for tick volumes
                           );
   
   if(numPrices < 2) { 
                     Print( "Error getting ", depth, " volume informations for vol index calculation."); 
                     return -1;
   }     
              
   double result = 0;
   for( int i= 0; i < numPrices; ++i){
         result = result * expFactor + volData[i] * ( 1- expFactor);
   } 
   
   return result;
}

/*
* the following functions calculate a discontinuity index of price or gapIndex  simple
* Params: 
* string pairName, is the symbol you want to calculate ga[p index for it.
* int depth, number of time frames to go back 
*/
double volAv(string pairName, ENUM_TIMEFRAMES timeFrame = PERIOD_M1 , int depth = 10){
long volData[100];
   ArraySetAsSeries(volData, false);
   
   double vpoint  = MarketInfo(pairName, MODE_POINT);
   
   int numPrices = CopyTickVolume(
                           pairName,      // symbol name
                           timeFrame,        // period
                           0,        // start position
                           depth,            // data count to copy
                           volData    // target array for tick volumes
                           );
   
   if(numPrices < 2) { 
                     Print( "Error getting ", depth, " price informations for gap index calculation."); 
                     return -1;
   }     
              
   double sum = 0;
   for( int i= 0; i < numPrices; ++i){
         sum = sum  + volData[i];
   } 
   return sum/(numPrices);
}