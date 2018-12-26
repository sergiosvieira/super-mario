unit uMapa;

{$MODE Delphi}

interface

uses LCLIntf, LCLType, LMessages,Classes,Graphics,Grids, SysUtils, Types, MMSystem;

type
  THeader = record
    l,c,s: integer;
    sprcount: integer;
  end;
  TSprite = record
    Idx: integer;
    Img, Mas, ImgMas: TBitmap
  end;
  TCano = record
    Sentido: byte; //0: BAIXO 1:CIMA
    Link_Fase: string;
  end;
  TDeclive = record
    Tipo: byte; //1: 45° 2: 30°
  end;
  TFrames = record
    Atual, Inicial, Final: integer;
  end;
  TTipo = (nenhum, emcima, escada, bloco_moeda, bloco_cogumelo, mola, cano);
  TBloco = record
    {
    DEFINIÇÕES DO TIPO
      0: N SOLIDO 1: SOLIDO 2: CANO/BAIXO/SOLIDO 3: CANO/CIMA/SOLIDO
      4: SUBIDA 45°/N SOLIDO/LINK_FASE 5: DESCIDA 45°/N SOLIDO/LINK_FASE
      6: ANIMADO/SOLIDO/QUADRO_INICIAL/QUADRO_FINAL
      7: ANIMADO/N SOLIDO/QUADRO_INICIAL/QUADRO_FINAL
      8: SÓLIDO EM CIMA 9: ESCADA/N SOLIDO 10: BLOCO "?" 11: BLOCO MOLA
      12: MOLA 13: FIM DA FASE
    }
    Solido: boolean;
    Visivel: boolean;
    Tipo: TTipo;
    Declive: TDeclive;
    Frame: TFrames;
    Sprite: Integer;
    Rect: TRect;
    offsetx, offsety: integer;
    Tempo: single;
  end;

  ptBloco = ^TBloco;
  TMapa = class
  private
    Cabeca : THeader;
    FImg: TBitmap;
    FMas: TBitmap;
    FImgMas: TBitmap;
    FSize: integer;//tamanho do bloco
    //Tempo: single;
    Taxa: single;
  public
    FCache: array[0..678] of TBitmap;
    FCache_: array[0..678] of TBitmap;

    Blocos: array of TBloco;
    offx, offy: integer;
    constructor Create;
    destructor Destroy;
    function Bloco(c,l: integer): TBloco;
    function pBloco(c,l: integer): ptBloco;
    procedure setBloco(c, l, sprite, offx, offy: integer; Tipo: TTipo);
    procedure Salvar(Arquivo: string);overload;
    procedure Salvar(Arquivo: string; arBlocos: array of TBloco; Linhas, Colunas: integer);overload;
    procedure Carregar(Arquivo: string); overload;
    procedure Carregar_Editor(Arquivo: string);
//    procedure Carregar(Arquivo: string; var arBlocos: array of TBloco); overload;
    procedure Desenhar(Buffer: TBitmap; x1, x2, DeslX,DeslY: integer);
    procedure Desenhar_Intervalo(Buffer: TBitmap; Tamanho_Bloco: integer; Coluna_Inicial, Coluna_Final: integer);
    //procedure SalvarGrade(Grade: TStringGrid; Imagem: TBitmap; Tamanho_Bloco: integer);
    //procedure CarregarGrade(Grade: TStringGrid);
    procedure PintadeAzul;
    procedure PintardePreto;
    procedure PintardeBranco;
    procedure MarcaQuadrado(x,y,cor: integer);
    procedure CarregarImgs(ArquivoImagem: string; offcolor: TColor);
    procedure CopiarPara(var b: array of TBloco);
    property Col: integer read Cabeca.c;
    property Lin: integer read Cabeca.l;
  end;

  function eax_(a,b:integer;colunas:integer):integer;
  function ah_(valor: integer;colunas:integer):integer;
  function al_(valor: integer;colunas:integer):integer;

