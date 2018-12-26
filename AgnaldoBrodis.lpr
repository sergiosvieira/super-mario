program AgnaldoBrodis;

{$MODE Delphi}
{$ASMMODE INTEL}
uses
  Forms, Interfaces,
  UMain in 'UMain.pas' {FmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Agnaldo Brodis Full Edition - sergiosvieira@hotmail.com';
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
