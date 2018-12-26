{
  PROGRAMANDO JOGOS - AGNALDO BRODIS COMPLETO - 2005
  AUTOR: ANTONIO SÉRGIO DE SOUSA VIEIRA 2002 - 2005
  AGRADECIMENTOS: FABRÍCIO CATAE / KLAUS / MELFICE (PELO INCENTIVO A CONTINUAR O JOGO)
  BRASIL - FORTALEZA - CE
  http://www15.brinkster.com/djddelphi
}

unit UMain;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, uMapa, MMSystem, uObjeto, Commandos{fmod, fmodtypes}, u_Timer;

type
  TFmMain = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FmMain: TFmMain;

//definições do jogo
type
  TCoordenada = Record
    x,y: Integer;
  end;

  TSentidoX = (Esquerda,Direita,Parado);
  TSentidoY = (Cima,Baixo);

  TCoins = class(TObjeto)
  private
  public
    Valor: integer;
    velo_inicial: integer;
  end;

  TCogumelo= class(TObjeto)
  private
    SentidoX: TSentidoX;
    SentidoY: TSentidoY;
    a,b,c,d: TCoordenada;
  public
    aceleracao: single;
    velocidade: integer;
    procedure Mover_cogumelo;
    procedure Detectar_Bloco(x_, y_: integer; pBloco: ptBloco);
  end;

  TAgnaldo = class(TObjeto)
  private
    a,b,c,d: TCoordenada;
    osx, osy: TSentidoX;
    function Ponto( x_, y_: integer): TCoordenada;
  public
    SentidoX: TSentidoX;
    SentidoY: TSentidoY;
    Pulo: Boolean;
    Veloc: Integer;
    Acele: single;
    Solido: boolean;
    Descendo_Cano: boolean;
    Controle: TControle;
    VelocX, AceleX: Single;
    ScrX, ScrY: integer;
    Correndo: boolean;
    constructor create( bitmap: TBitmap; buffer: TCanvas; offcolor: TColor ); override;
    procedure ChecarPulo;
    procedure Pular;
    procedure Detectar_Bloco(x_, y_: integer; pBloco: ptBloco);
    procedure Mover(velocidade: integer);
    procedure Checar_Teclado;
    procedure Desenhar(px, py: integer); override;
    procedure Ajustar_Quadros;
    procedure Cabecadas(pBloco: ptBloco);
  end;

  TEstado = (logo1, logo2, menu, opcoes, mudar_fase, fase, game_over );
  TJogo = record
    Pontos: integer;
    Vidas: integer;
    Estado: TEstado;
    Tempo: single;
    Fase_Atual: string;
    Mapa: TMapa;
    Taxa: single; //taxa de velocidade do jogo
    buffer: tbitmap;
    background: tbitmap;
    Largura, Altura: integer;
    Fps: integer;
    Path: string;
    Debug: boolean;
    // Novidade
    FCenX: integer;
    DeslX: integer;
    CMaxX: Single;
    //Ponteiro para Sons e Musica
    pMusica, pPulo, pCano, pMoeda: Pointer;
    //Comportamento dos objetos do mapa
    pBloco: ptBloco; //usado do bloco que o boneco estiver dando cabeçada
    pMoedas: array[1..3] of TCoins;
    Cogumelo: TCogumelo;
    velo_inicial: integer; // movimento do bloco "?"
  end;

//constantes
const
  TAM = 32; //tamanho do Agnaldo

//variáveis globais de controle do jogo
var
  Jogo: TJogo;
  Agnaldo: TAgnaldo;
  cx, cy: integer; //centro do mapa

implementation

uses Types;

{$R *.lfm}