implementation
{
function TDS( tipo, declive: byte; sprite: word): LongWord;
begin
  result:= ( tipo or (declive shl 8) or (sprite shl 16) );
end;

function getTipo( tsd_: longword ): byte;
begin
  result:= byte(tsd_);
end;

function getSprite( tsd_: longword ): longword;
begin
  result:= longword(tsd_ shr 16);
end;

function getDeclive( tsd_: longword ): byte;
begin
  result:= byte(tsd_ shr 8);
end;
}

function eax_(a,b:integer;colunas:integer):integer;
begin
  result:= (a*colunas) + b;
end;

function ah_(valor: integer;colunas:integer):integer;
begin
  result:= valor div colunas;
end;

function al_(valor: integer;colunas:integer):integer;
begin
  result:= valor mod colunas;
end;


{ TMapa }
{
procedure TMapa.SalvarGrade(Grade: TStringGrid; Imagem: TBitmap; Tamanho_Bloco: integer);
var
  i,j,t,x,y: integer;
  l,c: integer;
  ti, sp, de: integer;
  count: integer;
  achou: boolean;
begin
  count:= 0;
  t:= Tamanho_Bloco;
  Cabeca.l:= Grade.RowCount;
  Cabeca.c:= Grade.ColCount;
  Cabeca.s:= Cabeca.l*Cabeca.c;
  SetLength(Blocos, Cabeca.s);
  ZeroMemory(@imgBlocos[0],Sizeof(imgBlocos));
  for i:= 0 to Cabeca.s-1 do begin
    c:= i mod Grade.ColCount;
    l:= i div Grade.ColCount;
    ti:= getTipo(StrtoInt(Grade.Cells[c,l]));
    sp:= getSprite(StrtoInt(Grade.Cells[c,l]));
    de:= getDeclive(StrtoInt(Grade.Cells[c,l]));
    Blocos[i].Rect   := Rect(c * t,l * t,c * t + t, l * t + t);
    Blocos[i].Tipo   := ti;
    Blocos[i].Slop   := de;
    Blocos[i].offsetx:= 0;
    Blocos[i].offsety:= 0;

    for j:= 0 to count do
      if( imgBlocos[j].Idx = sp )and( sp <> 0 )then
        achou:= true;

    if( not achou )then begin
      imgBlocos[count].Idx:= sp;
      imgBlocos[count].Img:= TBitmap.Create;
      imgBlocos[count].Img.Width := FSize;
      imgBlocos[count].Img.Height:= FSize;
      c:= sp mod (Imagem.Width div FSize);
      l:= sp div (Imagem.Width div FSize);
      Blocos[i].Sprite := count;
      StretchBlt(imgBlocos[count].Img.Canvas.Handle,0,0,FSize,Fsize,
        Imagem.Canvas.Handle, c*FSize, l*FSize, FSize, FSize, SRCCOPY);
      inc(count);
    end;
    //ShowMessage(Format('i: %d, c: %d, l: %d, valor: %d',[i,c,l,FBlocos[i]]));
  end;
  Cabeca.sprcount:= Count;
end;

procedure TMapa.CarregarGrade(Grade: TStringGrid);
var
  l,c: integer;
  i: integer;
  v: dword;
  ah, al: integer;
begin
  Grade.RowCount:= Cabeca.l;
  Grade.ColCount:= Cabeca.c;
  for i:= 0 to Cabeca.s-1 do begin
    c:= i mod Cabeca.c;
    l:= i div Cabeca.c;
    v:= TDS(Blocos[i].Tipo,Blocos[i].Slop, Blocos[i].Sprite);
    Grade.cells[c,l]:= inttoStr(v);
  end;
end;
}
procedure TMapa.Carregar(Arquivo: string);
var
  ms: TMemoryStream;
  i,j,b,px,py: integer;
  index: integer;
