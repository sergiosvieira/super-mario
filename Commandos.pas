unit Commandos;

{$MODE Delphi}

{
****************************************
Biblioteca de Interpretação de Commandos
****************************************

Versão Beta 28/05/05

Criada e Desenvolvida por Eduardo "Trialforce" Bonfandini

trialforce@hotmail.com

Especialmente desenvolvida para Jogos seguindo estilo dos jogos de lutas 1x1 = Street Fighter
Pode ser facilmente usada ou convertida para outros sistemas)

Projeto Iniciado em 21/04/05

21/04/05
Projeto Inicial, com montando sómente do básico do reconhecimento de teclas direcionais e botões

30/04/05
Incluido Suporte a Multiplos Botões e iniciado um sistema de configuração de teclas pelo usuário.

14/05/05
Terminado sistema de configuração de teclas pelo usuário. Ainda falta fazer Save/Load.

26/05/05
Adicionado ao sistema de mapeamento de teclas, cerca de 99% das teclas de um teclado brasileiro.

28/05/05
Adicionado sistema que verifica botão, por botão, se está pressionado ou não... desta forma, o sistema
pode ser melhor aproveitado para outras formas de jogos. E também verifica a quantos ticks eles está pressionado)
}


{Rosa dos Botões Virtuais :P

     C
  B  |  D
   \ | /
A---------E
   / | \
  H  G  F

B1=1
B2=2
B3=3
B4=4
B5=5
B6=6
B7=7
B8=8

}

interface
//para getkeystate
uses LCLIntf, LCLType, LMessages, SysUtils;

type

  //**********************//
  //        Teclas        //
  //**********************//

  //Word=tipo de pressiomento de tecla, usado pela função getkeystate
  //String= tipo texto usado na geração da lista

  //usado pra codificação de Word para String...
  TVkey = record
    key: word;      //define-se a WORD que é o tecla
    Text: string;   //defini-se a STRING que seria a texto ou nome da tecla
  end;

  // É a lista de teclas, que podem ser definidas, ou seja aqui vc define
  // quais teclas sua aplicação vai reconhecer...
  // vc pode por exemplo desabilitar o F1... o enter ou sei lá...
  TListaVkeys = record
    ListaVKey: array of TVkey;
  end;

  //**********************//
  //  Botões Virtuais     //
  //**********************//

  // Chamo de botões virtuais, pois na verdade isto não são os botões em si,
  // mas na verdade, eles são representações da teclas pressionadas.

  // Novo Sistema, pra determinar, botão por botão se está pressionado neste momento ou não
  TBotao = record
    Key: word;
    ticks: integer;
    Pressionado: boolean;
    //Tempo:Integer;
  end;

  //botões virtuais, aqui são armazenados as WORDS para cada botão
  TTeclasVirtuais = record
    esquerda, direita, baixo, cima: Tbotao;
    Botoes: array of Tbotao;
  end;

  // Este é o tipo que engloba tudo
  TControle = record
    lista: string;  //lista de commandos
    ultimo: string; //ultimo commando a ser pressionado
    tempo: integer; //tempo de pressionamento da tecla atual...
    Teclas: TTeclasVirtuais; // este são as teclas em si
  end;

// Função mestre chamada a cada evento da aplicação...
// normalmente acionada por um timer
// Função que gera a Lista de botões pressionados
function PegaTeclas(Controle: Tcontrole): Tcontrole;

// Função que Define as Lista de Teclas que os botões poderam reconhecer..
function MontarVkeys(ListaVKeys: TlistaVKeys): TlistaVkeys;
// Função que converte de WORD pra STRING ou seja Vkey para TEXT
function Vkeytotext(vkey: word; ListaVKeys: TlistaVkeys): string;

implementation

function PegaTeclas(Controle: Tcontrole): Tcontrole;
var
  apertou: boolean;
  i: integer;
