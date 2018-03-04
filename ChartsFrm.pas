unit ChartsFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TeEngine, Series, ExtCtrls, TeeProcs, Chart, Variables, GNSClasses,
  DateUtils, StdCtrls;

type
  TChartsForm = class(TForm)
    Chart: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    CBWallet: TCheckBox;
    CBWorkHours: TCheckBox;
    CBTips: TCheckBox;
    CBPause: TCheckBox;
    procedure CBWalletClick(Sender: TObject);
    procedure CBWorkHoursClick(Sender: TObject);
    procedure CBTipsClick(Sender: TObject);
    procedure CBPauseClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AddValues(DaysList: TList; ExpensesList: TList; Payment: TPayment);
  end;

var
  ChartsForm: TChartsForm;

implementation

{$R *.dfm}

procedure TChartsForm.AddValues(DaysList: TList; ExpensesList: TList; Payment: TPayment);
var
  I: Integer;
begin
  for I:=0 to DaysList.Count-1 do begin
    with PDDBItem(DaysList.Items[I])^ do begin
      Chart.Series[0].Add(HoursBetween(DayHours.Too, DayHours.From), FormatDateTime('DD.MM', Date.Date));
      Chart.Series[1].Add(Tip, FormatDateTime('DD.MM', Date.Date));
      Chart.Series[2].Add(Wallet, FormatDateTime('DD.MM', Date.Date));
      Chart.Series[3].Add(Pause, FormatDateTime('DD.MM', Date.Date));
    end;
  end;
end;

procedure TChartsForm.CBWalletClick(Sender: TObject);
begin
  Chart.Series[2].Active:=CBWallet.Checked;
end;

procedure TChartsForm.CBWorkHoursClick(Sender: TObject);
begin
  Chart.Series[0].Active:=CBWorkHours.Checked;
end;

procedure TChartsForm.CBTipsClick(Sender: TObject);
begin
  Chart.Series[1].Active:=CBTips.Checked;
end;

procedure TChartsForm.CBPauseClick(Sender: TObject);
begin
  Chart.Series[3].Active:=CBPause.Checked;
end;

end.