begin
  ms:= TMemoryStream.Create;
  ms.LoadFromFile(Arquivo);
  ms.ReadBuffer(Cabeca,sizeof(THeader));
  SetLength(Blocos,Cabeca.s);
  ms.ReadBuffer(Blocos[0],Cabeca.s*sizeof(TBloco));
  ms.Free;
  for i:= 0 to Cabeca.s-1 do begin
    if( Blocos[i].Sprite <> 0 )then begin
        b:= Blocos[i].Sprite;
        index:= Blocos[i].Frame.Inicial;
        if( Blocos[i].Frame.Inicial <> Blocos[i].Frame.Final )then begin
          for j:= Blocos[i].Frame.Inicial to Blocos[i].Frame.Final do begin
            b:= index;
            if( not Assigned( FCache[b] ) )then begin
              FCache[b]:= TBitmap.Create;
              FCache[b].Width:= 32;
              FCache[b].Height:= 32;

              px:= b mod (FImg.Width div 32);
              py:= b div (FImg.Width div 32);

              StretchBlt( FCache[b].Canvas.Handle, 0, 0, 32, 32,
                FImgMas.Canvas.Handle, px * 32, py * 32,
                32, 32, SRCAND );

              FCache_[b]:= TBitmap.Create;
              FCache_[b].Width:= 32;
              FCache_[b].Height:= 32;


              StretchBlt( FCache_[b].Canvas.Handle, 0, 0, 32, 32,
                FMas.Canvas.Handle, px * 32, py * 32,
                32, 32, SRCAND );
              Inc(Index);
            end;
          end;
        end else
        if( not Assigned( FCache[b] ) )then begin
          FCache[b]:= TBitmap.Create;
          FCache[b].Width:= 32;
          FCache[b].Height:= 32;

          px:= b mod (FImg.Width div 32);
          py:= b div (FImg.Width div 32);

          StretchBlt( FCache[b].Canvas.Handle, 0, 0, 32, 32,
            FImgMas.Canvas.Handle, px * 32, py * 32,
            32, 32, SRCAND );

          FCache_[b]:= TBitmap.Create;
          FCache_[b].Width:= 32;
          FCache_[b].Height:= 32;


          StretchBlt( FCache_[b].Canvas.Handle, 0, 0, 32, 32,
             FMas.Canvas.Handle, px * 32, py * 32,
             32, 32, SRCAND );
        end;
    end;
  end;
{
  for i:= 0 to Cabeca.s-1 do begin
    //if( Assigned(FCache[i]) )then Exit;
    if( Blocos[i].Frame.Inicial <> Blocos[i].Frame.Final )then begin

      for j:= Blocos[i].Frame.Inicial to Blocos[i].Frame.Final do begin
        b:= Blocos[i].Frame.Inicial + index;

        FCache[b]:= TBitmap.Create;
        FCache[b].Width:= 32;
        FCache[b].Height:= 32;

        px:= b mod (FImg.Width div 32);
        py:= b div (FImg.Width div 32);

        StretchBlt( FCache[b].Canvas.Handle, 0, 0, 32, 32,
          FImgMas.Canvas.Handle, px * 32, py * 32,
          32, 32, SRCAND );

        FCache_[b]:= TBitmap.Create;
        FCache_[b].Width:= 32;
        FCache_[b].Height:= 32;


        StretchBlt( FCache_[b].Canvas.Handle, 0, 0, 32, 32,
         FMas.Canvas.Handle, px * 32, py * 32,
         32, 32, SRCAND );
        index:= index + 1;
      end;
    end else begin
      b:= Blocos[i].Sprite;
      if( b <> 0 )then begin
        FCache[b]:= TBitmap.Create;
        FCache[b].Width:= 32;
        FCache[b].Height:= 32;

        px:= b mod (FImg.Width div 32);
        py:= b div (FImg.Width div 32);

        StretchBlt( FCache[b].Canvas.Handle, 0, 0, 32, 32,
          FImgMas.Canvas.Handle, px * 32, py * 32,
          32, 32, SRCAND );

        FCache_[b]:= TBitmap.Create;
        FCache_[b].Width:= 32;
        FCache_[b].Height:= 32;


        StretchBlt( FCache_[b].Canvas.Handle, 0, 0, 32, 32,
         FMas.Canvas.Handle, px * 32, py * 32,
         32, 32, SRCAND );
      end;
    end;

  end;
}