//controle do jogo
procedure Iniciar_Jogo( Estado: TEstado; Fase_Atual: string );
begin
  Jogo.Largura:= FmMain.ClientWidth;
  Jogo.Altura := FmMain.ClientHeight;
  Jogo.Pontos:= 0;
  Jogo.Vidas := 3;
  Jogo.Estado:= Estado;
  Jogo.Tempo:= GetTickCount; { *Convertido de TimeGetTime* }
  Jogo.Fase_Atual:= Fase_Atual;
  Jogo.Mapa:= TMapa.Create;
  Jogo.Path:= GetCurrentDir;
  Jogo.Debug:= true;
  Jogo.Mapa.CarregarImgs(Jogo.Path + '\gfx\Blocos.Bmp',clFuchsia);
  Jogo.Mapa.Carregar(Jogo.Fase_Atual);
  Jogo.Taxa:= 15;// quando maior mais lento o jogo fica
  Jogo.buffer:= tbitmap.Create;
  Jogo.buffer.Width := TAM * Jogo.Mapa.Col;
  Jogo.buffer.Height:= TAM * Jogo.Mapa.Lin;
  Jogo.background:= TBitmap.Create;
  Jogo.background.LoadFromFile(Jogo.Path + '\gfx\background.Bmp');
  Agnaldo:= TAgnaldo.create(Jogo.Path + '\gfx\Agnaldo.bmp',Jogo.buffer.Canvas,clFuchsia);
  Agnaldo.AjustarQuadros(0,0,5,32,32,0.5);
  Agnaldo.x:= 32; Agnaldo.y:= 32;
  Agnaldo.Acele:= 1;
  Agnaldo.Veloc:= 0;
  Agnaldo.Pulo:= true;
  Agnaldo.SentidoY:= baixo;
  Agnaldo.SentidoX:= Direita;
  Agnaldo.osx:= Direita;
  //NOVIDADE
  Jogo.FCenX:= (Jogo.Mapa.Col * TAM div 2) - (Jogo.Largura div 2);
  Jogo.DeslX:= 0;
  Jogo.CMaxX:= (Jogo.Mapa.Col * TAM) / 320 * 10;
  //CONTROLE DOS BLOCOS "?"
  Jogo.velo_inicial:= 0;
end;

procedure Iniciar_Sons;
begin
  //FSOUND_Init(44100,32,0);
  //Jogo.pMusica:= FMUSIC_LoadSong(PChar(Jogo.Path + '\sfx\fase1.mid'));
  //FMUSIC_SetLooping(Jogo.pMusica, true);
  //FMUSIC_SetMasterVolume(Jogo.pMusica,128);
  //FMUSIC_PlaySong(Jogo.pMusica);
  //Jogo.pPulo:= FSOUND_Sample_Load(FSOUND_FREE, PChar(Jogo.Path + '\sfx\jump.wav'),FSOUND_2D,0,0);
  //Jogo.pMoeda:= FSOUND_Sample_Load(FSOUND_FREE, PChar(Jogo.Path + '\sfx\coin.wav'),FSOUND_2D,0,0);
end;

procedure Carregar_Fase( Fase: string );
begin
  if( Assigned(Jogo.Mapa) )then
    Jogo.Mapa.Carregar( Fase )
  else
    ShowMessage('Erro. Objeto Mapa não foi instanciado.');
end;

procedure Finalizar_Jogo;
begin
  FreeAndNil(Jogo.buffer);
  FreeAndNil(Jogo.background);
end;

procedure Debug;
var
  tx, ty: integer;
begin
{
  Jogo.buffer.Canvas.TextOut(1,0,'CentroX: ' + InttoStr(Jogo.FCenX));
  Jogo.buffer.Canvas.TextOut(1,15,'DeslocamentoX:' + InttoStr(Jogo.DeslX));
  Jogo.buffer.Canvas.TextOut(1,30,'Sprite:' + InttoStr(Agnaldo.Quadro.Atual));

  if(not Jogo.debug )then exit;
  Jogo.buffer.Canvas.TextOut(1,20,'Pulando: ' + InttoStr(Ord(Agnaldo.Pulo)));
  if( Agnaldo.SentidoX = parado )then
    Jogo.buffer.Canvas.TextOut(1,35,'SentidoX: PARADO');
  if( Agnaldo.SentidoX = esquerda )then
    Jogo.buffer.Canvas.TextOut(1,35,'SentidoX: ESQUERDA');
  if( Agnaldo.SentidoX = direita )then
    Jogo.buffer.Canvas.TextOut(1,35,'SentidoX: DIREITA');
  if( Agnaldo.SentidoY = Cima )then
    Jogo.buffer.Canvas.TextOut(1,50,'SentidoY: CIMA');
  if( Agnaldo.SentidoY = Baixo )then
    Jogo.buffer.Canvas.TextOut(1,50,'SentidoY: BAIXO');
  Jogo.buffer.Canvas.TextOut(1,65,'Velocida Pulo: ' + InttoStr(Agnaldo.Veloc));
  tx:= Agnaldo.x div TAM;
  ty:= Agnaldo.y div TAM;
  Jogo.buffer.Canvas.TextOut(1,80,Format('SPRITE EM A(%d,%d) - Solido (%d)',[tx,ty,Ord(Jogo.Mapa.Bloco(tx, ty).Solido)]));
  tx:= (Agnaldo.x + TAM) div TAM;
  ty:= Agnaldo.y div TAM;
  Jogo.buffer.Canvas.TextOut(150,80,Format('SPRITE EM B(%d,%d) - Solido (%d)',[tx,ty,Ord(Jogo.Mapa.Bloco(tx, ty).Solido)]));
  tx:= Agnaldo.x div TAM;
  ty:= (Agnaldo.y + TAM) div TAM;
  Jogo.buffer.Canvas.TextOut(1,95,Format('SPRITE EM C(%d,%d) - Solido (%d)',[tx,ty,Ord(Jogo.Mapa.Bloco(tx, ty).Solido)]));
  tx:= (Agnaldo.x + TAM) div TAM;
  ty:= (Agnaldo.y + TAM) div TAM;
  Jogo.buffer.Canvas.TextOut(150,95,Format('SPRITE EM D(%d,%d) - Solido (%d)',[tx,ty,Ord(Jogo.Mapa.Bloco(tx, ty).Solido)]));
  Jogo.buffer.Canvas.TextOut(1,110,Format('VelocidadeX (%f)',[Agnaldo.VelocX]));
}
end;

