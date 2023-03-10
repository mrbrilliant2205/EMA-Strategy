//+------------------------------------------------------------------+
//|                                                 22122022_RSI.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
#include <Trade\AccountInfo.mqh>
CTrade trade;
CAccountInfo AccInfo;
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
// Volume
input int               Stoploss_Point       = 30;
int                     Sl;
input double            risk                 = 0.01;
input double            PnL_ratio            = 2;
//input bool	            bool_TrailingStop    =  false;			//  Su_Dung_TraiLing_Cho_Lenh_1
//int                     PointPass;				                  // Point_Bat_Dau_Trailing
//int                     PointTrailing;				               // Point_Trailing
//int               PointStep            =  30;            // Point_Nhay
input double            Ratio_to_breakeven   =  1.5;           // Khi giá chạy được gấp bao nhiêu lần Stoploss thì rời hòa               
//Discount - Premium
input int               DP                   = 50;             // Bao nhieu nen phia truoc
// EMA
input int               PeriodMAFast         = 34;
input ENUM_MA_METHOD    ModeMA_1             = MODE_EMA;
input int               PeriodMASlow         = 89;
input ENUM_MA_METHOD    ModeMA_2             = MODE_EMA;
double                  Ask, Bid;
int                     getMA_1, getMA_2;
double                  arrayMA_1[], arrayMA_2[];
double                  MA_1_1, MA_1_2, MA_2_1, MA_2_2, diff_MA_1, diff_MA_2;
double                  nen;
int                     xuhuong;
void OnTick()
{
//---
     Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

            
//2 MA
   //  Chuẩn bị
    getMA_1   = iMA(_Symbol,_Period,PeriodMAFast,0,ModeMA_1,PRICE_CLOSE);
    getMA_2   = iMA(_Symbol,_Period,PeriodMASlow,0,ModeMA_2,PRICE_CLOSE);
    ArraySetAsSeries(arrayMA_1,true);
    ArraySetAsSeries(arrayMA_2,true);
    CopyBuffer(getMA_1,0,0,3,arrayMA_1);
    CopyBuffer(getMA_2,0,0,3,arrayMA_2); 
   //  lấy giá trị
    MA_1_1 = NormalizeDouble(arrayMA_1[1],_Digits);
    MA_1_2 = NormalizeDouble(arrayMA_1[2],_Digits);
    MA_2_1 = NormalizeDouble(arrayMA_2[1],_Digits);
    MA_2_2 = NormalizeDouble(arrayMA_2[2],_Digits);
    diff_MA_1 = MathAbs(MA_1_1 - MA_2_1);
    diff_MA_2 = MathAbs(MA_1_2 - MA_2_2);
  if (PositionsTotal() > 1) {return;}
     //AccInfo.LimitOrders() <5;
   // xu huong
   if(MA_1_1 > MA_2_1 && MA_1_2 < MA_2_2) 
         xuhuong = 1; // xu hướng tăng bắt đầu
   if(MA_1_1 < MA_2_1 && MA_1_2 > MA_2_2) 
         xuhuong = 0; // xu hướng giảm bắt đầu       
     
          
   //-- lệnh buy
    
    if(CountOrders("OB_BUY") < 2
    && CheckColorCandle(_Symbol,Period(),1) == "BLUE"
    && CheckColorCandle(_Symbol,Period(),2) == "RED"
    && CheckColorCandle(_Symbol,Period(),3) == "RED"
    && CheckColorCandle(_Symbol,Period(),4) == "RED"
    && CheckColorCandle(_Symbol,Period(),5) == "RED"
    && Checkpinbar(_Symbol,Period(),1) == "Up"
    //&& dis_pre(_Symbol,Period(),DP,1) == "DISCOUNT"
    )
    {
           //if(iRSI(_Symbol,PERIOD_M1,8,PRICE_CLOSE) < 28)
           //&& iRSI(Symbol(),PERIOD_M15,8,PRICE_CLOSE) > 50
           if(MA_1_1 > MA_2_1
           && iClose(_Symbol,PERIOD_CURRENT,1) > MA_1_1
           )
           {
                Sl = (Ask - lowest_price(_Symbol,PERIOD_CURRENT,3))/Point() + Stoploss_Point;
                
                //Tính khối lượng
                double lot = 5000*risk/(Sl*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE));
                double Lotsize = NormalizeDouble(lot,2);
                trade.Buy(Lotsize,_Symbol,Ask,lowest_price(_Symbol,PERIOD_CURRENT,3)-Stoploss_Point*Point(),Ask + Sl*PnL_ratio*Point());
                
           }    
    }
       
   //-- lệnh sell
    
    if(CountOrders("OB_SELL") < 2
    && CheckColorCandle(_Symbol,Period(),1) == "RED"
    && CheckColorCandle(_Symbol,Period(),2) == "BLUE"
    && CheckColorCandle(_Symbol,Period(),3) == "BLUE"
    && CheckColorCandle(_Symbol,Period(),4) == "BLUE"
    && CheckColorCandle(_Symbol,Period(),5) == "BLUE"
    && Checkpinbar(_Symbol,Period(),1) == "Down"
   // && dis_pre(_Symbol,Period(),DP,1) == "PREMIUM"
    )
    { 
          //if(iRSI(_Symbol,PERIOD_M1,8,PRICE_CLOSE) > 72)
          //&& iRSI(Symbol(),PERIOD_M15,8,PRICE_CLOSE) < 45
          if(MA_1_1 < MA_2_1
          && iClose(_Symbol,PERIOD_CURRENT,1) < MA_1_1
          )
          {
               Sl = (highest_price(_Symbol,PERIOD_CURRENT,3) - Bid)/Point() + Stoploss_Point;
               
               //Tính khối lượng
                double lot = 5000*risk/(Sl*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE));
                double Lotsize = NormalizeDouble(lot,2);
                trade.Sell(Lotsize,_Symbol,Bid,highest_price(_Symbol,PERIOD_CURRENT,3)+Stoploss_Point*Point(),Bid - Sl*PnL_ratio*Point());
                
          }             
    }
