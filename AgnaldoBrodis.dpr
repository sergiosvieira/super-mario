program AgnaldoBrodis;

uses
  Forms,
  UMain in 'UMain.pas' {FmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Agnaldo Brodis Full Edition - sergiosvieira@hotmail.com';
  Application.CreateForm(TFmMain, FmMain);
  Application.Run;
end.