begin
  apertou := False;

  if getkeystate(controle.teclas.esquerda.key) >= 0 then
    controle.teclas.esquerda.pressionado := False;

  if getkeystate(controle.teclas.direita.key) >= 0 then
    controle.teclas.direita.pressionado := False;

  if getkeystate(controle.teclas.cima.key) >= 0 then
    controle.teclas.cima.pressionado := False;

  if getkeystate(controle.teclas.baixo.key) >= 0 then
    controle.teclas.baixo.pressionado := False;

  // Se apertar esquerda

  if getkeystate(controle.teclas.esquerda.key) < 0 then
  begin
    //if controle.teclas.esquerda.Pressionado then inc(controle.teclas.esquerda.tempo);
    controle.teclas.esquerda.Pressionado := True;
    //se não estiver pressionando 'cima', nem 'baixo' ou seja esquerda puro...
    if getkeystate(controle.teclas.cima.key) >= 0 then
    begin
      if getkeystate(controle.teclas.baixo.key) >= 0 then
      begin
        if controle.ultimo <> 'A' then
        begin
          controle.lista := controle.lista + 'A';
          controle.ultimo := 'A';
          controle.tempo := 0;
        end;
        if controle.ultimo = 'A' then
          Inc(controle.tempo);
        apertou := True;
      end;
    end;

    //Se for esquerda+cima //diagonal
    if getkeystate(controle.teclas.cima.key) < 0 then
    begin
      if controle.ultimo <> 'B' then
      begin
        controle.lista := controle.lista + 'B';
        controle.ultimo := 'B';
        controle.tempo := 0;
      end;
      if controle.ultimo = 'B' then
        Inc(controle.tempo);
      apertou := True;
    end;

  end;

  // Se pressionar pra cima...
  if getkeystate(controle.teclas.cima.key) < 0 then
  begin
    controle.teclas.cima.Pressionado := True;

    //sem ser esquerda ou direita ; cima puro
    if getkeystate(controle.teclas.esquerda.key) >= 0 then
    begin
      if getkeystate(controle.teclas.direita.key) >= 0 then
      begin
        if controle.ultimo <> 'C' then
        begin
          controle.lista := controle.lista + 'C';
          controle.ultimo := 'C';
          controle.tempo := 0;
        end;
        if controle.ultimo = 'C' then
          Inc(controle.tempo);
        apertou := True;
      end;
    end;

    // se for cima+direita //diagonal
    if getkeystate(controle.teclas.direita.key) < 0 then
    begin
      if controle.ultimo <> 'D' then
      begin
        controle.lista := controle.lista + 'D';
        controle.ultimo := 'D';
        controle.tempo := 0;
      end;
      if controle.ultimo = 'D' then
        Inc(controle.tempo);
      apertou := True;
    end;

  end;

  //se pressionar direita
  if getkeystate(controle.teclas.direita.key) < 0 then
  begin
    controle.teclas.direita.Pressionado := True;

    // se for pra direta puro, ou seja sem apertar nem pra cima nem pra baixo
    if getkeystate(controle.teclas.cima.key) >= 0 then
    begin
      if getkeystate(controle.teclas.baixo.key) >= 0 then
      begin
        if controle.ultimo <> 'E' then
        begin
          controle.lista := controle.lista + 'E';
          controle.ultimo := 'E';
          controle.tempo := 0;
        end;
        if controle.ultimo = 'E' then
          Inc(controle.tempo);
        apertou := True;
      end;
    end;

    //se for direita+baixo // diagonal
    if getkeystate(controle.teclas.baixo.key) < 0 then
    begin
      if controle.ultimo <> 'F' then
      begin
        controle.lista := controle.lista + 'F';
        controle.ultimo := 'F';
        controle.tempo := 0;
      end;
      if controle.ultimo = 'F' then
        Inc(controle.tempo);
      apertou := True;
    end;

  end;

  // se pressionar baixo
  if getkeystate(controle.teclas.baixo.key) < 0 then
  begin
    controle.teclas.baixo.Pressionado := True;

    // baixo puro
    if getkeystate(controle.teclas.direita.key) >= 0 then
    begin
      if getkeystate(controle.teclas.esquerda.key) >= 0 then
      begin
        if controle.ultimo <> 'G' then
        begin
          controle.lista := controle.lista + 'G';
          controle.ultimo := 'G';
          controle.tempo := 0;
        end;
        if controle.ultimo = 'G' then
          Inc(controle.tempo);
        apertou := True;
      end;
    end;

    // se for baixo+esquerda // diagonal
    if getkeystate(controle.teclas.esquerda.key) < 0 then
    begin
      if controle.ultimo <> 'H' then
      begin
        controle.lista := controle.lista + 'H';
        controle.ultimo := 'H';
        controle.tempo := 0;
      end;
      if controle.ultimo = 'H' then
        Inc(controle.tempo);
      apertou := True;
    end;

  end;

  i := 0;

  while i < high(controle.teclas.botoes) + 1 do
  begin

    if getkeystate(controle.teclas.botoes[i].key) >= 0 then
    begin
      controle.teclas.botoes[i].Pressionado := False;
      controle.teclas.botoes[i].ticks := 0;
    end;

    if getkeystate(controle.teclas.botoes[i].key) < 0 then
    begin

      if controle.teclas.botoes[i].pressionado then
        Inc(controle.teclas.botoes[i].ticks);

      controle.teclas.botoes[i].Pressionado := True;

      if controle.ultimo <> IntToStr(i) then
      begin
        controle.lista := controle.lista + IntToStr(i);
        controle.ultimo := IntToStr(i);
        controle.tempo := 0;
      end;
      if controle.ultimo = IntToStr(i) then
        Inc(controle.tempo);
      apertou := True;
    end;
    Inc(i);
  end;

  // se não tiver apertado nenhuma botão, reseta a lista e o tempo
  if apertou = False then
  begin
    controle.lista := '';
    controle.ultimo := '';
    controle.tempo := 0;
  end;

  Result := controle;

