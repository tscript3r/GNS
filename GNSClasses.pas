unit GNSClasses;

interface

uses
  Variables,
  SysUtils,
  Classes,
  Windows,
  Forms,
  Dialogs,
  Console,
  DateUtils,
  xmldom,
  XMLIntf,
  msxmldom,
  XMLDoc,
  ActiveX;

const
{$J+}
  END_OF_WORK: TDateTime = 0;
{$J-}

type
  TPayment = class
  private
    Payments: array of TPay;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Month, Count: Integer);
    function GetCount(Month: Integer): Integer;
    function GetAllCount: Integer;
    function GetPaymentCount: Integer;
    function HighestPayment(var Count: Integer): Integer;
    function LowestPayment(var Count: Integer): Integer;
  end;

  TDebt = class
  public
    Debts: array of TDebtItem;
    constructor Create;
    destructor Destroy; override;
    procedure Add(Who: String; Mutch: Integer);
    function Count: Integer;
  end;

  TXMLDB = class
  private
    FPayment: TPayment;
    XML: IXMLDOCUMENT;
    FDaysList: TList;
    FExpensesList: TList;
    FFileName: String;
    FEOS: TDateTime;
    FDebt: TDebt;
  public
    constructor Create(DBFile: String; DaysList: TList; ExpensesList: TList; Payment: TPayment; Debt: TDebt; var EOS: TDateTime);
    destructor Destroy; override;
    procedure SaveToFile;
    function LoadFromFile: Boolean;
  end;

  TStats = class
  private
    FDaysList: TList;
    FPayment: TPayment;
    FExpensesList: TList;
    function FindID(ID: Integer): Integer;
  public
    constructor Create(DaysList: TList; Payment: TPayment; ExpensesList: TList);
    destructor Destroy; override;

    function IDCreate(DateE: TDateTime): Integer;
    function GetFirstDayID: Integer;
    function GetLastDayIDofMonth(Month: Integer): Integer;

    function TipsCount: Integer; overload;
    function TipsCount(From, Too: Integer): Integer; overload;
    function BestTip(var Count: Integer): TDateTime; overload;
    function BestTip(From, Too: Integer; var Count: Integer): TDateTime; overload;
    function LeastTip(var Count: Integer): TDateTime; overload;
    function LeastTip(From, Too: Integer; var Count: Integer): TDateTime; overload;
    function DaysCount: Integer; overload;
    function DaysCount(From, Too: Integer): Integer; overload;
    function WorkTimeMinutes: Integer; overload;
    function WorkTimeMinutes(From, Too: Integer): Integer; overload;
    function PauseTime: Integer; overload;
    function PauseTime(From, Too: Integer): Integer; overload;
    function LongestDay(var WorkTime: Integer): TDateTime; overload;
    function LongestDay(From, Too: Integer; var WorkTime: Integer): TDateTime; overload;
    function ShortestDay(var WorkTime: Integer): TDateTime; overload;
    function ShortestDay(From, Too: Integer; var WorkTime: Integer): TDateTime; overload;
    function BestWallet(var Count: Integer): TDateTime; overload;
    function BestWallet(From, Too: Integer; var Count: Integer): TDateTime; overload;
    function WalletCount: Integer; overload;
    function WalletCount(From, Too: Integer): Integer; overload;
    function LeastWallet(var Count: Integer): TDateTime; overload;
    function LeastWallet(From, Too: Integer; var Count: Integer): TDateTime; overload;

    function ExpensesCount: Integer;

    function PaymentCount: Integer;
    function PaymentMonths: Integer;
    function PaymentBest(var Count: Integer): Integer;
    function PaymentLeast(var Count: Integer): Integer;

    function PrognosisTip: Double;
    function PrognosisDaysLeft: Integer;
    function PrognosisWorkDaysLeft: Integer;
    function PrognosisWorkTimeLeft: Integer;
    function PrognosisWalletAverage: Integer;
  end;

  TDataBase = class
  private
    FDDBFile: String;
    FEDBFile: String;
    FEOS: TDateTime;
    XMLDB: TXMLDB;
  public
    DaysList: TList;
    ExpensesList: TList;
    Stats: TStats;
    Payment: TPayment;
    Debt: TDebt;
    constructor Create(DBFile: String);
    destructor  Destroy; override;
    procedure   LoadDDB;
    procedure   AddDay(Wallet, Tip: Integer; Hours: TDayHours; Pause: Integer;
                       DateEx: TDateTime);
    procedure   AddExpense(Expense: TEDBItem);
    procedure   ClearLists;
    function    FindID(ID: Integer): Integer;
    function    IDCreate(DateE: TDateTime): Integer;
    function    CheckDay(Date: TDateTime): Boolean;
    procedure   SortDBDays;
    procedure   SaveToFile;
    procedure   AssignTip;
    procedure   Backup;
    property ExpensesDBFile: String read FEDBFile write FEDBFile;
    property DaysDBFile: String read FDDBFile write FDDBFile;
    property EndOfSeason: TDateTime read FEOS write FEOS;
  end;