var
  tempo_fps: single = 0;// tempo para controle do FPS
  oFps: integer = 0;

procedure Mostrar_FPS(buff: tbitmap);
begin
  if( GetTickCount { *Convertido de TimeGetTime* }- tempo_fps > 1000 )then begin
    oFps:= Jogo.Fps;

    if( Jogo.Fps > 60 )then Jogo.taxa:= Jogo.Taxa + 1
    else if( Jogo.Fps < 30 )then Jogo.Taxa:= Jogo.Taxa - 1;
    if( Jogo.Taxa < 1 )then Jogo.Taxa:= 1;

    Jogo.Fps:= 0;
    tempo_fps:= GetTickCount(); { *Convertido de TimeGetTime* }
  end else begin
    buff.Canvas.TextOut(1,1,InttoStr(oFps) + ' FPS');
    inc(Jogo.Fps );
  end;
end;


procedure Ajustar_Moedas;
begin
  if( Assigned(Jogo.pMoedas[1]) )then begin
    Dec(Jogo.pMoedas[1].velo_inicial,1);
    Dec(Jogo.pMoedas[1].y,Jogo.pMoedas[1].velo_inicial);
    if( Jogo.pMoedas[1].velo_inicial < -10 )then begin
      Jogo.pMoedas[1].velo_inicial:= 0;
      Jogo.pMoedas[1].y:= 0;
      Jogo.pMoedas[1]:= nil;
    end;
  end;

  if( Assigned(Jogo.pMoedas[2]) )then begin
    Dec(Jogo.pMoedas[2].velo_inicial,1);
    Dec(Jogo.pMoedas[2].y,Jogo.pMoedas[2].velo_inicial);
    if( Jogo.pMoedas[2].velo_inicial < -10 )then begin
      Jogo.pMoedas[2].velo_inicial:= 0;
      Jogo.pMoedas[2].y:= 0;
      Jogo.pMoedas[2]:= nil;
    end;
  end;

  if( Assigned(Jogo.pMoedas[3]) )then begin
    Dec(Jogo.pMoedas[3].velo_inicial,1);
    Dec(Jogo.pMoedas[3].y,Jogo.pMoedas[3].velo_inicial);
    if( Jogo.pMoedas[3].velo_inicial < -10 )then begin
      Jogo.pMoedas[3].velo_inicial:= 0;
      Jogo.pMoedas[3].y:= 0;
      Jogo.pMoedas[3]:= nil;
    end;
  end;
end;

procedure Desenhar_Moedas;
begin
  if( Assigned(Jogo.pMoedas[1]) )then begin
    Jogo.pMoedas[1].Desenhar(Jogo.pMoedas[1].x - Jogo.FCenX,Jogo.pMoedas[1].y);
  end;
  if( Assigned(Jogo.pMoedas[2]) )then begin
    Jogo.pMoedas[2].Desenhar(Jogo.pMoedas[2].x - Jogo.FCenX,Jogo.pMoedas[2].y);
  end;
  if( Assigned(Jogo.pMoedas[3]) )then begin
    Jogo.pMoedas[3].Desenhar(Jogo.pMoedas[3].x - Jogo.FCenX,Jogo.pMoedas[3].y);
  end;
end;

procedure Desenhar_Cogumelo;
begin
  if( Assigned(Jogo.Cogumelo) )then
    Jogo.Cogumelo.Desenhar(Jogo.Cogumelo.x - Jogo.FCenX, Jogo.Cogumelo.y);
    //Jogo.Cogumelo.Desenhar(1, 1);
end;

{ TCogumelo }

procedure TCogumelo.Detectar_Bloco(x_, y_: integer; pBloco: ptBloco);
function Ponto( px, py: integer): TCoordenada;
begin
  result.x:= px;
  result.y:= py;
end;
{
  A      B
  --------
  |      |
  |      |
  |      |
  --------
  C      D
}
begin
  B:= Ponto( (x_ + TAM) div TAM, (y_) div TAM );
  D:= Ponto( (x_ + TAM) div TAM, (y_ + TAM) div TAM);

  A:= Ponto( (x_) div TAM, (y_) div TAM );
  C:= Ponto( (x_) div TAM, (y_ + TAM) div TAM);
