program GNS;

{$APPTYPE CONSOLE}

uses
  FastMM4,
  SysUtils,
  Classes,
  Windows,
  System,
  Forms,
  Dialogs,
  Console,
  DateUtils,
  Graphics,
  ActiveX,
  Variables in 'Variables.pas',
  GNSClasses in 'GNSClasses.pas',
  ChartsFrm in 'ChartsFrm.pas' {ChartsForm};

const
  P_PREFIX  = '/';
  A_PREFIX  = '-';

  A_WALLET  = 'w';
  AF_WALLET = 'wallet';
  A_TIP     = 't';
  AF_TIP    = 'tip';
  A_HOURS   = 'h';
  AF_HOURS  = 'hours';
  A_PAUSE   = 'p';
  AF_PAUSE  = 'pause';
  A_DATE    = 'd';
  AF_DATE   = 'date';
  AF_WEEKS  = 'weeks';
  AF_MONTHS = 'months';
  AF_DAYS = 'days';

  P_STATS   = 's';
  PF_STATS  = 'stats';
  P_ADD     = 'a';
  PF_ADD    = 'add';
  P_EXPENSE = 'e';
  PF_EXPENSE = 'expense';
  P_PROGNOSIS = 'p';
  PF_PROGNOSIS = 'prognosis';
  P_SALARY = 'w';
  PF_SALARY = 'wages';
  P_DEBT = 'd';
  PF_DEBT = 'debt';
  P_FINANCE = 'f';
  PF_FINANCE = 'finance';
  P_CHARTS = 'c';
  PF_CHARTS = 'charts';
  PF_HELP = 'help';
  P_HELP = 'h';

  MSG_HELP = '/stats     - viewes stats, options: days, weeks, months'#13#10+
             '/add       - adds a work day to the DB. Attributes:'#13#10+
             '             -h - hours: from, to'#13#10+
             '             -w - money count in your wallet'#13#10+
             '             -t - tips from yesterday'#13#10+
             '             Optional attributes:'#13#10+
             '             -p - pause time in minutes'#13#10+
             '             -d - date of the work day, if not from today'+#13#10+
             '             Examples:'#13#10+
             '             /add -h 10:00 17:30 -p 0 -d 13.03 -w 999 -t 99'#13#10+
             '             /add -h 17:00 22:00 -w 999 -t 99'#13#10+
             '/expense     - viewes expenses list. Attributes:'#13#10+
             '             Expense_name Expense_cost'#13#10+
             '/prognosis - views prognosis of the season'#13#10+
             '/finance   - views finance informations'#13#10+
             '/charts    - views work days charts';

  E_SYNTAX = 'Syntax error!';

{
 gns /add -w 1500 -t 150 [-t 22.03 150] -h 11:30 23:00 -p 30 [min] -d 22.03
 gns /stats
 gns /stats 13.03
 gns /stats 13.03 31.03
 gns /expense Phone 300
 gns /prognosis
 gns /wages 1300
 gns /wages
}

type
  TStatsMode = (Full, Day, FromTo, Weeks, Months, Days);

var
  Wallet: Integer=0;
  Tip: Integer=0;
  Pause: Integer=30;
  DayHours: TDayHours;
  Expense: TEDBItem;
  Date: TDateEx;
  DB: TDataBase;
  IDFrom,
  IDTo: Integer;
  StatsMode: TStatsMode;
  WagesCount: Integer=0;
  Debt: Integer = 0;
  DebtName: String;

function IArguments: String;
begin
  Result:='';
  if(Wallet=0)then
    Result:=Result+AF_WALLET+', ';
  if(Tip=0)then
    Result:=Result+AF_TIP+', ';
  if not(DayHours.Assigned)then
    Result:=Result+AF_HOURS+', ';
  Delete(Result, Length(Result)-1, Length(Result));
end;

function DateGenerate: TDateTime;
begin
  if(HourOf(Now)in[0..8])then
    Result:=IncDay(Now, -1)
  else
    Result:=Now;
end;

procedure AddDay;
const
  CONFIRM_MSG = 'Date:'#$9#$9' %s'#13#10+
                'Hours:'#$9#$9' %s to %s'#13#10+
                'Wallet:'#$9#$9' %s'#13#10+
                'Tip:'#$9#$9' %s'#13#10+
                'Pause:'#$9#$9' %smin';
 CONFIRM =      #13#10#13#10'Do you confirm? (y/n): ';
var
  S: String;
begin
  if(Wallet>0)and(Tip>0)and(DayHours.Assigned)then begin
    if not(Date.Assigned)then begin
      Date.Date:=DateGenerate;
      Date.Assigned:=True;
    end;
    if not(DB.CheckDay(Date.Date))then begin
      TextColor(LightRed);
      WriteLn('[ERROR] This day (',DateToStr(Date.Date),') is already in DB!');
      TextColor(White);
      Exit;
    end;
    repeat

      TextColor(LightBlue);
      Write(#13#10, Format(CONFIRM_MSG,[DateToStr(Date.Date), TimeToStr(DayHours.From),
                                        TimeToStr(DayHours.Too), IntToStr(Wallet),
                                        IntToStr(Tip), IntToStr(Pause)]));
      TextColor(LightRed);
      Write(CONFIRM);
      //TextColor(White);
      ReadLn(S);
    until(S='y') or (S='n');
    if(S='n')then
      Exit;
    DB.AddDay(Wallet, Tip, DayHours, Pause, Date.Date);
    //DB.SortDBDays;
    DB.AssignTip;
    DB.SaveToFile;
  end else begin
    TextColor(LightRed);
    WriteLn('[ERROR] Insufficient arguments: ', IArguments);
    TextColor(White);
  end;
