unit u_Timer;

{$MODE Delphi}


interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, sqldb;

// Contador de Tempo

type
  TClk = record
    StartHi, StartLo: Cardinal;
    TotalHi, TotalLo: Cardinal;
  end;

const
  ClkZero: TClk = (TotalHi: 0; TotalLo: 0);

var
  CpuClock: extended; // clock da CPU (em Hz) (inicializado na inicializacao da lib

procedure ClkReset(var Clk: TClk); // inicializa o tempo total com "0"
procedure ClkStart(var Clk: TClk); // marca o inicio de contagem
procedure ClkStop(var Clk: TClk); // adiciona o tempo desde "ClkStart" ao tempo total
function ClkGet(const Clk: TClk): extended; // retorna o tempo total, em segundos
function ClkGetStr(const nome: string; const Clk: TClk): string;
function ClkGetStrPerc(const nome: string; const Clk, ClkBase: TClk): string;
procedure CpuClockInit; // verifica o clock do processador (leva 1/10 segundos p/ obter precisao)

{ CrK -> }
type
  TTimer = record
    Count: Integer;
    Clk: TClk;
  end;
  PTimer = ^TTimer;
{ <- CrK }

function TimerCreate(const Name: string): Integer; { Inicializa um contador de tempo }
procedure TimerFree(Timer: Integer);
procedure TimerStart(Timer: Integer); { Começa a contagem }
procedure TimerStop(Timer: Integer); { Pára a contagem }
procedure TimerResetAll; { Zera todos os timers }
function TimerGet(Timer: Integer): Double; { Pega o valor em segundos do timer }
procedure TimersListGet(List: TStringList; const Sep: string);

implementation

procedure ClkReset(var Clk: TClk);
begin
  Clk.TotalHi := 0;
  Clk.TotalLo := 0;
end;

procedure ClkStart(var Clk: TClk);
var
  StartHi, StartLo: cardinal;
begin
  {$ASMMODE intel}
  asm
    //push eax // senao da excessao
    //push edx
    db $0F // Get TimeStamp (somente em Pentium)
    db $31
    mov StartLo, eax
    mov StartHi, edx
    //pop edx
    //pop eax
  end;
  Clk.StartLo := StartLo;
  Clk.StartHi := StartHi;
end;

procedure ClkStop(var Clk: TClk);
var
  StartHi, StartLo: cardinal;
  TotalHi, TotalLo: cardinal;
begin
  TotalLo := Clk.TotalLo;
  TotalHi := Clk.TotalHi;
  StartLo := Clk.StartLo;
  StartHi := Clk.StartHi;
  {$ASMMODE intel}
  asm
    //push eax // senao da excessao
    //push edx
    db $0F  // Get TimeStamp (somente em Pentium)
    db $31
    sub eax, StartLo
    sbb edx, StartHi
    add TotalLo, eax
    adc TotalHi, edx
    //pop edx
    //pop eax
  end;
  Clk.TotalLo := TotalLo;
  Clk.TotalHi := TotalHi;
end;

function ClkGet(const Clk: TClk): extended;
begin
  result := (Clk.TotalHi*(256.0*256.0*256.0*256.0) + Clk.TotalLo) / CpuClock;
end;

function ClkGetStr(const nome: string; const Clk: TClk): string;
var
  total: extended;
begin
  total := ClkGet(Clk);
  result := nome + ': ' + FloatToStrF(total, ffFixed, 18, 6) + 's';
  // IntToStr(round(total*100000));
end;

function ClkGetStrPerc(const nome: string; const Clk, ClkBase: TClk): string;
var
  perc: extended;
begin
  perc := ClkGet(Clk) / ClkGet(ClkBase) * 100;
  result := ClkGetStr(nome, Clk);
  result := result + ' (' + FloatToStrF(perc, ffFixed, 18, 4) + '%)';
//    result := result + ' (' + IntToStr(trunc(perc)) + '.' + IntToStr(trunc(perc*1000) mod 1000) + '%)';
end;

procedure CpuClockInit; // verifica o clock do processador (leva 1/10 segundos p/ obter precisao)
var
  t, t1, t2: cardinal;
  c: TClk;
begin
  ClkReset(c);
  t := GetTickCount + 10;
  repeat // espera o inicio do clock
    t1 := GetTickCount;
  until t1 >= t;
  ClkStart(c);
  repeat // espera o inicio do clock
    t2 := GetTickCount;
  until t2 >= t1 + 50;
  ClkStop(c);
  CpuClock := c.TotalHi*(256.0*256.0*256.0*256.0) + c.TotalLo;
  CpuClock := CpuClock / ((t2 - t1) / 1000.0);
end;

var
  Timers: TStringList;

type
  PClk = ^TClk;

function TimerCreate(const Name: string): Integer;
var
  T: PTimer;
begin
  if Timers = nil then Timers := TStringList.Create;
  New(T);
  Result := Timers.AddObject(Name, TObject(T));
end;

procedure TimerFree(Timer: Integer);
begin
  if Timers <> nil then begin
    Dispose(PTimer(Timers.Objects[Timer]));
    Timers.Objects[Timer] := nil;
    Timers[Timer] := '';
  end;
end;

procedure TimerStart(Timer: Integer);
var
  T: PTimer;
begin
  if Timers <> nil then begin
    T := PTimer(Timers.Objects[Timer]);
    if T <> nil then begin
      if T.Count = 0 then ClkStart(T.Clk);
      Inc(T.Count);
    end;
  end;
end;

procedure TimerStop(Timer: Integer);
var
  T: PTimer;
begin
  if Timers <> nil then begin
    T := PTimer(Timers.Objects[Timer]);
    if T <> nil then begin
      Dec(T.Count);
      if T.Count < 0 then T.Count := 0;
      if T.Count = 0 then ClkStop(T.Clk);
    end;
  end;
end;

procedure TimerResetAll;
var
  I: Integer;
  T: PTimer;
begin
  if Timers <> nil then begin
    for I := 0 to Timers.Count - 1 do begin
      T := PTimer(Timers.Objects[I]);
      if T <> nil then begin
        T.Count := 0;
        ClkReset(T.Clk);
      end;
    end;
  end;
end;

function TimerGet(Timer: Integer): Double;
var
  T: PTimer;
begin
  if Timers <> nil then begin
    T := PTimer(Timers.Objects[Timer]);
    if T <> nil then Result := ClkGet(T.Clk) else Result := 0;
  end else Result := 0;
end;

procedure TimersListGet(List: TStringList; const Sep: string);
var
  I: Integer;
  T: PTimer;
  F: Extended;
begin
  List.Clear;
  if Timers <> nil then begin
    for I := 0 to Timers.Count - 1 do begin
      T := PTimer(Timers.Objects[I]);
      if T <> nil then begin
        F := ClkGet(T.Clk);
        if F > 0 then
          List.Add(Format('%.5f: %s%s', [F, Timers[I], Sep]));
      end;
    end;
  end;
end;

initialization
  CpuClockInit;
finalization
  Timers.Free;
end.