end;

procedure TCogumelo.Mover_cogumelo;
var
  nx, ny: integer;
begin
  SentidoY:= Baixo;
  aceleracao:= 1.1;
  if( SentidoX = Direita )then begin

    nx:= x + velocidade;
    ny:= y;

    Detectar_Bloco(nx, ny,nil);
    if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then begin
      nx:= Jogo.Mapa.Bloco(B.x,B.y).Rect.Left - TAM;
      SentidoX:= Esquerda;
    end else
      if( Jogo.Mapa.Bloco(D.x,D.y).Solido )then begin
        nx:= Jogo.Mapa.Bloco(D.x,D.y).Rect.Left - TAM;
        SentidoX:= Esquerda;
      end;
    x:= nx; y:= ny;
  end else
    if( SentidoX = Esquerda )then begin

      nx:= x - velocidade;
      ny:= y;

      Detectar_Bloco(nx, ny, nil);
      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then begin
        nx:= Jogo.Mapa.Bloco(A.x,A.y).Rect.Right;
        SentidoX:= Direita;
      end else
        if( Jogo.Mapa.Bloco(C.x,C.y).Solido )then begin
          nx:= Jogo.Mapa.Bloco(C.x,C.y).Rect.Right;
          SentidoX:= Direita;
        end;
      x:= nx; y:= ny;
    end;
  if( x < 0 )then
    if( SentidoX = Esquerda )then
      SentidoX:= Direita
    else
      if( SentidoX = Direita )then
        SentidoX:= Esquerda;

  if( SentidoY = Baixo )then begin
    ny:= y + 4;
    Detectar_Bloco(x, ny, nil);
    if( Jogo.Mapa.Bloco(C.x,C.y).Solido )then begin
      ny:= Jogo.Mapa.Bloco(C.x,C.y).Rect.Top - TAM - 2;
    end else
      if( Jogo.Mapa.Bloco(D.x,D.y).Solido )then begin
        ny:= Jogo.Mapa.Bloco(C.x,C.y).Rect.Top - TAM - 2;
        aceleracao:= 0;
      end;
  end;
  y:= ny;
end;


{ TAgnaldo }

procedure TAgnaldo.Ajustar_Quadros;
var
  taxa_anim: integer;// caso esteja correndo, a animação será mais rápida
begin
  if( Correndo )then
    taxa_anim:= 5
  else
    taxa_anim:= 50;
  if( Veloc <> 0 )then begin
    if( osx = Esquerda )then
      Quadro.Atual:= 5
    else
      if( osx = Direita )then
        Quadro.Atual:= 2;
  end else begin
    if( Pulo )then exit;
    if( SentidoX = Parado )then begin
      if( osx = Direita )and(VelocX = 0)then
        Quadro.Atual:= 0
      else if( osx = Direita )then begin
        if( GetTickCount { *Convertido de TimeGetTime* }- tempo_animacao > taxa_anim )then begin
          Inc(Quadro.Atual);
          tempo_animacao:= GetTickCount; { *Convertido de TimeGetTime* }
        end;
        if( Quadro.Atual > 1 )then Quadro.Atual:= 0;
      end;

      if( osx = Esquerda )and(VelocX = 0)then
        Quadro.Atual:= 3
      else if( osx = Esquerda )then begin
        if( GetTickCount { *Convertido de TimeGetTime* }- tempo_animacao > taxa_anim )then begin
          Inc(Quadro.Atual);
          tempo_animacao:= GetTickCount; { *Convertido de TimeGetTime* }
        end;
        if( Quadro.Atual > 4 )then Quadro.Atual:= 3;
      end;
    end else begin
      if( SentidoX = Direita )then begin
        if( GetTickCount { *Convertido de TimeGetTime* }- tempo_animacao > taxa_anim )then begin
          Inc(Quadro.Atual);
          tempo_animacao:= GetTickCount; { *Convertido de TimeGetTime* }
        end;
        if( Quadro.Atual > 1 )then Quadro.Atual:= 0;
      end else
      if( SentidoX = Esquerda )then begin
        if( Quadro.Atual < 3 )then
          Quadro.Atual:= 3;
        if( GetTickCount { *Convertido de TimeGetTime* }- tempo_animacao > taxa_anim )then begin
          Inc(Quadro.Atual);
          tempo_animacao:= GetTickCount; { *Convertido de TimeGetTime* }
        end;
        if( Quadro.Atual > 4 )then Quadro.Atual:= 3;
      end;
    end;
  end;
end;

procedure TAgnaldo.Cabecadas;
var
  Coin: TCoins;
  Cogu: TCogumelo;
  i: integer;