end;

function ColorGenerate: Integer;
const
  COLORS: array[0..7] of Integer =
  (8, 9, 10, 11, 1, 14, 15, 7);
var
  I: Integer;
begin
  repeat
    I:=Random(8);
  until(I in[0..7]);
  Result:=COLORS[I];
end;

procedure FullStats;
var
  Color, Month, Count: Integer;
  Date: TDateTime;
begin
  Color:=ColorGenerate;
  with DB.Stats do begin

    TextColor(Color);
    WriteLn(#13#10#1' WORK TIME '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    Count:=WorkTimeMinutes;
    WriteLn('Count: '#$9#$9, DaysCount, ' days');
    WriteLn('Hours: '#$9#$9, (Count div 60), 'h ', (Count mod 60),'min');
    WriteLn('Pause: '#$9#$9, (PauseTime div 60),'h ', (PauseTime mod 60),'min');
    WriteLn('Average: '#$9,(Count div DaysCount) div 60, 'h ', (Count div DaysCount) mod 60,'min');
    Date:=LongestDay(Count);
    WriteLn('Longest: '#$9, (Count div 60), 'h ', (Count mod 60),'min ', '(', FormatDateTime('DD.MM', Date), ')');
    Date:=ShortestDay(Count);
    WriteLn('Shortest:'#$9, (Count div 60), 'h ', (Count mod 60),'min ', '  (', FormatDateTime('DD.MM', Date), ')');

    TextColor(Color);
    WriteLn(#13#10#1' PAYMENT '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count:'#$9#$9, PaymentCount, ' euro');
    WriteLn('Income:'#$9#$9, (PaymentCount/(WorkTimeMinutes(GetFirstDayID, GetLastDayIDofMonth(MonthOf(Now)-1)) div 60)):0:2, ' E/H');
    WriteLn('Average:'#$9, (PaymentCount/PaymentMonths):0:2, ' euro');
    Month:=PaymentBest(Count);
    WriteLn('Best:'#$9#$9, Count, ' euro (', ShortMonthNames[Month],')');
    Month:=PaymentLeast(Count);
    WriteLn('Least:'#$9#$9, Count, ' euro (', ShortMonthNames[Month],')');

    TextColor(Color);
    WriteLn(#13#10#1' TIP '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    Count:=TipsCount;
    TextColor(White);
    WriteLn('Count: '#$9#$9, TipsCount, ' euro');
    WriteLn('Income: '#$9, (Count/(WorkTimeMinutes div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (TipsCount/DaysCount):0:2, ' euro');
    Date:=BestTip(Count);
    WriteLn('Best: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastTip(Count);
    WriteLn('Least: '#$9#$9, Count, ' euro    (', FormatDateTime('DD.MM', Date),')');

    TextColor(Color);
    WriteLn(#13#10#1' WALLET '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count: '#$9#$9, WalletCount, ' euro');
    WriteLn('Income: '#$9, (WalletCount/(WorkTimeMinutes div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (WalletCount/DaysCount):0:2, ' euro');
    Date:=BestWallet(Count);
    WriteLn('Best: '#$9#$9, Count, ' euro (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastWallet(Count);
    WriteLn('Least: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
  end;
end;

procedure WriteFeed(S: String; Color: Integer);
const
  W = 30;
  C = #1;
begin
  S:=#1+' '+S+' '+StringOfChar(C, W-Length(S));
  TextColor(Color);
  WriteLn(S);
end;

procedure DayStats;
begin
  with DB.Stats do begin
    TextColor(LightGreen);
    WriteLn(#13#10#1' WORK TIME '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Hours: '#$9#$9, (WorkTimeMinutes(IDFrom, IDTo) div 60), 'h ', (WorkTimeMinutes(IDFrom, IDTo) mod 60),'min');
    WriteLn('Pause: '#$9#$9, (PauseTime(IDFrom, IDTo) div 60),'h ', (PauseTime(IDFrom, IDTo) mod 60),'min');
    TextColor(LightBlue);
    WriteLn(#13#10#1' TIP '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count: '#$9#$9, TipsCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (TipsCount(IDFrom, IDTo)/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
    TextColor(Yellow);
    WriteLn(#13#10#1' WALLET '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count: '#$9#$9, WalletCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (WalletCount(IDFrom, IDTo)/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
  end;
end;

procedure FromToStats;
var
  Color, Count: Integer;
  Date: TDateTime;
begin
  Color:=ColorGenerate;
  with DB.Stats do begin

    TextColor(Color);
    WriteLn(#13#10#1' WORK TIME '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    Count:=WorkTimeMinutes(IDFrom, IDTo);
    WriteLn('Count: '#$9#$9, DaysCount(IDFrom, IDTo), ' days');
    WriteLn('Hours: '#$9#$9, (Count div 60), 'h ', (Count mod 60),'min');
    WriteLn('Pause: '#$9#$9, (PauseTime div 60),'h ', (PauseTime(IDFrom, IDTo) mod 60),'min');
    WriteLn('Average: '#$9,(Count div DaysCount(IDFrom, IDTo)) div 60, 'h ', (Count div DaysCount(IDFrom, IDTo)) mod 60,'min');
    Date:=LongestDay(IDFrom, IDTo, Count);
    WriteLn('Longest: '#$9, (Count div 60), 'h ', (Count mod 60),'min ', '(', FormatDateTime('DD.MM', Date), ')');
    Date:=ShortestDay(IDFrom, IDTo, Count);
    WriteLn('Shortest:'#$9, (Count div 60), 'h ', (Count mod 60),'min ', '  (', FormatDateTime('DD.MM', Date), ')');

    TextColor(Color);
    WriteLn(#13#10#1' TIP '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    Count:=TipsCount(IDFrom, IDTo);
    TextColor(White);
    WriteLn('Count: '#$9#$9, TipsCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (Count/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (TipsCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
    Date:=BestTip(IDFrom, IDTo, Count);
    WriteLn('Best: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastTip(IDFrom, IDTo, Count);
    WriteLn('Least: '#$9#$9, Count, ' euro    (', FormatDateTime('DD.MM', Date),')');

    TextColor(Color);
    WriteLn(#13#10#1' WALLET '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count: '#$9#$9, WalletCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (WalletCount(IDFrom, IDTo)/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (WalletCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
    Date:=BestWallet(IDFrom, IDTo, Count);
    WriteLn('Best: '#$9#$9, Count, ' euro (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastWallet(IDFrom, IDTo, Count);
    WriteLn('Least: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
  end;
end;

procedure WeeksStats;
type
  TBestWeek = record
    From,
    Too,
    Count: Integer;
  end;
var
  Color, Col2, Count: Integer;
  StartI, I: Integer;
  Date: TDateTime;
  BestWeek: TBestWeek;
begin
  Color:=LightBlue;
  Col2:=LightGray;
  BestWeek.Count:=0;
  I:=0;
  repeat
    StartI:=I;
    repeat
      if(I>=DB.DaysList.Count-1)then
        Break;
      Inc(I);
    until(DayOfWeek(PDDBItem(DB.DaysList.Items[I])^.Date.Date)=1);
    if(I>=DB.DaysList.Count)and(StartI=I)then
      Break;
    IDFrom:=PDDBItem(DB.DaysList.Items[StartI])^.ID;
    IDTo:=PDDBItem(DB.DaysList.Items[I])^.ID;
    WriteLn;
    WriteFeed(FormatDateTime('DD.MM', PDDBItem(DB.DaysList.Items[StartI])^.Date.Date)+' - '+
              FormatDateTime('DD.MM', PDDBItem(DB.DaysList.Items[I])^.Date.Date), Color);
    with DB.Stats do begin
      TextColor(Col2);
      WriteLn(#1' WORK TIME '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
      TextColor(White);
      Count:=WorkTimeMinutes(IDFrom, IDTo);
      WriteLn('Hours: '#$9#$9, (Count div 60), 'h ', (Count mod 60),'min');
      WriteLn('Pause: '#$9#$9, (PauseTime div 60),'h ', (PauseTime(IDFrom, IDTo) mod 60),'min');
      WriteLn('Average: '#$9,(Count div DaysCount(IDFrom, IDTo)) div 60, 'h ', (Count div DaysCount(IDFrom, IDTo)) mod 60,'min');
      Date:=LongestDay(IDFrom, IDTo, Count);
      WriteLn('Longest: '#$9, (Count div 60), 'h ', (Count mod 60),'min ', '(', FormatDateTime('DD.MM', Date), ')');
      Date:=ShortestDay(IDFrom, IDTo, Count);
      WriteLn('Shortest:'#$9, (Count div 60), 'h ', (Count mod 60),'min ', '  (', FormatDateTime('DD.MM', Date), ')');

      TextColor(Col2);
      WriteLn(#1' TIP '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
      Count:=TipsCount(IDFrom, IDTo);
      if(Count>BestWeek.Count)then begin
        BestWeek.From:=IDFrom;
        BestWeek.Too:=IDTo;
        BestWeek.Count:=Count;
      end;
      TextColor(White);
      WriteLn('Count: '#$9#$9, TipsCount(IDFrom, IDTo), ' euro');
      WriteLn('Income: '#$9, (Count/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
      WriteLn('Average: '#$9, (TipsCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
      Date:=BestTip(IDFrom, IDTo, Count);
      WriteLn('Best: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
      Date:=LeastTip(IDFrom, IDTo, Count);
      WriteLn('Least: '#$9#$9, Count, ' euro    (', FormatDateTime('DD.MM', Date),')');

      TextColor(Col2);
      WriteLn(#1' WALLET '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
      TextColor(White);
      WriteLn('Count: '#$9#$9, WalletCount(IDFrom, IDTo), ' euro');
      WriteLn('Income: '#$9, (WalletCount(IDFrom, IDTo)/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
      WriteLn('Average: '#$9, (WalletCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
      Date:=BestWallet(IDFrom, IDTo, Count);
      WriteLn('Best: '#$9#$9, Count, ' euro (', FormatDateTime('DD.MM', Date),')');
      Date:=LeastWallet(IDFrom, IDTo, Count);
      WriteLn('Least: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
    end;
  until(I>=DB.DaysList.Count-1);
  IDFrom:=BestWeek.From;
  IDTo:=BestWeek.Too;
  WriteLn;
  WriteFeed('BEST WEEK: '+FormatDateTime('DD.MM', PDDBItem(DB.DaysList.Items[DB.FindID(IDFrom)])^.Date.Date)+' - '+
            FormatDateTime('DD.MM', PDDBItem(DB.DaysList.Items[DB.FindID(IDTo)])^.Date.Date), Color);
  with DB.Stats do begin
    TextColor(Col2);
    WriteLn(#1' WORK TIME '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    Count:=WorkTimeMinutes(IDFrom, IDTo);
    WriteLn('Hours: '#$9#$9, (Count div 60), 'h ', (Count mod 60),'min');
    WriteLn('Pause: '#$9#$9, (PauseTime div 60),'h ', (PauseTime(IDFrom, IDTo) mod 60),'min');
    WriteLn('Average: '#$9,(Count div DaysCount(IDFrom, IDTo)) div 60, 'h ', (Count div DaysCount(IDFrom, IDTo)) mod 60,'min');
    Date:=LongestDay(IDFrom, IDTo, Count);
    WriteLn('Longest: '#$9, (Count div 60), 'h ', (Count mod 60),'min ', '(', FormatDateTime('DD.MM', Date), ')');
    Date:=ShortestDay(IDFrom, IDTo, Count);
    WriteLn('Shortest:'#$9, (Count div 60), 'h ', (Count mod 60),'min ', '  (', FormatDateTime('DD.MM', Date), ')');

    TextColor(Col2);
    WriteLn(#1' TIP '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    Count:=TipsCount(IDFrom, IDTo);
    if(Count>BestWeek.Count)then begin
      BestWeek.From:=IDFrom;
      BestWeek.Too:=IDTo;
      BestWeek.Count:=Count;
    end;
    TextColor(White);
    WriteLn('Count: '#$9#$9, TipsCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (Count/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (TipsCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
    Date:=BestTip(IDFrom, IDTo, Count);
    WriteLn('Best: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastTip(IDFrom, IDTo, Count);
    WriteLn('Least: '#$9#$9, Count, ' euro    (', FormatDateTime('DD.MM', Date),')');

    TextColor(Col2);
    WriteLn(#1' WALLET '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    WriteLn('Count: '#$9#$9, WalletCount(IDFrom, IDTo), ' euro');
    WriteLn('Income: '#$9, (WalletCount(IDFrom, IDTo)/(WorkTimeMinutes(IDFrom, IDTo) div 60)):0:2, ' E/H');
    WriteLn('Average: '#$9, (WalletCount(IDFrom, IDTo)/DaysCount(IDFrom, IDTo)):0:2, ' euro');
    Date:=BestWallet(IDFrom, IDTo, Count);
    WriteLn('Best: '#$9#$9, Count, ' euro (', FormatDateTime('DD.MM', Date),')');
    Date:=LeastWallet(IDFrom, IDTo, Count);
    WriteLn('Least: '#$9#$9, Count, ' euro  (', FormatDateTime('DD.MM', Date),')');
  end;
end;

procedure MonthStats;
begin

end;

procedure DaysStats;
var
  DayID: Integer;
  Color: Integer;
  I: Integer;
begin
  Color:=ColorGenerate;
  for I:=0 to DB.DaysList.Count-1 do
    with DB.Stats do
      with PDDBItem(DB.DaysList[I])^ do begin
        DayID:=ID;
        WriteLn;
        WriteFeed(FormatDateTime('DD.MM', Date.Date), Color);
        TextColor(White);
        WriteLn('Hours: '#$9#$9, (WorkTimeMinutes(DayID, DayID) div 60), 'h ', (WorkTimeMinutes(DayID, DayID) mod 60),'min');
        WriteLn('Pause: '#$9#$9, (PauseTime(DayID, DayID) div 60),'h ', (PauseTime(DayID, DayID) mod 60),'min');
        WriteLn('Tip: '#$9#$9, TipsCount(DayID, DayID), ' euro');
        WriteLn('Tip income: '#$9, (TipsCount(DayID, DayID)/(WorkTimeMinutes(DayID, DayID) div 60)):0:2, ' E/H');
        WriteLn('Wallet: '#$9, WalletCount(DayID, DayID), ' euro');
        WriteLn('Wallet income: '#$9, (WalletCount(DayID, DayID)/(WorkTimeMinutes(DayID, DayID) div 60)):0:2, ' E/H');
      end;
end;

procedure Stats;
begin
  case(StatsMode)of
    Full: FullStats;
    Day: DayStats;
    FromTo: FromToStats;
    Weeks: WeeksStats;
    Months: MonthStats;
    Days: DaysStats;
  end;
end;

procedure Expenses;
var
  I, Color: Integer;
  S: String;
begin
  if(Expense.Value>0)then
    repeat
      TextColor(LightBlue);
      WriteLn(#13#10'Value: ', Expense.Value);
      WriteLn('Description: ', Expense.Description);
      WriteLn('Date: ', FormatDateTime('DD.MM', Expense.Date));
      TextColor(LightRed);
      Write(#13#10'Do you confirm? (y/n): ');
      ReadLn(S);
      if(Length(S)>0)then
        if(S='y')then begin
          DB.AddExpense(Expense);
          DB.SaveToFile;
          Break;
        end else
          if(S='n')then
            Break;
    until(False)
  else begin
    if(DB.ExpensesList.Count>0)then begin
      Color:=ColorGenerate;
      TextColor(Color);
      WriteLn(#13#10#1' EXPENSES '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
      TextColor(White);
      WriteLn('Count:'#$9#$9, DB.Stats.ExpensesCount);
      TextColor(Color);
      Write(#13#10#1' LIST '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
      TextColor(White);
      for I:=0 to DB.ExpensesList.Count-1 do
        with PEDBItem(DB.ExpensesList.Items[I])^ do
          WriteLn(#13#10'Name: '#$9#$9, Description, #13#10,
                  'Cost:'#$9#$9, Value, ' euro', #13#10,
                  'Date:'#$9#$9, FormatDateTime('DD.MM', Date));

    end else begin
      TextColor(LightRed);
      WriteLn('[ERROR] Expenses list empty!');
    end;
  end;
end;

procedure UnknownParameter(I: Integer);
begin
  TextColor(LightRed);
  WriteLn('[ERROR] Unknown parameter: "', ParamStr(I), '"');
end;

procedure UnknownAttribute(Value: Boolean; S: String);
const
  S1 = '[ERROR] False attribute';
  S2 = ' value ';
begin
  TextColor(LightRed);
  if(Value)then
    WriteLn(S1, S2, S)
  else
    WriteLn(S1, ': ', S);
end;

procedure NoAttributeValue(S: String);
begin
  TextColor(LightRed);
  WriteLn('[ERROR] No attribute value for: ', S);
end;

procedure DoubleValue(From: String);
begin
  TextColor(LightRed);
  WriteLn('[ERROR] Double value for: ', From);
end;

procedure Prognosis;
begin
  TextColor(Yellow);
  WriteLn(#13#10#1' PROGNOSIS '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
  TextColor(White);
  WriteLn('Days left: '#$9, DB.Stats.PrognosisDaysLeft);
  WriteLn('Work days left: ', DB.Stats.PrognosisWorkDaysLeft);
  WriteLn('Tip income: '#$9, DB.Stats.PrognosisTip:0:2, ' euro');
  WriteLn('Work time: '#$9, DB.Stats.PrognosisWorkTimeLeft div 60, 'h');
  WriteLn('Wallet average: ', DB.Stats.PrognosisWalletAverage, ' euro');
end;

procedure Wages;
begin
  if(WagesCount>0)then begin
    DB.Payment.Add(MonthOf(Now)-1, WagesCount);
    DB.SaveToFile;
  end else begin

  end;
end;

procedure DebtHandle;
var
  I: Integer;
begin
  if(Debt<>0)then begin
    DB.Debt.Add(DebtName, Debt);
    DB.SaveToFile;
  end else begin
    if(Length(DB.Debt.Debts)=0)then
      Exit;
    TextColor(ColorGenerate);
    WriteLn(#13#10#1' DEBTS '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
    TextColor(White);
    with DB.Debt do
      for I:=0 to Length(Debts)-1 do begin
        WriteLn(Debts[I].Who, ': ', Debts[I].Mutch, ' euro');
      end;
  end;
end;

procedure Finance;
begin
  TextColor(ColorGenerate);
  WriteLn(#13#10#1' FINANCE '#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1#1);
  TextColor(White);
  WriteLn('Tip:'#$9#$9, DB.Stats.TipsCount, ' euro');
  WriteLn('Payment:'#$9, DB.Payment.GetAllCount, ' euro');
  WriteLn('Debts:'#$9#$9, DB.Debt.Count, ' euro');
  WriteLn('Expenses:'#$9, DB.Stats.ExpensesCount, ' euro');
  WriteLn('Count:'#$9#$9, DB.Stats.TipsCount+DB.Payment.GetAllCount, ' euro');
  WriteLn('Count-Expenses:'#$9, (DB.Stats.TipsCount+DB.Payment.GetAllCount)-DB.Stats.ExpensesCount, ' euro');
end;

procedure Charts;
var
  ChartsForm: TChartsForm;
begin
  ChartsForm:=TChartsForm.Create(nil);
  try
    ChartsForm.AddValues(DB.DaysList, DB.ExpensesList, DB.Payment);
    ChartsForm.ShowModal;
  finally
    ChartsForm.Free;
  end;
end;

procedure Help;
begin
  WriteLn(MSG_HELP);
end;

procedure PParser;
var
  I: Integer;
begin
  for I:=0 to ParamCount do
    if(Length(ParamStr(I))>=2)then
      if(ParamStr(I)[1]=P_PREFIX)then
        case Ord(AnsiLowerCase(ParamStr(I))[2]) of
          Ord(P_ADD): AddDay;
          Ord(P_STATS): Stats;
          Ord(P_EXPENSE): Expenses;
          Ord(P_PROGNOSIS): Prognosis;
          Ord(P_SALARY): Wages;
          Ord(P_DEBT): DebtHandle;
          Ord(P_FINANCE): Finance;
          Ord(P_CHARTS): Charts;
          Ord(P_HELP): Help;
          else begin
            UnknownParameter(I);
            Break;
          end;
        end;
end;

function AddAttributesCheck(var I:Integer): Boolean;
var
  FS: TFormatSettings;
begin
  Result:=True;
  repeat
    Inc(I);
    if(I>ParamCount)then
      Break;
    if not(ParamStr(I)[1]=A_PREFIX)then
      Break
    else
      case Ord(AnsiLowerCase(ParamStr(I))[2]) of
        Ord(A_WALLET): begin
                         Inc(I);
                         if(I>ParamCount)then begin
                           NoAttributeValue(AF_WALLET);
                           Result:=False;
                         end else
                           if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                             NoAttributeValue(AF_WALLET);
                             Result:=False;
                             Dec(I);
                           end else
                             if(Wallet=0)then
                               if not(TryStrToInt(ParamStr(I), Wallet))then begin
                                 Result:=False;
                                 UnknownAttribute(True, '['+AF_WALLET+']: '+ParamStr(I));
                               end else
                             else begin
                               Result:=False;
                               DoubleValue(AF_WALLET);
                             end;
                       end;
        Ord(A_TIP):    begin
                         Inc(I);
                         if(I>ParamCount)then begin
                           NoAttributeValue(AF_TIP);
                           Result:=False;
                         end else
                           if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                             NoAttributeValue(AF_TIP);
                             Result:=False;
                             Dec(I);
                           end else
                             if(Tip=0)then
                               if not(TryStrToInt(ParamStr(I), Tip))then begin
                                 Result:=False;
                                 UnknownAttribute(True, '['+AF_TIP+']: '+ParamStr(I));
                               end else
                             else begin
                               Result:=False;
                               DoubleValue(AF_TIP);
                             end;
                       end;
        Ord(A_PAUSE):  begin
                         Inc(I);
                         if(I>ParamCount)then begin
                           NoAttributeValue(AF_WALLET);
                           Result:=False;
                         end else
                           if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                             NoAttributeValue(AF_WALLET);
                             Result:=False;
                             Dec(I);
                           end else
                             if(Pause=30)then
                               if not(TryStrToInt(ParamStr(I), Pause))then begin
                                 Result:=False;
                                 UnknownAttribute(True, '['+AF_PAUSE+']: '+ParamStr(I));
                               end else
                             else begin
                               Result:=False;
                               DoubleValue(AF_PAUSE);
                             end;
                       end;
        Ord(A_HOURS):  begin
                         Inc(I);
                         if(I>ParamCount)then begin
                           NoAttributeValue(AF_HOURS);
                           Result:=False;
                         end else
                           if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                             NoAttributeValue(AF_HOURS);
                             Result:=False;
                             Dec(I);
                           end else
                             if not(DayHours.Assigned)then
                               if not(TryStrToDateTime(ParamStr(I), DayHours.From))then begin
                                 Result:=False;
                                 UnknownAttribute(True, '['+AF_HOURS+']: '+ParamStr(I))
                               end else begin
                                 Inc(I);
                                 if(I>ParamCount)then begin
                                   NoAttributeValue(AF_HOURS);
                                   Result:=False;
                                 end else
                                   if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                                     NoAttributeValue(AF_HOURS);
                                     Result:=False;
                                     Dec(I);
                                   end else
                                     if not(DayHours.Assigned)then
                                       if not(TryStrToDateTime(ParamStr(I), DayHours.Too))then begin
                                         Result:=False;
                                         UnknownAttribute(True, '['+AF_HOURS+']: '+ParamStr(I))
                                       end else
                                         DayHours.Assigned:=True
                                     else begin
                                       Result:=False;
                                       DoubleValue(AF_HOURS);
                                     end;
                             end else begin
                               Result:=False;
                               DoubleValue(AF_HOURS);
                             end;
                       end;
        Ord(A_DATE):   begin
                         Inc(I);
                         if(I>ParamCount)then begin
                           NoAttributeValue(AF_DATE);
                           Result:=False;
                         end else
                           if((ParamStr(I)[1]=P_PREFIX)or(ParamStr(I)[1]=A_PREFIX))then begin
                             NoAttributeValue(AF_DATE);
                             Result:=False;
                             Dec(I);
                           end else begin
                             FS.DateSeparator:='.';
                             FS.LongDateFormat:='dd.mm.yyyy';
                             FS.ShortDateFormat:='dd.mm';
                             if not(Date.Assigned)then
                               if not(TryStrToDate(ParamStr(I), Date.Date, FS))then begin
                                 Result:=False;
                                 UnknownAttribute(True, '['+AF_DATE+' (dd.mm.yyyy/dd.mm)]: '+ParamStr(I))
                               end else begin
                                 Date.Assigned:=True;
                                 //Dec(I);
                             end else begin
                               Result:=False;
                               DoubleValue(AF_DATE);
                             end;
                           end;
                       end;
      end;
  until(I-1>=ParamCount);
  Dec(I);
end;

function SalaryAttributesCheck(var I: Integer): Boolean;
var
  StatsParams, Rem: Integer;
begin
  Result:=True;
  StatsParams:=0;
  Rem:=I+1;
  repeat
    Inc(I);
    if(Length(ParamStr(I))>0)then
      if(ParamStr(I)[1]=P_PREFIX)then begin
        Dec(I);
        Break
      end else
        Inc(StatsParams)
    else
      Break;
  until(I>=ParamCount);
  if(StatsParams=1)then begin
    if not(TryStrToInt(ParamStr(Rem), WagesCount))then begin
      Result:=False;
      UnknownAttribute(True, '['+PF_SALARY+']: '+ParamStr(I));
    end;
  end else
    if(StatsParams<>0)then begin
      TextColor(LightRed);
      WriteLn('[ERROR] To many arguments for /wages command!');
      Result:=False;
    end;
end;

function StatsAttributesCheck(var I:Integer): Boolean;
var
  StatsParams, Rem: Integer;
  FS: TFormatSettings;
  SDFrom, SDTo: TDateTime;
begin
  Result:=True;
  StatsParams:=0;
  Rem:=I+1;
  repeat
    Inc(I);
    if(Length(ParamStr(I))>0)then
      if(ParamStr(I)[1]=P_PREFIX)then begin
        Dec(I);
        Break
      end else
        Inc(StatsParams)
    else
      Break;
  until(I>=ParamCount);
  FS.DateSeparator:='.';
  FS.LongDateFormat:='dd.mm.yyyy';
  FS.ShortDateFormat:='dd.mm';
  case StatsParams of
    0: StatsMode:=Full;
    1: begin
         if(AnsiLowerCase(ParamStr(Rem))=AF_WEEKS)then
           StatsMode:=Weeks
         else
           if(AnsiLowerCase(ParamStr(Rem))=AF_MONTHS)then
             StatsMode:=Months
           else
             if(AnsiLowerCase(ParamStr(Rem))=AF_DAYS)then
               StatsMode:=Days
             else begin
               StatsMode:=Day;
               if not(TryStrToDate(ParamStr(Rem), SDFrom, FS))then begin
                 UnknownAttribute(True, '['+AF_DATE+' (dd.mm.yyyy/dd.mm)]: '+ParamStr(Rem));
                 WriteLn(#$9'Or type: months, weeks or days');
                 Result:=False;
               end else
                 if(DB.CheckDay(SDFrom))then begin
                   Result:=False;
                   TextColor(LightRed);
                   WriteLn('[ERROR] Date (',FormatDateTime('DD.MM.YYYY', SDFrom),') is not in DB!');
                 end;
               if(Result)then begin
                 IDFrom:=DB.IDCreate(SDFrom);
                 IDTo:=DB.IDCreate(SDFrom);
               end;
             end;
       end;
    2: begin
         StatsMode:=FromTo;
         if not(TryStrToDate(ParamStr(Rem), SDFrom, FS))then begin
           UnknownAttribute(True, '['+AF_DATE+' (dd.mm.yyyy/dd.mm)]: '+ParamStr(Rem));
           Result:=False;
         end else
           if(DB.CheckDay(SDFrom))then begin
             Result:=False;
             TextColor(LightRed);
             WriteLn('[ERROR] Date (',FormatDateTime('DD.MM.YYYY', SDFrom),') is not in DB!');
           end;
         Inc(Rem);
         if not(TryStrToDate(ParamStr(Rem), SDTo, FS))then begin
           UnknownAttribute(True, '['+AF_DATE+' (dd.mm.yyyy/dd.mm)]: '+ParamStr(Rem));
           Result:=False;
         end else
           if(DB.CheckDay(SDTo))then begin
             Result:=False;
             TextColor(LightRed);
             WriteLn('[ERROR] Date (',FormatDateTime('DD.MM.YYYY', SDTo),') is not in DB!');
           end;
         if(Result)then
           if not(DB.IDCreate(SDFrom)<DB.IDCreate(SDTo))then
             if(DB.IDCreate(SDFrom)<>DB.IDCreate(SDTo))then begin
               Result:=False;
               TextColor(LightRed);
               WriteLn('[ERROR] Date (',FormatDateTime('DD.MM.YYYY', SDFrom),') is earlier than: ',
                       FormatDateTime('DD.MM.YYYY', SDTo));
             end else
               if(DB.IDCreate(SDFrom)=DB.IDCreate(SDTo))then begin
                 Result:=False;
                 TextColor(LightRed);
                 WriteLn('[ERROR] Date ',FormatDateTime('DD.MM.YYYY', SDFrom),' and ',
                         FormatDateTime('DD.MM.YYYY', SDTo), ' are the same!');
               end;
         if(Result)then begin
           IDFrom:=DB.IDCreate(SDFrom);
           IDTo:=DB.IDCreate(SDTo);
         end;
       end;
    else begin
      TextColor(LightRed);
      WriteLn('[ERROR] To many arguments for /stats command!');
      Result:=False;
    end;
  end;
end;

function ExpensesAttributesCheck(var I: Integer): Boolean;
var
  AttributesParams, Rem: Integer;
  FS: TFormatSettings;
begin
  Result:=True;
  AttributesParams:=0;
  Rem:=I+1;
  repeat
    Inc(I);
    if(Length(ParamStr(I))>0)then
      if(ParamStr(I)[1]=P_PREFIX)then begin
        Dec(I);
        Break
      end else
        Inc(AttributesParams)
    else
      Break;
  until(I>=ParamCount);
  if(AttributesParams=0)then
    Exit;
  if(AttributesParams in[2..3])then begin
    if(AttributesParams=3)then begin
      FS.DateSeparator:='.';
      FS.LongDateFormat:='dd.mm.yyyy';
      FS.ShortDateFormat:='dd.mm';
      if not(TryStrToDate(ParamStr(Rem+2), Expense.Date, FS))then begin
        Result:=False;
        UnknownAttribute(True, '['+PF_EXPENSE+' (dd.mm.yyyy/dd.mm)]: '+ParamStr(I));
      end;
    end;
    if(TryStrToInt(ParamStr(Rem+1), Expense.Value))then begin
      if(AttributesParams<3)then
        Expense.Date:=Now;
      Expense.Description:=ParamStr(Rem);
    end else begin
      Result:=False;
      UnknownAttribute(True, '['+PF_EXPENSE+']: '+ParamStr(I));
    end;
  end else begin
    if(AttributesParams<2)then begin
      Result:=False;
      TextColor(LightRed);
      WriteLn('[ERROR] Not enough arguments!'#13#10#13#10+'Examples:'#13#10+'/expense Phone 500'+#13#10+'/expense Phone 500 13.03');
    end else begin
      Result:=False;
      TextColor(LightRed);
      WriteLn('[ERROR] To many arguments!'#13#10#13#10+'Examples:'#13#10+'/expense Phone 500'+#13#10+'/expense Phone 500 13.03');
    end;
  end;
  Inc(I, AttributesParams);
end;

function DebtAttributesCheck(var I: Integer): Boolean;
var
  AttributesParams, Rem: Integer;
begin
  Result:=True;
  AttributesParams:=0;
  Rem:=I+1;
  repeat
    Inc(I);
    if(Length(ParamStr(I))>0)then
      if(ParamStr(I)[1]=P_PREFIX)then begin
        Dec(I);
        Break
      end else
        Inc(AttributesParams)
    else
      Break;
  until(I>=ParamCount);
  if(AttributesParams=0)then
    Exit;
  if(AttributesParams=2)then begin
    if not(TryStrToInt(ParamStr(Rem+1), Debt))then begin
      TextColor(LightRed);
      WriteLn('[ERROR] Wrong debt value!'#13#10#13#10+'Examples:'#13#10+'/debt Kowalski 500'+#13#10+'/debt (to get list)');
    end else
      DebtName:=ParamStr(Rem);
  end else begin
    TextColor(LightRed);
    WriteLn('[ERROR] Not enough arguments!'#13#10#13#10+'Examples:'#13#10+'/debt Kowalski 500'+#13#10+'/debt (to get list)');
  end;
end;

function SyntaxCheck: Boolean;
var
  I: Integer;
begin
  Result:=True;
  I:=1;
  repeat
    if(Length(ParamStr(I))>=1)then
      if not((ParamStr(I)[1]=P_PREFIX))then begin
        UnknownParameter(I);
        Result:=False;
      end else begin
        case(Ord(ParamStr(I)[2]))of
          Ord(P_ADD):     Result:=AddAttributesCheck(I);
          Ord(P_STATS):   Result:=StatsAttributesCheck(I);
          Ord(P_SALARY):  Result:=SalaryAttributesCheck(I);
          Ord(P_EXPENSE): Result:=ExpensesAttributesCheck(I);
          Ord(P_DEBT):    Result:=DebtAttributesCheck(I);
        end;
      end else
        Result:=False;
     Inc(I);
   until(I-1>=ParamCount);
end;

begin
  Randomize;
  try
    CoInitialize(nil);
    try
      DayHours.Assigned:=False;
      Date.Assigned:=False;
      Expense.Value:=0;
      DB:=TDataBase.Create('C:\Users\Alekkk\Dysk Google\prog\GNS\db.xml');
      try
        DB.Backup;
        DB.LoadDDB;
        if not(SyntaxCheck)then begin
          TextColor(LightGray);
          Exit;
        end;
  //    DB.SortDBDays;
        PParser;
      finally
        DB.ClearLists;
        DB.Free;
        TextColor(LightGray);
      end;
    finally
      CoUninitialize;
    end;
  except
    on E : Exception do begin
      TextColor(LightRed);
      WriteLn('[ERROR] Bum! APP Crash :('#13#10);
      WriteLn(E.ClassName, ': ', E.Message);
      TextColor(LightGray);
    end;
  end;
end.
