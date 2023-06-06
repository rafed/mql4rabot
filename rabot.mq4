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

static datetime LastM5Alert  = 0; static int M5_delay  = 60 * 2;
static datetime LastM15Alert = 0; static int M15_delay = 60 * 3;
static datetime LastM30Alert = 0; static int M30_delay = 60 * 4;
static datetime LastH1Alert  = 0; static int H1_delay  = 60 * 5;
static datetime LastH4Alert  = 0; static int H4_delay  = 60 * 10;
static datetime LastD1Alert  = 0; static int D1_delay  = 60 * 20;
static datetime LastW1Alert  = 0; static int W1_delay  = 60 * 30;

bool shouldLimitAlert(int timeframe){
   if(timeframe == PERIOD_M5){
      if(TimeCurrent() < LastM5Alert + M5_delay) return true ;
      LastM5Alert = TimeCurrent();
   } else if(timeframe == PERIOD_M15){
      if(TimeCurrent() < LastM15Alert + M15_delay) return true ;
      LastM15Alert = TimeCurrent();
   } else if(timeframe == PERIOD_M30){
      if(TimeCurrent() < LastM30Alert + M30_delay) return true ;
      LastM30Alert = TimeCurrent();
   } else if(timeframe == PERIOD_H1){
      if(TimeCurrent() < LastH1Alert + H1_delay) return true ;
      LastH1Alert = TimeCurrent();
   } else if(timeframe == PERIOD_H4){
      if(TimeCurrent() < LastH4Alert + H4_delay) return true ;
      LastH4Alert = TimeCurrent();
   } else if (timeframe == PERIOD_D1){
      if(TimeCurrent() < LastD1Alert + D1_delay) return true ;
      LastD1Alert = TimeCurrent();
   } else if (timeframe == PERIOD_W1){
      if(TimeCurrent() < LastW1Alert + W1_delay) return true ;
      LastW1Alert = TimeCurrent();
   }
   
   return false;
}

string resolveTimeframe(int timeframe){
   if(timeframe == PERIOD_M1)  return "M1";
   if(timeframe == PERIOD_M5)  return "M5";
   if(timeframe == PERIOD_M15) return "M15";
   if(timeframe == PERIOD_M30) return "M30";
   if(timeframe == PERIOD_H1)  return "H1";
   if(timeframe == PERIOD_H4)  return "H4";
   if(timeframe == PERIOD_D1)  return "D1";
   if(timeframe == PERIOD_W1)  return "W1";
   return "Unknown";
}

void AlertChannels(string action, int timeframe, string strategy){ // (BUY, H4, Bollinger Bands)
   // if(currencyOrderOpen()) return;
   // string action = action == BUY ? "BUY" : (action == SELL ? "SELL" : "Do Nothing")
   if(shouldLimitAlert(timeframe)) return;
   
   string msg = TimeToStr(CurTime()) + ": " + action + " " +  _Symbol + " " + resolveTimeframe(timeframe) + " " + strategy;
   
   Alert(msg);
   Print(msg);
   SendNotification(msg);
}

double detectTrendDirection(int trendline_period){
   double trendline_last_candle = iMA(_Symbol, _Period, trendline_period, 0, MODE_EMA, PRICE_CLOSE, 0);
   double trendline_first_candle = iMA(_Symbol, _Period, trendline_period, 0, MODE_EMA, PRICE_CLOSE, trendline_period);
   double trendline_slope = trendline_last_candle - trendline_first_candle;
   
   return trendline_slope;
}

bool currencyOrderOpen(){ 
   for(int i = 0 ; i < OrdersTotal() ; i++) { 
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES); 
      if (OrderSymbol() == _Symbol) return true; 
   }    
   return false; 
} 

/////////////////// FRESHHHHHHHHHHHHHHH ///////////////
double CalculateLotSize(double risk, double entryPrice, double stopLossPrice, double accountBalance)
{
    double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double distance = MathAbs(entryPrice - stopLossPrice);
    int digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
    double stopLossSize = (distance / MarketInfo(Symbol(), MODE_POINT)) * pipValue;

    double lotSize = (accountBalance * (risk / 100.0)) / (stopLossSize * MarketInfo(Symbol(), MODE_TICKSIZE));

    return NormalizeDouble(lotSize, 2);
}