//Trailingstop
    //if(PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN) > Ratio_to_breakeven*Sl*Point()
    //)
    //{
    //     trade.PositionModify(_Symbol,PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_TP));
    //     //TrailingStopbyPoint(PointPass,PointTrailing,ceil(Ratio_to_breakeven*PointStep));
    //}
    //if(PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_PRICE_CURRENT) > Ratio_to_breakeven*Sl*Point()
    //)
    //{
    //     trade.PositionModify(_Symbol,PositionGetDouble(POSITION_PRICE_OPEN),PositionGetDouble(POSITION_TP));
    //     //TrailingStopbyPoint(PointPass,PointTrailing,ceil(Ratio_to_breakeven*PointStep));
    //}
    
    
}
//+------------------------------------------------------------------+
//Đếm lệnh
int CountOrders(string type)
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ENUM_POINTER_TYPE PositionType = ENUM_POINTER_TYPE(PositionGetInteger(POSITION_TYPE));
      ulong PositionTicket = PositionGetTicket(i);
      {
         string _symbol = PositionGetString(POSITION_SYMBOL);
         if(_symbol == _Symbol)
         {
            if(type == "All")
            count ++;
            if(type == "OP_BUY" && PositionType == 0)
            count ++;            
            if(type == "OP_SELL" && PositionType == 1)
            count ++; 
            if(type == "OP_BUYLIMIT" && PositionType == 2)
            count ++;            
            if(type == "OP_SELLLIMIT" && PositionType == 3)
            count ++;
            if(type == "OP_BUYSTOLP" && PositionType == 4)
            count ++;            
            if(type == "OP_SELLSTOP" && PositionType == 5)
            count ++;           
            if(type == "OP_SELL_OP_BUY" && PositionType > -1 && PositionType < 2)
            count ++;  
         }
         if(type =="AllAllAll")
         count ++;                  
      }
   }
   return count;
}
//+------------------------------------------------------------------+
// Kiểm tra màu nến
string CheckColorCandle(string symbol, ENUM_TIMEFRAMES timeframe, int shift) 
{
   string ColorCandle = "";
   if(iOpen(symbol,timeframe,shift) <= iClose(symbol,timeframe,shift))
      ColorCandle = "BLUE";
   else ColorCandle = "RED";
   return ColorCandle;
}
// Kiểm tra nến cuối
string Checkpinbar(string symbol, ENUM_TIMEFRAMES timeframe, int shift) 
{
   string check = ""; 
   //nến xanh
   if(iOpen(symbol,timeframe,shift) <= iClose(symbol,timeframe,shift))
   {
      if((iClose(symbol,timeframe,shift) - iOpen(symbol,timeframe,shift)) > 0.3*(iHigh(symbol,timeframe,shift) - iLow(symbol,timeframe,shift)))
      {
         if((iOpen(symbol,timeframe,shift) - iLow(symbol,timeframe,shift)) > (iHigh(symbol,timeframe,shift) - iClose(symbol,timeframe,shift))
         || (iClose(symbol,timeframe,shift) - iOpen(symbol,timeframe,shift)) > 0.4*(iHigh(symbol,timeframe,shift) - iLow(symbol,timeframe,shift)))
      
         check = "Up";
      }
   }
   //nến đỏ
   if(iOpen(symbol,timeframe,shift) >= iClose(symbol,timeframe,shift))
   {
       if((iOpen(symbol,timeframe,shift) - iClose(symbol,timeframe,shift)) > 0.3*(iHigh(symbol,timeframe,shift) - iLow(symbol,timeframe,shift)))  
         if((iHigh(symbol,timeframe,shift) - iClose(symbol,timeframe,shift)) > (iOpen(symbol,timeframe,shift) - iLow(symbol,timeframe,shift))
         || (iOpen(symbol,timeframe,shift) - iClose(symbol,timeframe,shift)) > 0.4*(iHigh(symbol,timeframe,shift) - iLow(symbol,timeframe,shift)))
            check = "Down";
   }
   return check;
}
//Dat stoploss buy
double lowest_price(string symbol, ENUM_TIMEFRAMES timeframe, int sonen)
{
   double lp = iLow(symbol,timeframe,0);
   for (int i = 0; i<=sonen; i++)
   {
      if(iLow(symbol,timeframe,i) < lp)
         {
            lp = iLow(symbol,timeframe,i);
         }
   }
   return lp;
}
//Dat stoploss sell
double highest_price(string symbol, ENUM_TIMEFRAMES timeframe, int sonen)
{
   double lp = iHigh(symbol,timeframe,0);
   for (int i = 0; i<=sonen; i++)
   {
      if(iHigh(symbol,timeframe,i) > lp)
         {
            lp = iHigh(symbol,timeframe,i);
         }
   }
   return lp;
}
string dis_pre(string symbol, ENUM_TIMEFRAMES tf, int sonen, int shift)
{
   string discount_premium = "";
   if(iClose(symbol,tf,1) > (iHighest(symbol,tf,MODE_HIGH,sonen,shift) + iLowest(symbol,tf,MODE_LOW,sonen,shift))/2)
   {
      discount_premium = "PREMIUM";
   } 
   if(iClose(symbol,tf,1) < (iHighest(symbol,tf,MODE_HIGH,sonen,shift) + iLowest(symbol,tf,MODE_LOW,sonen,shift))/2)
   {
      discount_premium = "DISCOUNT";
   }
   return discount_premium; 
}

