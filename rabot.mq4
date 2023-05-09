//+------------------------------------------------------------------+
//|                                                        Rabot.mq4 |
//|                                     Copyright 2023 Rafed M Yasir |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023 Rafed M Yasir"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int BUY        = 1;
int SELL       = -1;
int DO_NOTHING = 0;

int advancedBollingerBandsStrategy(float deviation)
{
   int periods = 20;    // number of periods for Bollinger Bands calculation

   double lowerBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
   double upperBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
   
   double prevLowerBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
   double prevUpperBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
   
   // price is above last close && close2 was below lower band && close1 is above lower band
   if (Ask > Close[1] && Close[2] < prevLowerBB && Close[1] > lowerBB){
      return BUY;
   }
   
   if (Bid < Close[1] && Close[2] > prevUpperBB && Close[1] < upperBB){
      return SELL;
   }
  
   return DO_NOTHING;
}

int bollingerBandsStrategy(float deviation)
{
   int     periods = 20;    // number of periods for Bollinger Bands calculation

   double lowerBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
   double upperBB = iBands(_Symbol, _Period, periods, deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
   
   // price is above last close && close2 was below lower band && close1 is above lower band
   if (Ask < lowerBB)
      return BUY;
   
   if (Bid > upperBB)
      return SELL;

   return DO_NOTHING;
}

int RSIStrategy(){
   double RSIValue = iRSI(_Symbol, _Period, 14, PRICE_CLOSE, 0);
   if(RSIValue > 70)
      return SELL;
      
   if(RSIValue <30)
      return BUY;
      
   return DO_NOTHING;
}


static datetime LastAlert=0;
void AlertChannels(string msg){
   if(TimeCurrent() < LastAlert + 120)
      return;

   LastAlert = TimeCurrent();
   
   msg = TimeToStr(CurTime()) + ": " + Symbol() + " " + msg;
   
   Alert(msg);
   Print(msg);
   // SendNotification(msg);
   //Comment(msg);
}

void OnTick()
{
   // STRATEGY #1
   int bollingerBandsSignal = bollingerBandsStrategy(2.5);
   int RSIStrategySignal = RSIStrategy();

   if(bollingerBandsSignal < 0 && RSIStrategySignal < 0)
      AlertChannels("RSI+BB - Strong SELL");
   else if(bollingerBandsSignal < 0)
      AlertChannels("RSI+BB - SELL");

   if(bollingerBandsSignal > 0 && RSIStrategySignal > 0)
      AlertChannels("RSI+BB - Strong BUY");
   else if(bollingerBandsSignal > 0)
      AlertChannels("RSI+BB - BUY");
  
   
   // STRATEGY #2
   int advancedBollingerBandsStrategySignal = advancedBollingerBandsStrategy(2);
   if (advancedBollingerBandsStrategySignal > 0)
      AlertChannels("AdvancedBB - BUY");
    
   if (advancedBollingerBandsStrategySignal < 0)
      AlertChannels("AdvancedBB - SELL");
}
