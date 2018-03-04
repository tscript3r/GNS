unit Variables;

interface

uses Classes;

type
  TDebtItem = record
    Who: String;
    Mutch: Integer;
  end;

  TPay = record
    Month,
    Count: Integer;
  end;

  TDayHours = record
    Assigned: Boolean;
    From,
    Too:  TDateTime;
  end;

  TDateEx = record
    Assigned: Boolean;
    Date: TDateTime;
  end;

  TDDBItem = packed record
    ID,
    Wallet,
    Tip: Integer;
    DayHours: TDayHours;
    Pause: Integer;
    Date: TDateEx
  end;
  PDDBItem = ^TDDBItem;

  TEDBItem = packed record
    Value: Integer;
    Description: String[255];
    Date: TDateTime;
  end;
  PEDBItem = ^TEDBItem;

  PList = ^TList;


implementation

end.