// TrailingStop
//void TrailingStopbyPoint(int PointStart,int Pointtrailing)//, int Point_Step)
//  {
//   uint total=PositionsTotal();
//   for(uint i=0; i < total; i++)
//     {
//      string position_symbol=PositionGetSymbol(POSITION_SYMBOL);
//      ulong Position_Ticket    = PositionGetTicket(i);
//      ENUM_POSITION_TYPE PositionType = ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE));
//        {
//         if(position_symbol == _Symbol)
//         {
//            if(PositionType == POSITION_TYPE_SELL)
//              {
//                  double Create_sl = PositionGetDouble(POSITION_PRICE_OPEN)+PointStart*_Point;
//                  if(PositionGetDouble (POSITION_SL)== 0)
//                     {trade.PositionModify(Position_Ticket,Create_sl,PositionGetDouble (POSITION_TP));}
//                  if(SymbolInfoDouble(_Symbol,SYMBOL_BID) < PositionGetDouble (POSITION_PRICE_OPEN) - PointStart *_Point 
//                  )
//                     {trade.PositionModify(Position_Ticket,PositionGetDouble (POSITION_PRICE_OPEN) - Pointtrailing *_Point,PositionGetDouble (POSITION_TP));}
//              }
//            if(PositionType == POSITION_TYPE_BUY)
//              {
//                  double Create_sl = PositionGetDouble(POSITION_PRICE_OPEN)-PointStart*_Point;
//                  if(PositionGetDouble (POSITION_SL)== 0)
//                     {trade.PositionModify(Position_Ticket,Create_sl,PositionGetDouble (POSITION_TP));}
//                  if(SymbolInfoDouble(_Symbol,SYMBOL_ASK) > PositionGetDouble (POSITION_PRICE_OPEN) + PointStart *_Point 
//                  )
//                     {trade.PositionModify(Position_Ticket,PositionGetDouble (POSITION_PRICE_OPEN) + Pointtrailing *_Point,PositionGetDouble (POSITION_TP));}
//              }
//           }
//
//        }
//     }
//  }

  