begin

  if(pBloco.Tipo = bloco_moeda)then begin
    Jogo.pBloco:= pBloco;
    Jogo.pBloco.Sprite:= 119;
    Jogo.pBloco.Frame.Inicial:= 0;
    Jogo.pBloco.Frame.Final:= 0;
    Jogo.pBloco.Tipo:= nenhum;
    Jogo.velo_inicial:= 5;
    veloc:= 0;
    Coin:= TCoins.Create(Jogo.Path + '\gfx\coins.bmp',Jogo.buffer.canvas,clFuchsia);
    Coin.Valor:= 10;
    Coin.AjustarQuadros(0,0,3,32,32,0.5);
    Coin.Auto_Anime:= true;
    Coin.x:= Jogo.pBloco.Rect.left;
    Coin.y:= Jogo.pBloco.Rect.Top - 35;
    Coin.velo_inicial:= 10;
    for i:= 1 to 3 do
      if( not Assigned(Jogo.pMoedas[i]) )then begin
        Jogo.pMoedas[i]:= Coin;
        break;
      end;
    //FSOUND_PlaySound(1,Jogo.pMoeda);
  end;

  if(pBloco.Tipo = bloco_cogumelo )then begin
    Jogo.pBloco:= pBloco;
    Jogo.velo_inicial:= 5;
    Jogo.pBloco.Sprite:= 119; //imagem sem o "?"
    Jogo.pBloco.Frame.Inicial:= 0;
    Jogo.pBloco.Frame.Final:= 0;
    Jogo.pBloco.Tipo:= nenhum;
    Veloc:= 0;
    Cogu:= TCogumelo.Create(Jogo.Path + '\gfx\cogumelo.bmp',Jogo.buffer.canvas,clFuchsia);
    Cogu.x:= Jogo.pBloco.Rect.left;
    Cogu.y:= Jogo.pBloco.Rect.Top - TAM * 2;
    Cogu.velocidade:= 2;
    Jogo.Cogumelo:= Cogu;
    //FSOUND_PlaySound(1,Jogo.pMoeda);
  end;

end;

procedure TAgnaldo.ChecarPulo;
begin
  if( not Pulo )then
    if( GetKeyState(VK_CONTROL)<0 )then begin
      Pulo:= True;
      if( Correndo )then
        Veloc:= 16
      else
        Veloc:= 15;
      //FSOUND_PlaySound(1,Jogo.pPulo);
    end;
end;

procedure TAgnaldo.Checar_Teclado;
begin
  if( GetKeyState(vk_left)<0 )then
     SentidoX:= Esquerda
  else
     if( GetKeyState(vk_right)<0 )then
        SentidoX:= Direita
     else
        SentidoX:= Parado;
  if( not Pulo)and(Veloc=0)then// correr apenas se estiver no solo
  if( GetKeyState(VK_LSHIFT)<0 )then
    Correndo:= true
  else
    Correndo:= false;
end;

constructor TAgnaldo.create(bitmap: TBitmap; buffer: TCanvas;
  offcolor: TColor);
begin
  inherited;
  Correndo:= False;
  SentidoX:= Parado;
  SentidoY:= Baixo;
  Pulo:= False;
  Solido:= true;
  x:= 20;
  y:= 50;
  Descendo_Cano:= false;
  Veloc:= 0;
  Acele:= 1;
  VelocX:= 0;
  AceleX:= 1;
end;

procedure TAgnaldo.Desenhar(px, py: integer);
begin
  inherited;
end;

procedure TAgnaldo.Detectar_Bloco;
function Ponto( px, py: integer): TCoordenada;
begin
  result.x:= px;
  result.y:= py;
end;
{
  A      B
  --------
  |      |
  |      |
  |      |
  --------
  C      D
}
begin

  B:= Ponto( (x_ + TAM - 3) div TAM, (y_ + 2) div TAM );
  D:= Ponto( (x_ + TAM - 3) div TAM, (y_ + TAM - 3) div TAM);

  A:= Ponto( (x_ + 3) div TAM, (y_ + 2) div TAM );
  C:= Ponto( (x_ + 3) div TAM, (y_ + TAM - 3) div TAM);
end;

var
  osx: TSentidoX;

procedure TAgnaldo.Mover(velocidade: integer);
var
  nx, ny: integer;
  lim: integer; //limite da aceleraçao