end;

function MontarVkeys(ListaVKeys: TlistaVKeys): TlistaVkeys;
begin
  Setlength(listavkeys.listavkey, 109);
  listaVkeys.listavkey[0].key := vk_left;
  listaVkeys.listavkey[0].Text := 'Seta Esquerda';
  listaVkeys.listavkey[1].key := vk_right;
  listaVkeys.listavkey[1].Text := 'Seta Direita';
  listaVkeys.listavkey[2].key := vk_up;
  listaVkeys.listavkey[2].Text := 'Seta Acima';
  listaVkeys.listavkey[3].key := vk_down;
  listaVkeys.listavkey[3].Text := 'Seta Abaixo';
  listaVkeys.listavkey[4].key := Ord('A');
  listaVkeys.listavkey[4].Text := 'A';
  listaVkeys.listavkey[5].key := Ord('B');
  listaVkeys.listavkey[5].Text := 'B';
  listaVkeys.listavkey[6].key := Ord('C');
  listaVkeys.listavkey[6].Text := 'C';
  listaVkeys.listavkey[7].key := Ord('D');
  listaVkeys.listavkey[7].Text := 'D';
  listaVkeys.listavkey[8].key := Ord('E');
  listaVkeys.listavkey[8].Text := 'E';
  listaVkeys.listavkey[9].key := Ord('F');
  listaVkeys.listavkey[9].Text := 'F';
  listaVkeys.listavkey[10].key := Ord('G');
  listaVkeys.listavkey[10].Text := 'G';
  listaVkeys.listavkey[11].key := Ord('H');
  listaVkeys.listavkey[11].Text := 'H';
  listaVkeys.listavkey[12].key := Ord('I');
  listaVkeys.listavkey[12].Text := 'I';
  listaVkeys.listavkey[13].key := Ord('J');
  listaVkeys.listavkey[13].Text := 'J';
  listaVkeys.listavkey[14].key := Ord('K');
  listaVkeys.listavkey[14].Text := 'K';
  listaVkeys.listavkey[15].key := Ord('L');
  listaVkeys.listavkey[15].Text := 'L';
  listaVkeys.listavkey[16].key := Ord('M');
  listaVkeys.listavkey[16].Text := 'M';
  listaVkeys.listavkey[17].key := Ord('N');
  listaVkeys.listavkey[17].Text := 'N';
  listaVkeys.listavkey[18].key := Ord('O');
  listaVkeys.listavkey[18].Text := 'O';
  listaVkeys.listavkey[19].key := Ord('P');
  listaVkeys.listavkey[19].Text := 'P';
  listaVkeys.listavkey[20].key := Ord('Q');
  listaVkeys.listavkey[20].Text := 'Q';
  listaVkeys.listavkey[21].key := Ord('R');
  listaVkeys.listavkey[21].Text := 'R';
  listaVkeys.listavkey[22].key := Ord('S');
  listaVkeys.listavkey[22].Text := 'S';
  listaVkeys.listavkey[23].key := Ord('T');
  listaVkeys.listavkey[23].Text := 'T';
  listaVkeys.listavkey[24].key := Ord('U');
  listaVkeys.listavkey[24].Text := 'U';
  listaVkeys.listavkey[25].key := Ord('V');
  listaVkeys.listavkey[25].Text := 'V';
  listaVkeys.listavkey[26].key := Ord('X');
  listaVkeys.listavkey[26].Text := 'X';
  listaVkeys.listavkey[27].key := Ord('Y');
  listaVkeys.listavkey[27].Text := 'Y';
  listaVkeys.listavkey[28].key := Ord('Z');
  listaVkeys.listavkey[28].Text := 'Z';
  listaVkeys.listavkey[29].key := Ord('W');
  listaVkeys.listavkey[29].Text := 'W';
  listaVkeys.listavkey[30].key := Ord('1');
  listaVkeys.listavkey[30].Text := '1';
  listaVkeys.listavkey[31].key := Ord('2');
  listaVkeys.listavkey[31].Text := '2';
  listaVkeys.listavkey[32].key := Ord('3');
  listaVkeys.listavkey[32].Text := '3';
  listaVkeys.listavkey[33].key := Ord('4');
  listaVkeys.listavkey[33].Text := '4';
  listaVkeys.listavkey[34].key := Ord('5');
  listaVkeys.listavkey[34].Text := '5';
  listaVkeys.listavkey[35].key := Ord('6');
  listaVkeys.listavkey[35].Text := '6';
  listaVkeys.listavkey[36].key := Ord('7');
  listaVkeys.listavkey[36].Text := '7';
  listaVkeys.listavkey[37].key := Ord('8');
  listaVkeys.listavkey[37].Text := '8';
  listaVkeys.listavkey[38].key := Ord('9');
  listaVkeys.listavkey[38].Text := '9';
  listaVkeys.listavkey[39].key := Ord('0');
  listaVkeys.listavkey[39].Text := '0';
  //////
  listaVkeys.listavkey[40].key := VK_LBUTTON;
  listaVkeys.listavkey[40].Text := 'Mouse Esquerdo';
  listaVkeys.listavkey[41].key := vk_space;
  listaVkeys.listavkey[41].Text := 'Espaço';
  listaVkeys.listavkey[42].key := VK_ESCAPE;
  listaVkeys.listavkey[42].Text := 'Esc';
  listaVkeys.listavkey[43].key := VK_ESCAPE;
  listaVkeys.listavkey[43].Text := 'Esc';
  listaVkeys.listavkey[44].key := VK_PRIOR;
  listaVkeys.listavkey[44].Text := 'Page Up';
  listaVkeys.listavkey[45].key := VK_NEXT;
  listaVkeys.listavkey[45].Text := 'Page Down';
  listaVkeys.listavkey[46].key := VK_END;
  listaVkeys.listavkey[46].Text := 'End';
  listaVkeys.listavkey[47].key := VK_END;
  listaVkeys.listavkey[47].Text := 'End';
  listaVkeys.listavkey[48].key := VK_SELECT;
  listaVkeys.listavkey[48].Text := 'Select';
  listaVkeys.listavkey[49].key := VK_SELECT;      //?
  listaVkeys.listavkey[49].Text := 'Select';
  listaVkeys.listavkey[50].key := VK_PRINT;
  listaVkeys.listavkey[50].Text := 'Print Screen';
  listaVkeys.listavkey[51].key := VK_PRINT;
  listaVkeys.listavkey[51].Text := 'Print';
  listaVkeys.listavkey[52].key := VK_EXECUTE;  //?
  listaVkeys.listavkey[52].Text := 'Execute';
  listaVkeys.listavkey[53].key := VK_SNAPSHOT;
  listaVkeys.listavkey[53].Text := 'PrintScreen';
  listaVkeys.listavkey[54].key := VK_INSERT;
  listaVkeys.listavkey[54].Text := 'Insert';
  listaVkeys.listavkey[55].key := VK_DELETE;
  listaVkeys.listavkey[55].Text := 'Delete';
  listaVkeys.listavkey[56].key := VK_HELP; //?
  listaVkeys.listavkey[56].Text := 'Help';
  listaVkeys.listavkey[57].key := VK_NUMPAD0;
  listaVkeys.listavkey[57].Text := 'Pad0';
  listaVkeys.listavkey[58].key := VK_NUMPAD1;
  listaVkeys.listavkey[58].Text := 'Pad1';
  listaVkeys.listavkey[59].key := VK_NUMPAD2;
  listaVkeys.listavkey[59].Text := 'Pad2';
  listaVkeys.listavkey[60].key := VK_NUMPAD3;
  listaVkeys.listavkey[60].Text := 'Pad3';
  listaVkeys.listavkey[61].key := VK_NUMPAD4;
  listaVkeys.listavkey[61].Text := 'Pad4';
  listaVkeys.listavkey[62].key := VK_NUMPAD5;
  listaVkeys.listavkey[62].Text := 'Pad5';
  listaVkeys.listavkey[63].key := VK_NUMPAD6;
  listaVkeys.listavkey[63].Text := 'Pad6';
  listaVkeys.listavkey[64].key := VK_NUMPAD7;
  listaVkeys.listavkey[64].Text := 'Pad7';
  listaVkeys.listavkey[65].key := VK_NUMPAD8;
  listaVkeys.listavkey[65].Text := 'Pad8';
  listaVkeys.listavkey[66].key := VK_NUMPAD9;
  listaVkeys.listavkey[66].Text := 'Pad9';
  listaVkeys.listavkey[67].key := VK_F1;
  listaVkeys.listavkey[67].Text := 'F1';
  listaVkeys.listavkey[68].key := VK_F2;
  listaVkeys.listavkey[68].Text := 'F2';
  listaVkeys.listavkey[69].key := VK_F3;
  listaVkeys.listavkey[69].Text := 'F3';
  listaVkeys.listavkey[70].key := VK_F4;
  listaVkeys.listavkey[70].Text := 'F4';
  listaVkeys.listavkey[71].key := VK_F5;
  listaVkeys.listavkey[71].Text := 'F5';
  listaVkeys.listavkey[72].key := VK_F6;
  listaVkeys.listavkey[72].Text := 'F6';
  listaVkeys.listavkey[73].key := VK_F7;
  listaVkeys.listavkey[73].Text := 'F7';
  listaVkeys.listavkey[74].key := VK_F8;
  listaVkeys.listavkey[74].Text := 'F8';
  listaVkeys.listavkey[75].key := VK_F9;
  listaVkeys.listavkey[75].Text := 'F9';
  listaVkeys.listavkey[76].key := VK_F10;
  listaVkeys.listavkey[76].Text := 'F10';
  listaVkeys.listavkey[77].key := VK_F11;
  listaVkeys.listavkey[77].Text := 'F11';
  listaVkeys.listavkey[78].key := VK_F12;
  listaVkeys.listavkey[78].Text := 'F12';
  listaVkeys.listavkey[79].key := VK_MULTIPLY;
  listaVkeys.listavkey[79].Text := 'Multiplicar';
  listaVkeys.listavkey[80].key := VK_ADD;
  listaVkeys.listavkey[80].Text := 'Adicionar';
  listaVkeys.listavkey[81].key := VK_SEPARATOR;  //?
  listaVkeys.listavkey[81].Text := 'Separador';
  listaVkeys.listavkey[82].key := VK_SUBTRACT;
  listaVkeys.listavkey[82].Text := 'Subtrair';
  listaVkeys.listavkey[83].key := VK_DECIMAL;
  listaVkeys.listavkey[83].Text := 'Decimal';
  listaVkeys.listavkey[84].key := VK_DIVIDE;
  listaVkeys.listavkey[84].Text := 'Dividir';
  listaVkeys.listavkey[85].key := VK_NUMLOCK;
  listaVkeys.listavkey[85].Text := 'NunLock';
  listaVkeys.listavkey[86].key := VK_SCROLL;
  listaVkeys.listavkey[86].Text := 'ScrollLock';
  listaVkeys.listavkey[87].key := VK_LSHIFT;
  listaVkeys.listavkey[87].Text := 'Shift Esquerdo';
  listaVkeys.listavkey[88].key := VK_RSHIFT;
  listaVkeys.listavkey[88].Text := 'Shift Direito';
  listaVkeys.listavkey[89].key := VK_LCONTROL;
  listaVkeys.listavkey[89].Text := 'Control Esquerdo';
  listaVkeys.listavkey[90].key := VK_RCONTROL;
  listaVkeys.listavkey[90].Text := 'Control Direito';
  listaVkeys.listavkey[91].key := VK_LMENU;
  listaVkeys.listavkey[91].Text := 'Alt Esquerdo';
  listaVkeys.listavkey[92].key := VK_RMENU;
  listaVkeys.listavkey[92].Text := 'Alt Direito';
  listaVkeys.listavkey[93].key := VK_RBUTTON;
  listaVkeys.listavkey[93].Text := 'Mouse Direito';
  listaVkeys.listavkey[94].key := VK_MBUTTON;
  listaVkeys.listavkey[95].Text := 'Mouse Meio';
  listaVkeys.listavkey[96].key := VK_BACK;
  listaVkeys.listavkey[96].Text := 'BackSpace';
  listaVkeys.listavkey[97].key := VK_TAB;
  listaVkeys.listavkey[97].Text := 'Tabulação';
  listaVkeys.listavkey[98].key := VK_CLEAR;
  listaVkeys.listavkey[99].Text := 'Clear';
  listaVkeys.listavkey[100].key := vk_return;
  listaVkeys.listavkey[100].Text := 'Enter';
  listaVkeys.listavkey[101].key := VK_SHIFT;
  listaVkeys.listavkey[101].Text := 'Shift';
  listaVkeys.listavkey[102].key := VK_SHIFT;
  listaVkeys.listavkey[102].Text := 'Shift';
  listaVkeys.listavkey[103].key := VK_CONTROL;
  listaVkeys.listavkey[103].Text := 'Control';
  listaVkeys.listavkey[104].key := VK_MENU;
  listaVkeys.listavkey[104].Text := 'Alt';
  listaVkeys.listavkey[105].key := VK_MENU;
  listaVkeys.listavkey[105].Text := 'Alt';
  listaVkeys.listavkey[106].key := VK_PAUSE;
  listaVkeys.listavkey[106].Text := 'Pause';
  listaVkeys.listavkey[107].key := VK_CAPITAL;
  listaVkeys.listavkey[107].Text := 'Caps Lock';
  listaVkeys.listavkey[108].key := VK_CAPITAL;
  listaVkeys.listavkey[108].Text := 'Caps Lock';