end;

procedure TMapa.Salvar(Arquivo: string);
var
  ms: TMemoryStream;
  i: integer;
begin
  if(Assigned(Blocos))then begin
    ms:= TMemoryStream.Create;
    ms.WriteBuffer(Cabeca,Sizeof(THeader));
    ms.WriteBuffer(Blocos[0],Cabeca.s*sizeof(TBloco));
    ms.SaveToFile(Arquivo);
    ms.Free;
  end;
end;


procedure TMapa.Desenhar;
var
  i, t, j: integer;
  r: trect;
  c, l, b, px, py: integer;
  x, y: integer;
  pB: ptBloco;
begin
  t:= 32;
  r.Left:= 0; r.Top:= 0;
  r.Right := 320;
  r.Bottom:= 272;
  Buffer.Canvas.Brush.Color:= clSkyBlue;
  //Buffer.Canvas.FillRect( r );

  for y:= 0 to Lin-1 do
    for x:= x1 to x2 do begin
      //b:= Blocos[y*Cabeca.c+x].Sprite;
      pb:= @Blocos[y*Col+x];
      if( pb.Visivel )then
      if( pb.Sprite <> 0 )then begin
        if( pb.Frame.Inicial <> pb.Frame.Final )then begin
          b:= pb.Frame.Atual;
          if( GetTickCount { *Convertido de TimeGetTime* }- pb.Tempo > Taxa )then begin
            pb.Frame.Atual:= pb.Frame.Atual + 1;
            pb.Tempo:= GetTickCount; { *Convertido de TimeGetTime* }
          end;
          if( b > pb.Frame.Final )then begin
            b:= pb.Frame.Inicial;
            pb.Frame.Atual:= b;
          end;
        end else b:= pb.Sprite;
      if( Assigned( FCache[b] ) )then begin
          Bitblt(Buffer.Canvas.handle,((X - X1) * 32) + DeslX,y*32-pb.offsety,
            32, 32, FCache_[b].Canvas.Handle,0,0, SRCAND );
          Bitblt(Buffer.Canvas.handle,((X - X1) * 32) + DeslX,y*32-pb.offsety,
            32, 32, FCache[b].Canvas.Handle,0,0, SRCINVERT );
          buffer.Canvas.TextOut(((X - X1) * 32) + DeslX,y*32,InttoStr(pb.offsety));
      end;
    end;
  end;
  Buffer.Canvas.Brush.Color:= clWhite;
end;

function TMapa.Bloco(c, l: integer): TBloco;
begin
  if(c<0)or(l<0)or(c>Cabeca.c)or(l>Cabeca.l)then exit;
  with Blocos[l*Cabeca.c+c].Rect do begin
    Left  := Left  - Blocos[l*Cabeca.c+c].offsetx;
    Right := Right - Blocos[l*Cabeca.c+c].offsetx;
    Top   := Top  - Blocos[l*Cabeca.c+c].offsety;
    Bottom:= Bottom - Blocos[l*Cabeca.c+c].offsety;
  end;
  result:= Blocos[l*Cabeca.c+c];
end;

procedure TMapa.setBloco(c, l, sprite, offx, offy: integer; Tipo: TTipo);
begin
  if(c<0)or(l<0)or(c>Cabeca.c)or(l>Cabeca.l)then exit;
  if(tipo<>nenhum)then
    Blocos[l*Cabeca.c+c].Tipo  := tipo;
  if(sprite<>-1)then
    Blocos[l*Cabeca.c+c].Sprite:= sprite;
  if(offx<>-1)then
    Blocos[l*Cabeca.c+c].offsetx:= offx;
  if(offy<>-1)then
    Blocos[l*Cabeca.c+c].offsety:= offx;
end;