begin
  if( SentidoX = Direita )then begin
    osx:= Direita;
    nx:= x + velocidade + Round(VelocX);
    ny:= y;

    VelocX:= VelocX + 0.2;

    if( Correndo )then
      lim:= 5
    else
      lim:= 2;

    if( VelocX > lim )then
        VelocX:= lim;

    Detectar_Bloco(nx, ny,nil);
    if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then
      nx:= Jogo.Mapa.Bloco(B.x,B.y).Rect.Left - TAM
    else
      if( Jogo.Mapa.Bloco(D.x,D.y).Solido )then
        nx:= Jogo.Mapa.Bloco(D.x,D.y).Rect.Left - TAM;
    x:= nx; y:= ny;
  end else
    if( SentidoX = Esquerda )then begin
      osx:= Esquerda;
      nx:= x - velocidade - Round(VelocX);
      ny:= y;

      VelocX:= VelocX + 0.2;

      if( Correndo )then
        lim:= 4
      else
        lim:= 2;

      if( VelocX > lim )then
          VelocX:= lim;

      Detectar_Bloco(nx, ny, nil);
      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then
        nx:= Jogo.Mapa.Bloco(A.x,A.y).Rect.Right - 1
      else
        if( Jogo.Mapa.Bloco(C.x,C.y).Solido )then
          nx:= Jogo.Mapa.Bloco(C.x,C.y).Rect.Right - 1;
      x:= nx; y:= ny;
    end;
  if( x < 0 )then x:= 0;

  if( SentidoX = Parado )then begin
    if( osx = Direita )then begin
      VelocX:= VelocX - 0.1;
      nx:= x + Round(VelocX);
      ny:= y;
      Detectar_Bloco(nx,ny,nil);
      if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then
        nx:= x
      else
        if( Jogo.Mapa.Bloco(D.x,D.y).Solido )then
          nx:= x;

      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then begin
        ny:= Jogo.Mapa.Bloco(A.x,A.y).Rect.Bottom;
        Veloc:= 0;
      end else
        if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then begin
          ny:= Jogo.Mapa.Bloco(B.x,B.y).Rect.Bottom;
          Veloc:= 0;
        end;

    end;
    if( osx = Esquerda )then begin
      VelocX:= VelocX - 0.1;
      nx:= x - Round(VelocX);
      ny:= y;
      Detectar_Bloco(nx,ny,nil);
      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then
        nx:= x
      else
        if( Jogo.Mapa.Bloco(C.x,C.y).Solido )then
          nx:= x;

      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then begin
        ny:= Jogo.Mapa.Bloco(A.x,A.y).Rect.Bottom;
        Veloc:= 0;
      end else
        if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then begin
          ny:= Jogo.Mapa.Bloco(B.x,B.y).Rect.Bottom;
          Veloc:= 0;
        end;


    end;
    if( VelocX < 0 )then
      VelocX:= 0;
    x:= nx; y:= ny;
  end;

end;

function TAgnaldo.Ponto(x_, y_: integer): TCoordenada;
begin
  result.x:= x_;
  result.y:= y_;
end;

procedure TAgnaldo.Pular;
var
  nx, ny: integer; //nova posição
  tx, ty: integer; //usado para facilitar a detecção do bloco na cabeçada
begin
  nx:= x; ny:= y;

  if( Pulo )then begin

    if( Correndo )then
      Acele:= 1.2
    else
      Acele:= 1.1;

    Veloc:= Veloc - Round(Acele);
    dec(ny,Veloc);
    if( Veloc < - TAM )then
      Veloc:= -TAM;
  end;

  if( Veloc > 0 )then
    SentidoY:= Cima
  else if( Veloc < 0 )then SentidoY:= Baixo;

  if( SentidoY = Baixo )then begin
    Detectar_Bloco(nx+5, ny, nil);// isso foi usado para melhorar a detecção do bloco abaixo
    if( Jogo.Mapa.Bloco(C.x,C.y).Solido )or( Jogo.Mapa.Bloco(C.x,C.y).Tipo = EmCima )then begin
          ny:= Jogo.Mapa.Bloco(C.x,C.y).Rect.Top - TAM + 2;
          Pulo:= False;
          Veloc:= 0;
    end else
    begin
      Detectar_Bloco(nx-5, ny, nil);
      if( Jogo.Mapa.Bloco(D.x,D.y).Solido )or( Jogo.Mapa.Bloco(D.x,D.y).Tipo = EmCima )then begin
        ny:= Jogo.Mapa.Bloco(D.x,D.y).Rect.Top - TAM + 2;
        Pulo:= False;
        Veloc:= 0;
      end else Pulo:= True;
    end;
  end else
    if( SentidoY = Cima )then begin

      Detectar_Bloco(nx,ny, nil);

      tx:= (nx + TAM div 2) div TAM;
      ty:= (ny) div TAM;

      if( Jogo.Mapa.Bloco(A.x,A.y).Solido )then begin
        ny:= Jogo.Mapa.Bloco(A.x,A.y).Rect.Bottom;
        Veloc:= 0;
      end else
        if( Jogo.Mapa.Bloco(B.x,B.y).Solido )then begin
          ny:= Jogo.Mapa.Bloco(B.x,B.y).Rect.Bottom;
          Veloc:= 0;
        end;

      if( Jogo.Mapa.Bloco(tx,ty).Solido )then begin
        Cabecadas(Jogo.Mapa.pBloco(tx,ty));
        ny:= Jogo.Mapa.Bloco(tx,ty).Rect.Bottom;
      end;


    end;

  if( ny < 0 )then Veloc:= 0;
  x:= nx; y:= ny;