implementation

constructor TDebt.Create;
begin
  SetLength(Debts, 0);
end;

destructor TDebt.Destroy;
begin
  SetLength(Debts, 0);
end;

procedure TDebt.Add(Who: String; Mutch: Integer);
var
  I: Integer;
  New: Boolean;
begin
  if(Length(Debts)<=0)then begin
    SetLength(Debts, 1);
    Debts[0].Who:=Who;
    Debts[0].Mutch:=Mutch;
  end else begin
    New:=True;
    for I:=0 to Length(Debts)-1 do
      if(AnsiLowerCase(Who)=AnsiLowerCase(Debts[I].Who))then begin
        New:=False;
        Break;
      end;
    if(New)then begin
      SetLength(Debts, Length(Debts)+1);
      Debts[Length(Debts)-1].Who:=Who;
      Debts[Length(Debts)-1].Mutch:=Mutch;
    end else
      Debts[I].Mutch:=Debts[I].Mutch+Mutch;
  end;
end;

function TDebt.Count: Integer;
var
  I: Integer;
begin
  Result:=0;
  if(Length(Debts)>0)then
    for I:=0 to Length(Debts)-1 do
      Inc(Result, Debts[i].Mutch);
end;

constructor TPayment.Create;
begin
  SetLength(Payments, 0);
end;

destructor TPayment.Destroy;
begin
  SetLength(Payments, 0);
end;

procedure TPayment.Add(Month, Count: Integer);
begin
  SetLength(Payments, Length(Payments)+1);
  Payments[Length(Payments)-1].Month:=Month;
  Payments[Length(Payments)-1].Count:=Count;
end;

