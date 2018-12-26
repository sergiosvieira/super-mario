unit uObjeto;

{$MODE Delphi}

interface

uses LCLIntf, LCLType, LMessages, Graphics;

type
  TFrame = record
    Atual, Inicial, Final: integer;
    Largura, Altura: integer;
    Taxa: single;
  end;

  TObjeto = class
  private
    bmp: TBitmap;
    bmp_mascara: TBitmap;
    mascara: TBitmap;
    ftempo_movimento: single;
  protected
    fbuffer: TCanvas;
  public
    x, y: integer;
    ox, oy: integer;
    Quadro: TFrame;
    Taxa_Movimento: single;
    Visivel: boolean;
    Auto_Anime: boolean;
    tempo_animacao: single;
    constructor Create(bitmap: string; buffer: TCanvas; offcolor: TColor);
      overload; virtual;
    constructor Create(bitmap: TBitmap; buffer: TCanvas; offcolor: TColor);
      overload; virtual;
    procedure AjustarQuadros(Atual, Inicial, Final, Largura, Altura: integer;
      Taxa: single);
    procedure Desenhar(posx, posy: integer); virtual;
    procedure Teclado; virtual;
  end;


implementation

{ TObjeto }

constructor TObjeto.Create(bitmap: string; buffer: TCanvas; offcolor: TColor);
begin
  Visivel := True;
  Auto_Anime := False;
  bmp := TBitmap.Create;
  bmp.LoadFromFile(bitmap);

  mascara := TBitmap.Create;
  mascara.Assign(bmp);
  mascara.Mask(offcolor);

  bmp_mascara := TBitmap.Create;
  bmp_mascara.Assign(bmp);
  bmp_mascara.Canvas.Draw(0, 0, mascara);
  bitblt(bmp_mascara.Canvas.Handle, 0, 0, bmp.Width, bmp.Height,
    bmp.Canvas.Handle, 0, 0, SRCERASE);

  x := 0;
  y := 0;
  ox := 0;
  oy := 0;
  fbuffer := buffer;
  Quadro.Atual := 0;
  Quadro.Inicial := 0;
  Quadro.Final := 0;
  Quadro.Largura := bmp.Width;
  Quadro.Altura := bmp.Height;
  Taxa_Movimento := 0.01;
  ftempo_movimento := GetTickCount;
  tempo_animacao := 0;
end;

procedure TObjeto.AjustarQuadros(Atual, Inicial, Final, Largura, Altura: integer;
  Taxa: single);
begin
  Quadro.Atual := Atual;
  Quadro.Inicial := Inicial;
  Quadro.Final := Final;
  Quadro.Largura := Largura;
  Quadro.Altura := Altura;
  Quadro.Taxa := Taxa;
end;

constructor TObjeto.Create(bitmap: TBitmap; buffer: TCanvas; offcolor: TColor);
begin
  Auto_Anime := False;
  visivel := True;
  bmp := TBitmap.Create;
  bmp.Assign(bitmap);

  mascara := TBitmap.Create;
  mascara.Assign(bmp);
  mascara.Mask(offcolor);

  bmp_mascara := TBitmap.Create;
  bmp_mascara.Assign(bmp);
  bmp_mascara.Canvas.Draw(0, 0, mascara);
  bitblt(bmp_mascara.Canvas.Handle, 0, 0, bmp.Width, bmp.Height,
    bmp.Canvas.Handle, 0, 0, SRCERASE);

  x := 0;
  y := 0;
  ox := 0;
  oy := 0;
  fbuffer := buffer;
  Quadro.Atual := 0;
  Quadro.Inicial := 0;
  Quadro.Final := 0;
  Quadro.Largura := bmp.Width;
  Quadro.Altura := bmp.Height;
  Quadro.Taxa := 1;
  Taxa_Movimento := 0.01;
  ftempo_movimento := GetTickCount;
  tempo_animacao := 0;
end;

procedure TObjeto.Desenhar;
var
  px, py: integer;
begin
  if (Auto_Anime) then
    Quadro.Atual := Quadro.Atual + 1;
  if (Quadro.Atual > Quadro.Final) then
    Quadro.Atual := Quadro.Inicial;
  px := Quadro.Atual mod (bmp.Width div Quadro.Largura);
  py := Quadro.Atual div (bmp.Width div Quadro.Largura);
  if (not Visivel) then
    exit;
  StretchBlt(fbuffer.Handle, posx - ox, posy - oy, Quadro.Largura, Quadro.Altura,
    mascara.Canvas.Handle, px * Quadro.Largura, py * Quadro.Altura,
    Quadro.Largura, Quadro.Altura, SRCAND);
  StretchBlt(fbuffer.Handle, posx - ox, posy - oy, Quadro.Largura, Quadro.Altura,
    bmp_mascara.Canvas.Handle, px * Quadro.Largura, py * Quadro.Altura,
    Quadro.Largura, Quadro.Altura, SRCINVERT);
  {
  bitblt( fbuffer.Handle, x, y, bmp.Width, bmp.Height,
    mascara.Canvas.Handle, 0, 0, SRCAND );
  bitblt( fbuffer.Handle, x, y, bmp.Width, bmp.Height,
    bmp_mascara.Canvas.Handle, 0, 0, SRCINVERT );
  }
end;


procedure TObjeto.Teclado;
begin

end;

end.