double CalculateLotSize(double risk, double entryPrice, double stopLoss)
{
   double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE); 
   double lotSize = (AccountBalance() * (risk / 100.0)) / (stopLoss * MarketInfo(Symbol(), MODE_TICKSIZE));
   return NormalizeDouble(lotSize, 2);
}

/*
void openTrade(int action, double risk, double SL, double TP){
   if(OrdersTotal() > 10) return;
   if(action == BUY)
      OrderSend(_Symbol, OP_BUY, Lots, Ask, 3, Stop_Loss, Take_Profit, Comments, 0, 0, NULL);
   
   if(action == SELL)
   
}*/


bool isCurrentSymbol(string curr_pair){
   int pos = StringFind(_Symbol, curr_pair);
   if(pos == -1)
      return false;
   return true;
}

void scalpingStrategy(int timeframe){
   int deviation = 2.5;
   int period = 20;
   
   double ma1 = iMA(_Symbol, timeframe, 10, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ma2 = iMA(_Symbol, timeframe, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ma3 = iMA(_Symbol, timeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   int trend1 = ma1 > ma2 ? 1 : (ma1 < ma2 ? -1 : 0);
   int trend2 = ma2 > ma3 ? 1 : (ma2 < ma3 ? -1 : 0);
   
   if(trend1 > 0 && trend2 > 0){ // uptrend
      double lowerBB = iBands(_Symbol, timeframe, period, deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
      double ma = iMA(_Symbol, timeframe, period, 0, MODE_EMA, PRICE_CLOSE, 0);
      
      if(Ask <= lowerBB) AlertChannels("Strong BUY", PERIOD_M5, "Scalp lowerBB");
      else if(Ask <= ma) AlertChannels("BUY", PERIOD_M5, "Scalp Mid zone");
   }
   
   if(trend1 < 0 && trend2 < 0){ // downtrend
      double upperBB = iBands(_Symbol, timeframe, period, deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
      double ma = iMA(_Symbol, timeframe, period, 0, MODE_EMA, PRICE_CLOSE, 0);
      
      if(Bid >= upperBB) AlertChannels("Strong SELL", PERIOD_M5, "Scalp upperBB");
      else if(Bid >= ma) AlertChannels("SELL", PERIOD_M5, "Scalp Mid zone");
   }
}

void dayTradingStrategy(){

}

void OnTick()
{
   // STRATEGY #1
   int bollingerBandsSignal = bollingerBandsStrategy(2.5);
   int RSIStrategySignal = RSIStrategy();

   if(bollingerBandsSignal < 0 && RSIStrategySignal < 0)
      AlertChannels("Strong SELL", _Period, "RSI+BB");
   else if(bollingerBandsSignal < 0)
      AlertChannels("SELL", _Period, "BB");

   if(bollingerBandsSignal > 0 && RSIStrategySignal > 0)
      AlertChannels("String BUY", _Period, "RSI+BB");
   else if(bollingerBandsSignal > 0)
      AlertChannels("BUY", _Period, "BB");
  
   
   // STRATEGY #2
   int advancedBollingerBandsStrategySignal = advancedBollingerBandsStrategy(2);
   if (advancedBollingerBandsStrategySignal > 0)
      AlertChannels("BUY", _Period, "AdvancedBB");
    
   if (advancedBollingerBandsStrategySignal < 0)
      AlertChannels("SELL", _Period, "AdvancedBB");
   
   // Strategy #3 - Scalping
   bool to_scalp = isCurrentSymbol("EURUSD") || isCurrentSymbol("XAUUSD") || isCurrentSymbol("GBPUSD") || isCurrentSymbol("USDJPY");
   if(to_scalp)
      scalpingStrategy(PERIOD_M5);
   
   // Strategy #4 - Day Trading
   dayTradingStrategy();
}