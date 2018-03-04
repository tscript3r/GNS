unit Charts;

interface

uses
  Windows,
  Graphics,
  SysUtils,
  Classes,
  Forms,
  Dialogs;

type
  TChart = class
  private
    XValues,
    YValues: array of Integer;
    OOX,
    OOY,
    FXSize,
    FYSize,
    FXLeftMargin,
    FXRightMargin,
    FYTopMargin,
    FYBottomMargin: Integer;
    FBackgroundColor: TColor;
    FChartLineColor: TColor;
    FChartLineWidth: Integer;
    procedure PrepeareChart;
  public
    Chart: TBitmap;
    constructor Create;
    destructor Destroy; override;
    function Draw: Boolean;
    procedure AddXValue(Value: Integer);
    procedure AddYValue(Value: Integer);
    property XSize: Integer read FXSize write FXSize default 800;
    property YSize: Integer read FYSize write FYSize default 600;
    property XLeftMargin: Integer read FXLeftMargin write FXLeftMargin default 50;
    property XRightMargin: Integer read FXRightMargin write FXRightMargin default 50;
    property YTopMargin: Integer read FYTopMargin write FYTopMargin default 50;
    property YBottomMarin: Integer read FYBottomMargin write FYBottomMargin default 50;
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor default clWhite;
    property ChartLineColor: TColor read FChartLineColor write FChartLineColor default clBlack;
    property ChartLineWidth: Integer read FChartLineWidth write FChartLineWidth default 2;
  end;

implementation

constructor TChart.Create;
begin
  SetLength(XValues, 0);
  SetLength(YValues, 0);
  Chart:=TBitmap.Create;
end;

destructor TChart.Destroy;
begin
  Chart.Free;
end;

procedure TChart.AddXValue(Value: Integer);
begin
  SetLength(XValues, Length(XValues)+1);
  XValues[Length(XValues)-1]:=Value;
end;

procedure TChart.AddYValue(Value: Integer);
begin
  SetLength(YValues, Length(YValues)+1);
  YValues[Length(YValues)-1]:=Value;
end;

procedure TChart.PrepeareChart;
begin
  with Chart do begin
    PixelFormat:=pf24bit;
    Height:=FYSize+FYBottomMargin+FYTopMargin;
    Width:=FXSize+FXRightMargin+FXLeftMargin;
    Canvas.Brush.Color:=FBackgroundColor;
    Canvas.FillRect(Rect(0, 0, Width, Height));
    OOX:=FXLeftMargin;
    OOY:=FYSize+FYTopMargin;
    Canvas.Pen.Color:=FChartLineColor;
    Canvas.Pen.Width:=FChartLineWidth;
    Canvas.MoveTo(OOX, OOY);
    Canvas.LineTo(FXSize+FXRightMargin, OOY);
    Canvas.MoveTo(OOX, OOY);
    Canvas.LineTo(OOX, FYTopMargin);
  end;
end;

function TChart.Draw: Boolean;
begin
  Result:=False;
  with Chart do begin
    PrepeareChart;
    SaveToFile('test.bmp');
  end;
end;

end.