function TPayment.GetCount(Month: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  if(Length(Payments)>0)then
    for I:=0 to Length(Payments)-1 do
      if(Payments[I].Month=Month)then
        Result:=Payments[I].Count;
end;

function TPayment.GetAllCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  if(Length(Payments)>0)then
    for I:=0 to Length(Payments)-1 do
      Inc(Result, Payments[I].Count);
end;

function TPayment.GetPaymentCount: Integer;
begin
  Result:=Length(Payments);
end;

function TPayment.HighestPayment(var Count: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  Count:=0;
  if(Length(Payments)>0)then
    for I:=0 to Length(Payments)-1 do
      if(Count<Payments[I].Count)then begin
        Result:=Payments[I].Month;
        Count:=Payments[I].Count;
      end;
end;

function TPayment.LowestPayment(var Count: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  Count:=0;
  if(Length(Payments)>0)then begin
    Result:=Payments[0].Month;
    Count:=Payments[0].Count;
    for I:=0 to Length(Payments)-1 do
      if(Count<=Payments[I].Count)then begin
        Result:=Payments[I].Month;
        Count:=Payments[I].Count;
      end;
  end;
end;

constructor TXMLDB.Create(DBFile: String; DaysList: TList; ExpensesList: TList; Payment: TPayment; Debt: TDebt; var EOS: TDateTime);
begin
  FFileName:=DBFile;
  FDaysList:=DaysList;
  FExpensesList:=ExpensesList;
  FPayment:=Payment;
  FEOS:=EOS;
  FDebt:=Debt;
end;


destructor TXMLDB.Destroy;
begin
 //XML.Active := False;
end;

procedure TXMLDB.SaveToFile;
var
  FS: TFormatSettings;
  FirstNode, SubSecond, SecondNode, DeepNode: IXMLNODE;
  I, Month: Integer;
begin
  XML:=NewXMLDocument;
  XML.Active := True;
  XML.Encoding:= 'UTF-8';
  XML.Options := [doNodeAutoIndent];
  FirstNode:=XML.AddChild('GNSDB');
  SubSecond:=FirstNode.AddChild('Work');
  GetLocaleFormatSettings(GetThreadLocale, FS);
  FS.LongDateFormat:='dd.mm.yyyy';
  FS.ShortDateFormat:='dd.mm.yyyy';
  FS.DateSeparator:='.';
  I:=0;
  repeat
      Month:=MonthOf(PDDBItem(FDaysList.Items[I])^.Date.Date);
      SecondNode:=SubSecond.AddChild('Month');
      SecondNode.Attributes['id']:=Month;
      SecondNode.Attributes['name']:=LongMonthNames[Month];
      if(FPayment.GetCount(Month)<>-1)then
        SecondNode.Attributes['payment']:=FPayment.GetCount(Month);
      repeat
        with PDDBItem(FDaysList.Items[I])^ do begin
          DeepNode:=SecondNode.AddChild('Day');
          DeepNode.Attributes['id']:=ID;
          DeepNode.Attributes['date']:=DateToStr(Date.Date, FS);
          DeepNode.Attributes['h_from']:=TimeToStr(DayHours.From);
          DeepNode.Attributes['h_to']:=TimeToStr(DayHours.Too);
          DeepNode.Attributes['wallet']:=Wallet;
          DeepNode.Attributes['tip']:=Tip;
          DeepNode.Attributes['pause']:=Pause;
        end;
        Inc(I);
        if(I>FDaysList.Count-1)then
          Break;
        if(Month<>MonthOf(PDDBItem(FDaysList.Items[I])^.Date.Date))then
          Break;
      until(I>FDaysList.Count-1);
  until(I>FDaysList.Count-1);
  if(FExpensesList.Count>0)then begin
    SecondNode:=FirstNode.AddChild('Expenses');
    for I:=0 to FExpensesList.Count-1 do begin
      with PEDBItem(FExpensesList.Items[I])^ do begin
        DeepNode:=SecondNode.AddChild('Expense');
        DeepNode.Attributes['value']:=Value;
        DeepNode.Attributes['description']:=Description;
        DeepNode.Attributes['date']:=DateToStr(Date, FS);
      end;
    end;
  end;
  if(Length(FDebt.Debts)>0)then begin
    SecondNode:=FirstNode.AddChild('Debts');
    for I:=0 to Length(FDebt.Debts)-1 do begin
      DeepNode:=SecondNode.AddChild('Debt');
      DeepNode.Attributes['who']:=FDebt.Debts[I].Who;
      DeepNode.Attributes['mutch']:=FDebt.Debts[I].Mutch;
    end;
  end;
  XML.SaveToFile(FFileName);
  //XML.Active:=False;
end;

function TXMLDB.LoadFromFile: Boolean;
var
  FirstNode, SubSecond, SecondNode: IXMLNODE;
  Item: PDDBItem;
  EItem: PEDBItem;
  FS: TFormatSettings;
begin
  Result:=False;
  if not(FileExists(FFileName))then
    Exit;
  GetLocaleFormatSettings(GetThreadLocale, FS);
  FS.LongDateFormat:='dd.mm.yyyy';
  FS.ShortDateFormat:='dd.mm.yyyy';
  FS.DateSeparator:='.';
  XML:=LoadXMLDocument(FFileName);
  XML.Active:=True;
  FirstNode:=XML.DocumentElement.ChildNodes.FindNode('Work');
  SubSecond:=FirstNode.ChildNodes.FindNode('Month');
  repeat
    if(SubSecond.HasAttribute('payment'))then
      FPayment.Add(SubSecond.Attributes['id'], SubSecond.Attributes['payment']);
    SecondNode:=SubSecond.ChildNodes.FindNode('Day');
    repeat
      New(Item);
      Item^.ID:=SecondNode.Attributes['id'];
      Item^.Date.Assigned:=True;
      Item^.Date.Date:=StrToDate(SecondNode.Attributes['date'], FS);
      Item^.DayHours.Assigned:=True;
      Item^.DayHours.From:=StrToTime(SecondNode.Attributes['h_from']);
      Item^.DayHours.Too:=StrToTime(SecondNode.Attributes['h_to']);
      Item^.Wallet:=SecondNode.Attributes['wallet'];
      Item^.Tip:=SecondNode.Attributes['tip'];
      Item^.Pause:=SecondNode.Attributes['pause'];
      FDaysList.Add(Item);
      SecondNode:=SecondNode.NextSibling;
    until(SecondNode=nil);
    SubSecond:=SubSecond.NextSibling;
  until(SubSecond=nil);
  Result:=True;
  FirstNode:=XML.DocumentElement.ChildNodes.FindNode('Expenses');
  if(FirstNode<>nil)then begin
    SecondNode:=FirstNode.ChildNodes.FindNode('Expense');
    if(SecondNode<>nil)then
      repeat
        New(EItem);
        EItem^.Value:=SecondNode.Attributes['value'];
        EItem^.Description:=SecondNode.Attributes['description'];
        EItem^.Date:=StrToDate(SecondNode.Attributes['date'], FS);
        FExpensesList.Add(EItem);
        SecondNode:=SecondNode.NextSibling;
      until(SecondNode=nil);
  end;
  FirstNode:=XML.DocumentElement.ChildNodes.FindNode('Debts');
  if(FirstNode<>nil)then begin
    SecondNode:=FirstNode.ChildNodes.FindNode('Debt');
    if(SecondNode<>nil)then
      repeat
        FDebt.Add(SecondNode.Attributes['who'], SecondNode.Attributes['mutch']);
        SecondNode:=SecondNode.NextSibling;
      until(SecondNode=nil);
  end;
  //XML.Active:=False; }
end;


constructor TStats.Create(DaysList: TList; Payment: TPayment; ExpensesList: TList);
begin
  FPayment:=Payment;
  FDaysList:=DaysList;
  FExpensesList:=ExpensesList;
end;

destructor TStats.Destroy;
begin

end;

function TStats.IDCreate(DateE: TDateTime): Integer;
var
  StartDate: TDateTime;
begin
  StartDate:=EncodeDateTime(2015, 01, 01, 0, 0, 0, 0);
  Result:=DaysBetween(DateE, StartDate);
end;

function TStats.FindID(ID: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  if(FDaysList.Count>=0)then
    for I:=0 to FDaysList.Count-1 do
      if(PDDBItem(FDaysList.Items[I])^.ID=ID)then begin
        Result:=I;
        Break;
      end;
end;

function TStats.GetFirstDayID: Integer;
begin
  Result:=-1;
  if(FDaysList.Count>=0)then
    Result:=PDDBItem(FDaysList.Items[0])^.ID;
end;

function TStats.GetLastDayIDOfMonth(Month: Integer): Integer;
var
  Date: TDateTime;
begin
  Date:=EncodeDate(YearOf(Now), Month, DayOf(EndOfAMonth(YearOf(Now), Month)));
  Result:=IDCreate(Date);
end;

function TStats.TipsCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to FDaysList.Count-1 do
    Inc(Result, PDDBItem(FDaysList.Items[I])^.Tip);
end;

function TStats.TipsCount(From, Too: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Inc(Result);
    for I:=From to Too do
      Inc(Result, PDDBItem(FDaysList.Items[I])^.Tip);
  end;
end;

function TStats.BestTip(var Count: Integer): TDateTime;
var
  I: Integer;
begin
  Result:=0;
  Count:=0;
  for I:=0 to FDaysList.Count-1 do
    if(PDDBItem(FDaysList.Items[I]).Tip>Count)then begin
      Count:=PDDBItem(FDaysList.Items[I]).Tip;
      Result:=PDDBItem(FDaysList.Items[I]).Date.Date;
    end;
end;

function TStats.BestTip(From, Too: Integer; var Count: Integer): TDateTime;
var
  I: Integer;
begin
  Count:=-1;
  Result:=0;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    for I:=From to Too do
      if(PDDBItem(FDaysList.Items[I]).Tip>Count)then begin
        Count:=PDDBItem(FDaysList.Items[I]).Tip;
        Result:=PDDBItem(FDaysList.Items[I]).Date.Date;
      end;
  end;
end;

function TStats.LeastTip(var Count: Integer): TDateTime;
var
 I: Integer;
begin
  Result:=0;
  Count:=PDDBItem(FDaysList.Items[0])^.Tip;
  for I:=1 to FDaysList.Count-2 do
    if(Count>PDDBItem(FDaysList.Items[I])^.Tip)then begin
      Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
      Count:=PDDBItem(FDaysList.Items[I])^.Tip;
    end;
end;

function TStats.LeastTip(From, Too: Integer; var Count: Integer): TDateTime;
var
  I: Integer;
begin
  From:=FindID(From);
  Too:=FindID(Too);
  Count:=PDDBItem(FDaysList.Items[From])^.Tip;
  Result:=PDDBItem(FDaysList.Items[From])^.Date.Date;
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    if(Too=FDaysList.Count-1)and(Too>0)then
      Dec(Too);
    for I:=From to Too do
      if(Count>PDDBItem(FDaysList.Items[I])^.Tip)then begin
        Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
        Count:=PDDBItem(FDaysList.Items[I])^.Tip;
      end;
  end else
    Count:=-1;
end;

function TStats.DaysCount(From, Too: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Inc(Result);
    for I:=From to Too do
      Inc(Result);
  end;
end;

function TStats.WorkTimeMinutes: Integer;
var
  Count: Integer;
  I: Integer;
begin
  Result:=0;
  for I:=0 to FDaysList.Count-1 do begin
    Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                          PDDBItem(FDaysList.Items[I])^.DayHours.Too);
    if((Count mod 5)<>0)then
      Inc(Count);
    Inc(Result, Count);
    Dec(Result, PDDBItem(FDaysList.Items[I])^.Pause);
  end;
end;

function TStats.WorkTimeMinutes(From, Too: Integer): Integer;
var
  Count: Integer;
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    for I:=From to Too do begin
      Inc(Result);
      Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                            PDDBItem(FDaysList.Items[I])^.DayHours.Too);
      if((Count mod 5)<>0)then
        Inc(Count);
      Inc(Result, Count);
      Dec(Result, PDDBItem(FDaysList.Items[I])^.Pause);
    end;
    Dec(Result);
  end;
end;

function TStats.PauseTime: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to FDaysList.Count-1 do
    Inc(Result, PDDBItem(FDaysList.Items[I])^.Pause);
end;

function TStats.PauseTime(From, Too: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Inc(Result);
    for I:=From to Too do
      Inc(Result, PDDBItem(FDaysList.Items[I])^.Pause);
  end;
end;

function TStats.LongestDay(var WorkTime: Integer): TDateTime;
var
  Count, I: Integer;
begin
  WorkTime:=0;
  Result:=0;
  for I:=0 to FDaysList.Count-1 do begin
    Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                          PDDBItem(FDaysList.Items[I])^.DayHours.Too);
    if(Count>=WorkTime)then begin
      WorkTime:=Count;
      Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
    end;
  end;
end;

function TStats.LongestDay(From, Too: Integer; var WorkTime: Integer): TDateTime;
var
  Count, I: Integer;
begin
  Result:=0;
  WorkTime:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Inc(WorkTime);
    for I:=From to Too do begin
      Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                            PDDBItem(FDaysList.Items[I])^.DayHours.Too);
      if(Count>=WorkTime)then begin
        WorkTime:=Count;
        Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
      end;
    end;
  end;
end;

function TStats.ShortestDay(var WorkTime: Integer): TDateTime;
var
  Count, I: Integer;
begin
  Result:=0;
  WorkTime:=MinutesBetween(PDDBItem(FDaysList.Items[0])^.DayHours.From,
                           PDDBItem(FDaysList.Items[0])^.DayHours.Too);
  for I:=1 to FDaysList.Count-1 do begin
    Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                          PDDBItem(FDaysList.Items[I])^.DayHours.Too);
    if(Count<WorkTime)then begin
      WorkTime:=Count;
      Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
    end;
  end;
end;

function TStats.ShortestDay(From, Too: Integer; var WorkTime: Integer): TDateTime;
var
  Count, I: Integer;
begin
  Result:=0;
  WorkTime:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    WorkTime:=MinutesBetween(PDDBItem(FDaysList.Items[From])^.DayHours.From,
                             PDDBItem(FDaysList.Items[From])^.DayHours.Too);
    Result:=PDDBItem(FDaysList.Items[From])^.Date.Date;
    for I:=From to Too do begin
      Count:=MinutesBetween(PDDBItem(FDaysList.Items[I])^.DayHours.From,
                            PDDBItem(FDaysList.Items[I])^.DayHours.Too);
      if(Count<WorkTime)then begin
        WorkTime:=Count;
        Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
      end;
    end;
  end;
end;

function TStats.BestWallet(var Count: Integer): TDateTime;
var
  I: Integer;
begin
  Result:=0;
  Count:=0;
  for I:=0 to FDaysList.Count-1 do
    if(PDDBItem(FDaysList.Items[I]).Wallet>Count)then begin
      Count:=PDDBItem(FDaysList.Items[I]).Wallet;
      Result:=PDDBItem(FDaysList.Items[I]).Date.Date;
    end;
end;

function TStats.BestWallet(From, Too: Integer; var Count: Integer): TDateTime;
var
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Result:=0;
    Count:=0;
    for I:=From to Too do
      if(PDDBItem(FDaysList.Items[I]).Wallet>Count)then begin
        Count:=PDDBItem(FDaysList.Items[I]).Wallet;
        Result:=PDDBItem(FDaysList.Items[I]).Date.Date;
      end;
  end;
end;

function TStats.WalletCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to FDaysList.Count-1 do
    Inc(Result, PDDBItem(FDaysList.Items[I])^.Wallet);
end;

function TStats.WalletCount(From, Too: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Inc(Result);
    for I:=From to Too do
      Inc(Result, PDDBItem(FDaysList.Items[I])^.Wallet);
  end;
end;

function TStats.DaysCount: Integer;
begin
  Result:=FDaysList.Count;
end;

function TStats.LeastWallet(var Count: Integer): TDateTime;
var
 I: Integer;
begin
  Result:=0;
  Count:=PDDBItem(FDaysList.Items[0])^.Wallet;
  for I:=1 to FDaysList.Count-2 do
    if(Count>PDDBItem(FDaysList.Items[I])^.Wallet)then begin
      Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
      Count:=PDDBItem(FDaysList.Items[I])^.Wallet;
    end;
end;

function TStats.LeastWallet(From, Too: Integer; var Count: Integer): TDateTime;
var
  I: Integer;
begin
  Result:=0;
  Count:=-1;
  From:=FindID(From);
  Too:=FindID(Too);
  if(From>-1)and(Too>-1)and(From<=Too)then begin
    Count:=PDDBItem(FDaysList.Items[From])^.Wallet;
    Result:=PDDBItem(FDaysList.Items[From])^.Date.Date;
    for I:=From to Too do
      if(Count>PDDBItem(FDaysList.Items[I])^.Wallet)then begin
        Result:=PDDBItem(FDaysList.Items[I])^.Date.Date;
        Count:=PDDBItem(FDaysList.Items[I])^.Wallet;
      end;
  end;
end;

function TStats.ExpensesCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  if(FExpensesList.Count>0)then
    for I:=0 to FExpensesList.Count-1 do
      Inc(Result, PEDBItem(FExpensesList.Items[I])^.Value);
end;

function TStats.PaymentCount: Integer;
begin
  Result:=FPayment.GetAllCount;
end;

function TStats.PaymentMonths: Integer;
begin
  Result:=FPayment.GetPaymentCount;
end;

function TStats.PaymentBest(var Count: Integer): Integer;
begin
  Result:=FPayment.HighestPayment(Count);
end;

function TStats.PaymentLeast(var Count: Integer): Integer;
begin
  Result:=FPayment.LowestPayment(Count);
end;

function TStats.PrognosisTip: Double;
var
  TipAverage: Double;
begin
  TipAverage:=TipsCount/DaysCount;
  Result:=TipAverage*PrognosisWorkDaysLeft;
end;

function TStats.PrognosisWorkDaysLeft: Integer;
begin
  Result:=DaysBetween(Now, END_OF_WORK);
  Result:=Result-WeeksBetween(Now, END_OF_WORK);
end;

function TStats.PrognosisDaysLeft: Integer;
begin
  Result:=DaysBetween(Now, END_OF_WORK);
end;

function TStats.PrognosisWorkTimeLeft: Integer;
var
  WorkTimeAverage: Double;
begin
  WorkTimeAverage:=WorkTimeMinutes/DaysCount;
  Result:=Round(WorkTimeAverage*PrognosisWorkDaysLeft);
end;

function TStats.PrognosisWalletAverage: Integer;
begin
  Result:=(Round(WalletCount/DaysCount))*PrognosisWorkDaysLeft;
end;


constructor TDataBase.Create;
begin
  FDDBFile:=DBFile;
  DaysList:=TList.Create;
  ExpensesList:=TList.Create;
  Payment:=TPayment.Create;
  Debt:=TDebt.Create;
  Stats:=TStats.Create(DaysList, Payment, ExpensesList);
  XMLDB:=TXMLDB.Create(FDDBFile, DaysList, ExpensesList, Payment, Debt, FEOS);
end;

destructor TDataBase.Destroy;
begin
  DaysList.Free;
  Stats.Free;
  ExpensesList.Free;
  XMLDB.Free;
  Payment.Free;
  Debt.Free;
end;

procedure TDataBase.ClearLists;
var
  I: Integer;
begin
  if(DaysList.Count>0)then
    for I:=0 to DaysList.Count-1 do
      Dispose(DaysList.Items[I]);
  if(ExpensesList.Count>0)then
    for I:=0 to ExpensesList.Count-1 do
      Dispose(ExpensesList.Items[I]);
end;

procedure TDataBase.LoadDDB;
begin
  XMLDB.LoadFromFile;
end;

function TDataBase.IDCreate(DateE: TDateTime): Integer;
var
  StartDate: TDateTime;
begin
  StartDate:=EncodeDateTime(2015, 01, 01, 0, 0, 0, 0);
  Result:=DaysBetween(DateE, StartDate);
end;

procedure TDataBase.AddDay(Wallet, Tip: Integer; Hours: TDayHours; Pause: Integer;
                           DateEx: TDateTime);
var
  Item: PDDBItem;
begin
  New(Item);
  Item^.ID:=IDCreate(DateEx);
  Item^.Wallet:=Wallet;
  Item^.Tip:=Tip;
  Item^.DayHours:=Hours;
  Item^.DayHours.Assigned:=True;
  Item^.Pause:=Pause;
  Item^.Date.Assigned:=True;
  Item^.Date.Date:=DateEx;
  DaysList.Add(Item);
end;

procedure TDataBase.SaveToFile;
begin
  Backup;
  XMLDB.SaveToFile;
end;

procedure TDataBase.Backup;
begin
  CopyFile(PChar(FDDBFile), PChar(ExtractFilePath(FDDBFile)+'backup\'+FormatDateTime('DDMM', Date)+'_'+ExtractFileName(FDDBFile)), False);
end;

function TDataBase.CheckDay(Date: TDateTime): Boolean;
var
  I: Integer;
begin
  Result:=True;
  if(DaysList.Count>0)then
    for I:=0 to DaysList.Count-1 do
      if(IDCreate(Date)=PDDBItem(DaysList.Items[I])^.ID)then begin
        Result:=False;
        Break;
      end;
end;

procedure TDataBase.SortDBDays;
var
  I, J: Integer;
  T: PDDBItem;
begin
  for I := 0 to DaysList.Count-2 do
    for J := I+1 to DaysList.Count-1 do
      if(PDDBItem(DaysList.Items[I])^.Date.Date<PDDBItem(DaysList.Items[J])^.Date.Date)then begin
        T := PDDBItem(DaysList.Items[I]);
        PDDBItem(DaysList.Items[I])^ := PDDBItem(DaysList.Items[J])^;
        PDDBItem(DaysList.Items[J])^ := T^;
      end;
end;

procedure TDataBase.AssignTip;
begin
  if(DaysList.Count>2)then begin
    PDDBItem(DaysList.Items[DaysList.Count-2])^.Tip:=PDDBItem(DaysList.Items[DaysList.Count-1])^.Tip;
    PDDBItem(DaysList.Items[DaysList.Count-1])^.Tip:=0;
  end;
end;

procedure TDataBase.AddExpense(Expense: TEDBItem);
var
  Exp: PEDBItem;
begin
  New(Exp);
  Exp^.Value:=Expense.Value;
  Exp^.Description:=Expense.Description;
  Exp^.Date:=Expense.Date;
  ExpensesList.Add(Exp);
end;

function TDataBase.FindID(ID: Integer): Integer;
var
  I: Integer;
begin
  Result:=-1;
  if(DaysList.Count>=0)then
    for I:=0 to DaysList.Count-1 do
      if(PDDBItem(DaysList.Items[I])^.ID=ID)then begin
        Result:=I;
        Break;
      end;
end;

initialization
  END_OF_WORK := EncodeDate(2015, 9, 29);

end.