//function pintadeazul(quadrados,Xmax,Ymax)
//	{
//	for x = 0 to Xmax do
//		{
//		if (quadrados[x,0] == branco)
//			marcaquadrado(quadrados,x,0)
//		if (quadrados[x,Ymax] == branco)
//			marcaquadrado(quadrados,x,Ymax)
//		}
//	for y = 0 to Ymax do
//		{
//		if (quadrados[0,y] == branco)
//			marcaquadrado(quadrados,0,y)
//		if (quadrados[Xmax,y] == branco)
//			marcaquadrado(quadrados,Xmax,y)
//		}
//	}
procedure TMapa.PintadeAzul;
var
  x, y: integer;
begin
{
  for x:= 0 to Cabeca.c-1 do begin
    if(Bloco(x,0).Tipo=2)then
      MarcaQuadrado(x,0,3);
    if(Bloco(x,Cabeca.l-1).Tipo=2)then
      MarcaQuadrado(x,Cabeca.l-1,3);
  end;
  PintardePreto;
  PintardeBranco;

  for y:= 0 to Cabeca.l-1 do begin
    if(Bloco(0,y).Tipo=2)then
      MarcaQuadrado(0,y,3);
    if(Bloco(Cabeca.c-1,y).tipo=2)then
      MarcaQuadrado(Cabeca.c-1,y,3);
  end;
}
end;


//function marcaquadrado(quadrados,px,py)
//	{
//	quadrados[px,py].color = azul;
//	if (quadrados[px+1,py] == branco)
//		marcaquadrado(quadrados,px+1,py);
//	if (quadrados[px-1,py] == branco)
//		marcaquadrado(quadrados,px-1,py);
//	if (quadrados[px,py+1] == branco)
//		marcaquadrado(quadrados,px,py+1);
//	if (quadrados[px,py-1] == branco)
//		marcaquadrado(quadrados,px,py-1);
//	}

procedure TMapa.MarcaQuadrado(x, y, cor: integer);
begin
{
  if(x<0)then exit;
  if(y<0)then exit;
  setBloco(x,y,cor,-1,-1,-1);
  if(Bloco(x+1,y).Tipo=2)then
    MarcaQuadrado(x+1,y,cor);
  if(Bloco(x-1,y).Tipo=2)then
    MarcaQuadrado(x-1,y,cor);
  if(Bloco(x,y+1).Tipo=2)then
    MarcaQuadrado(x,y+1,cor);
  if(Bloco(x,y-1).Tipo=2)then
    MarcaQuadrado(x,y-1,cor);
}
end;

procedure TMapa.PintardeBranco;
var
  x, y: integer;
begin
{
  for x:= 0 to Cabeca.c-1 do
    for y:= 0 to Cabeca.l-1 do
      if(Bloco(x,y).Tipo=3)then
        setBloco(x,y,2,-1,-1,-1);
}
end;

procedure TMapa.PintardePreto;
var
  x, y: integer;
begin
{
  for x:= 0 to Cabeca.c-1 do
    for y:= 0 to Cabeca.l-1 do
      if(Bloco(x,y).Tipo=2)then
        SetBloco(x,y,1,-1,-1,-1);
}
end;

constructor TMapa.Create;
begin
  offx:= 0; offy:= 0;
  FSize:= 32;
  Taxa:= 100;
end;

procedure TMapa.CarregarImgs(ArquivoImagem: string; offcolor: TColor);
begin

  FImg:= TBitmap.Create;
  FImg.LoadFromFile(ArquivoImagem);

  FMas:= TBitmap.Create;
  FMas.Assign(FImg);
  FMas.Mask(offcolor);

  FImgMas:= TBitmap.Create;
  FImgMas.Assign(FImg);
  FImgMas.Canvas.Draw(0,0,FMas);
  Bitblt(FImgMas.canvas.handle,0,0,FImg.Width, FImg.Height, FImg.canvas.handle,
    0, 0, SRCERASE);

end;


procedure TMapa.Desenhar_Intervalo(Buffer: TBitmap; Tamanho_Bloco,
  Coluna_Inicial, Coluna_Final: integer);
var
  i, t, j: integer;
  r: trect;
  c, l, b, px, py: integer;