end;

{ TFmMain }

procedure TFmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Finalizar_Jogo;
end;

procedure TFmMain.FormCreate(Sender: TObject);
begin
  Iniciar_Jogo(fase,'fase1.map');
  Iniciar_Sons;
  cx:= 3; cy:= 3;
end;

var
  x_, y_: integer; //fundo background


procedure TFmMain.FormActivate(Sender: TObject);
var
  x1, x2, x, y: integer;
  dif: single;
  b: integer;
  pb: ptBloco;
  i, j: integer;
  T, Aux: TClk;
  LastTime: Extended ;
begin
  x_:= 0; y_:= 0;

  LastTime:= 0;

  ClkReset(T);
  ClkStart(T);


  while not application.Terminated do begin
    x_:= -Round((Agnaldo.x-Agnaldo.ScrX) * 0.30) mod (Jogo.background.Width);
    Agnaldo.ChecarPulo;
    Agnaldo.Checar_Teclado;
    Agnaldo.Pular();
    Agnaldo.Mover(3);

    // Utilizado para controle do SCROLLING
    x1:= Jogo.FCenX div TAM;
    x2:= x1 + (Jogo.Largura div TAM) + 1;
    if( x2 > Jogo.Mapa.Col )then x2:= Jogo.Mapa.Col - 1;
    Jogo.DeslX:= - (Jogo.FCenX mod 32);
    Agnaldo.ScrX:= (Agnaldo.x - Jogo.FCenX);

    if( Agnaldo.ScrX < Jogo.CMaxX )then begin
      Dif := Jogo.CMaxX - Agnaldo.ScrX;
      Agnaldo.ScrX := Round(Jogo.CMaxX);
      Jogo.FCenX := Round(Jogo.FCenX - Dif);
    end else if Agnaldo.ScrX + 32 > Jogo.Largura - Jogo.CMaxX then begin
      Dif := Agnaldo.ScrX - (Jogo.Largura - Jogo.CMaxX - 32);
      Agnaldo.ScrX := Round(Jogo.Largura - Jogo.CMaxX - 32);
      Jogo.FCenX := Round(Jogo.FCenX + Dif);
    end;
    if(Jogo.FCenX + Jogo.Largura > Jogo.Mapa.Col * 32)then begin
      Jogo.FCenX := (Jogo.Mapa.Col * 32) - Jogo.Largura;
      Agnaldo.ScrX := Round(Agnaldo.x - Jogo.FCenX);
    end else
    if (Jogo.FCenX < 0) then begin
      Jogo.FCenX := 0;
      Agnaldo.ScrX := Round(Agnaldo.x - Jogo.FCenX);
    end;
    //FIM do Scrolling

    Agnaldo.Ajustar_Quadros;
    if( Agnaldo.y + TAM > Jogo.Altura )then begin
      Agnaldo.x:= 32;
      Agnaldo.y:= 32;
    end;
    // movimento do blocos "?"

    //if( Assigned(Jogo.pBloco) )then begin
    //  Dec(Jogo.velo_inicial,1);
    //  Inc(Jogo.pBloco.offsety,Jogo.velo_inicial);
    //  if( Jogo.velo_inicial <= -4 )then begin
    //    Jogo.velo_inicial:= 0;
    //    Jogo.pBloco.offsety:= 0;
    //    Jogo.pBloco:= nil;
    //  end;
    //end;

    //Ajustar_Moedas;
    //if( Assigned(Jogo.Cogumelo) )then
    //  Jogo.Cogumelo.Mover_Cogumelo;
    //
    BitBlt(Jogo.buffer.Canvas.Handle,x_,y_,Jogo.Largura,Jogo.Altura,
       Jogo.background.Canvas.Handle, 0, 0, SRCCOPY);
    BitBlt(Jogo.buffer.Canvas.Handle,x_ + Jogo.background.Width,y_,Jogo.Largura,Jogo.Altura,
      Jogo.background.Canvas.Handle, 0, 0, SRCCOPY);
    Jogo.Mapa.Desenhar(Jogo.buffer,x1,x2, Jogo.DeslX, 0);
    //Desenhar_Moedas;
    //Desenhar_Cogumelo;
    Agnaldo.Desenhar(Agnaldo.ScrX,Agnaldo.y);
    Debug; // Mostrar Informações do Mundo 2D
    Mostrar_FPS(Jogo.buffer);

    while True do begin
      Aux := T;
      ClkStop(Aux);
      if ClkGet(Aux) >= LastTime + (1/30) then BREAK;
    end;
    LastTime := ClkGet(Aux);

    BitBlt(canvas.Handle,0,0,Jogo.Largura,Jogo.Altura,
      Jogo.buffer.Canvas.Handle,0,0,SRCCOPY);
    Application.ProcessMessages;
  end;