{
Teclas não incluidas na lista
VK_CANCEL  Control+Break
VK_KANA  Used with IME
VK_HANGUL  Used with IME
VK_JUNJA  Used with IME
VK_FINAL  Used with IME
VK_HANJA  Used with IME
VK_KANJI  Used with IME
VK_CONVERT  Used with IME
VK_NONCONVERT  Used with IME
VK_ACCEPT  Used with IME
VK_MODECHANGE  Used with IME
VK_LWIN  Left Windows key (Microsoft keyboard)
VK_RWIN  Right Windows key (Microsoft keyboard)
VK_APPS  Applications key (Microsoft keyboard)
VK_F13  F13 key
VK_F14  F14 key
VK_F15  F15 key
VK_F16  F16 key
VK_F17  F17 key
VK_F18  F18 key
VK_F19  F19 key
VK_F20  F20 key
VK_F21  F21 key
VK_F22  F22 key
VK_F23  F23 key
VK_F24  F24 key
VK_PROCESSKEY  Process key
VK_ATTN  Attn key
VK_CRSEL  CrSel key
VK_EXSEL  ExSel key
VK_EREOF  Erase EOF key
VK_PLAY  Play key
VK_ZOOM  Zoom key
VK_NONAME  Reserved for future use
VK_PA1  PA1 key
VK_OEM_CLEAR  Clear key}

  Result := ListaVkeys;

end;

function Vkeytotext(vkey: word; ListaVKeys: TlistaVkeys): string;
var
  i: integer;
begin
  i := 0;
  while i < high(listavkeys.listavkey) + 1 do
  begin
    if vkey = listavkeys.ListaVKey[i].key then
      Result := listavkeys.ListaVKey[i].Text;
    Inc(i);
  end;

end;

function TexttoVkey(Text: string; ListaVKeys: TlistaVkeys): word;
var
  i: integer;
begin
  i := 0;
  while i < high(listavkeys.listavkey) + 1 do
  begin
    if Text = listavkeys.ListaVKey[i].Text then
      Result := listavkeys.ListaVKey[i].key;
    Inc(i);
  end;

end;


end.