begin
  t:= Tamanho_Bloco;
  r.Left:= 0; r.Top:= 0;
  r.Right := t * Cabeca.c;
  r.Bottom:= t * Cabeca.l;
  Buffer.Canvas.Brush.Color:= clSkyBlue;
  //Buffer.Canvas.FillRect( r );
  for i:= 0 to Cabeca.s-1 do begin
    c:= (i mod Cabeca.c);
    l:= (i div Cabeca.c);

    if(Blocos[i].Sprite <> 0 )then
    if( c in [Coluna_Inicial..Coluna_Final]) then begin

      if( Blocos[i].Frame.Inicial <> Blocos[i].Frame.Final )then begin
        b:= Blocos[i].Frame.Atual;
        if( GetTickCount { *Convertido de TimeGetTime* }- Blocos[i].Tempo > Taxa )then begin
          Blocos[i].Frame.Atual:= Blocos[i].Frame.Atual + 1;
          Blocos[i].Tempo:= GetTickCount; { *Convertido de TimeGetTime* }
        end;
        if( b > Blocos[i].Frame.Final )then begin
          b:= Blocos[i].Frame.Inicial;
          Blocos[i].Frame.Atual:= b;
        end;
      end else b:= Blocos[i].Sprite;


      //px:= b mod (FImg.Width div t);
      //py:= b div (FImg.Width div t);
    if( Assigned( FCache[b] ) )then begin
      Bitblt(Buffer.Canvas.handle,c*t-offx-Blocos[i].offsetx,l*t-offy-Blocos[i].offsety,
        32, 32, FCache_[b].Canvas.Handle,0,0, SRCAND );

      Bitblt(Buffer.Canvas.handle,c*t-offx-Blocos[i].offsetx,l*t-offy-Blocos[i].offsety,
        32, 32, FCache[b].Canvas.Handle,0,0, SRCINVERT );

    end;
    end;
  end;
end;

function TMapa.pBloco(c, l: integer): ptBloco;
begin
  if(c<0)or(l<0)or(c>Cabeca.c)or(l>Cabeca.l)then exit;
  result:= @Blocos[l*Cabeca.c+c];
end;

procedure TMapa.Salvar(Arquivo: string; arBlocos: array of TBloco; Linhas, Colunas: integer);
var
  size: integer;
  i: integer;
begin
  size:= High(arBlocos)+1;
  SetLength(Blocos,Size);
  for i:= 0 to size-1 do
    Blocos[i]:= arBlocos[i];
  Cabeca.l:= Linhas; Cabeca.c:= Colunas;
  Cabeca.s:= Size;
  Salvar(Arquivo);
end;
{
procedure TMapa.Carregar(Arquivo: string; var arBlocos: array of TBloco);
var
  i: integer;
begin
  Carregar(Arquivo);
//  SetLength(arBlocos,Cabeca.s);
  for i:= 0 to Cabeca.s-1 do
    arBlocos[i]:= Blocos[i];

end;
}
procedure TMapa.CopiarPara(var b: array of TBloco);
var i: integer;
begin
  for i:= 0 to Cabeca.s-1 do
    b[i]:= Blocos[i];
//  CopyMemory(@b, @Blocos, Cabeca.s * Sizeof(TBloco));
end;

procedure TMapa.Carregar_Editor(Arquivo: string);
var
  ms: TMemoryStream;
  i,j,b,px,py: integer;
  index: integer;
begin
  index:= 0;
  ms:= TMemoryStream.Create;
  ms.LoadFromFile(Arquivo);
  ms.ReadBuffer(Cabeca,sizeof(THeader));
  SetLength(Blocos,Cabeca.s);
  ms.ReadBuffer(Blocos[0],Cabeca.s*sizeof(TBloco));
  ms.Free;
end;


destructor TMapa.Destroy;
var i: integer;
begin
  for i:= 0 to 678 do
    if( Assigned(FCache[i] ) )then begin
      FreeAndNil(FCache[i]);
      FreeAndNil(FCache_[i]);
    end;
  FreeAndNil(FImg);
  FreeAndNil(FMas);
  FreeAndNil(FImgMas);
  inherited destroy;
end;

end.