end;

{
procedure TFmMain.FormActivate(Sender: TObject);
var
  x1, x2, x, y: integer;
  dif: single;
  b: integer;
  pb: ptBloco;
  i, j: integer;
begin
  x_:= 0; y_:= 0;
  terminado:= true;
  while not application.Terminated do begin
    if( timeGettime - Jogo.Tempo > Jogo.Taxa )and(Terminado)then begin
      x_:= -Round((Agnaldo.x-Agnaldo.ScrX) * 0.30) mod (Jogo.background.Width);
      Agnaldo.ChecarPulo;
      Agnaldo.Checar_Teclado;
      Agnaldo.Pular();
      Agnaldo.Mover(3);


      // Utilizado para controle do SCROLLING
      x1:= Jogo.FCenX div TAM;
      x2:= x1 + (Jogo.Largura div TAM) + 1;
      if( x2 > Jogo.Mapa.Col )then x2:= Jogo.Mapa.Col - 1;
      Jogo.DeslX:= - (Jogo.FCenX mod 32);
      Agnaldo.ScrX:= (Agnaldo.x - Jogo.FCenX);

      if( Agnaldo.ScrX < Jogo.CMaxX )then begin
        Dif := Jogo.CMaxX - Agnaldo.ScrX;
        Agnaldo.ScrX := Round(Jogo.CMaxX);
        Jogo.FCenX := Round(Jogo.FCenX - Dif);
      end else if Agnaldo.ScrX + 32 > Jogo.Largura - Jogo.CMaxX then begin
        Dif := Agnaldo.ScrX - (Jogo.Largura - Jogo.CMaxX - 32);
        Agnaldo.ScrX := Round(Jogo.Largura - Jogo.CMaxX - 32);
        Jogo.FCenX := Round(Jogo.FCenX + Dif);
      end;
      if (Jogo.FCenX + Jogo.Largura > Jogo.Mapa.Col * 32) then begin
        Jogo.FCenX := (Jogo.Mapa.Col * 32) - Jogo.Largura;
        Agnaldo.ScrX := Round(Agnaldo.x - Jogo.FCenX);
      end else
      if (Jogo.FCenX < 0) then begin
        Jogo.FCenX := 0;
        Agnaldo.ScrX := Round(Agnaldo.x - Jogo.FCenX);
      end;
      //FIM do Scrolling

      Agnaldo.Ajustar_Quadros;
      if( Agnaldo.y + TAM > Jogo.Altura )then begin
        Agnaldo.x:= 32;
        Agnaldo.y:= 32;
      end;
      // movimento do blocos "?"
      if( Assigned(Jogo.pBloco) )then begin
        Dec(Jogo.velo_inicial,2);
        Inc(Jogo.pBloco.offsety,Jogo.velo_inicial);
        if( Jogo.velo_inicial < -4 )then begin
          Jogo.velo_inicial:= 0;
          Jogo.pBloco.offsety:= 0;
          Jogo.pBloco:= nil;
        end;
      end;
      Ajustar_Moedas;
      if( Assigned(Jogo.Cogumelo) )then
        Jogo.Cogumelo.Mover_Cogumelo;
      Jogo.Tempo:= timeGetTime;
    end else
    if( timeGettime - tempo_jogo > Round(Jogo.Taxa) div 2 )then
      begin
        Terminado:= false;
        Jogo.buffer.Canvas.Draw(x_,y_,Jogo.background);
        Jogo.buffer.Canvas.Draw(x_+Jogo.background.Width,y_,Jogo.background);
        Jogo.Mapa.Desenhar(Jogo.buffer,x1,x2, Jogo.DeslX);
        Desenhar_Moedas;
        Desenhar_Cogumelo;
        Agnaldo.Desenhar(Agnaldo.ScrX,Agnaldo.y);
        //Debug; // Mostrar Informações do Mundo 2D
        Mostrar_FPS(Jogo.buffer);
        Canvas.Draw(0,0,Jogo.buffer);
        tempo_jogo:= timeGetTime;
        Terminado:= true;
      end;
    Application.ProcessMessages;
  end;
end;
}



end.
