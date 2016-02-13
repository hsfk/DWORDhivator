unit UPackUnpack;

{$mode objfpc}{$H+}
{$ASMMODE intel}
interface

uses
  Classes, SysUtils, Math, UTree, crt, bitops, UFileAnalization;

type
  Cache = array [0..255] of string;
  FrequencyTable = array [0..255] of longword;

  THuffman = class
  public
    procedure Create(SomeCache: cache; SomeTable: FrequencyTable);
    function Pack(filename: string): boolean;
    function Unpack(filename: string): boolean;
  private
  end;

var
  Routes: cache;
  Table: FrequencyTable;
  LastNills: byte;
  Ftree: Ttree;
  FFile: Tfile;
  FBit: Tbit;

implementation

procedure THuffman.Create(SomeCache: cache; SomeTable: FrequencyTable);
begin
  Routes := SomeCache;
  Table := SomeTable;
  LastNills := 0;
end;

function THuffman.Unpack(filename: string): boolean;
var
  output: Text;
  msInput: TMemoryStream;
  sizeoffile, Pbar, PbarC: int64;
  symbol, i: byte;
  root, tmp: nodeptr;
  Byte_: string;

  LCache: LengthCache;

begin
  msInput := TMemoryStream.Create;
  msInput.LoadFromFile(filename);
  SetLength(filename, length(filename) - 7);
  filename := 'unp - ' + filename;
  Assign(output, filename);
  rewrite(output);
  msInput.seek(0, soBeginning);

  Byte_ := '';
  for i := 0 to 3 do begin
    symbol := msInput.ReadByte;
    Byte_ += chr(symbol);
  end;
  if Byte_ <> 'SOLG' then begin
    Result := False;
    exit;
  end;
  for i := 0 to 255 do begin
    symbol := msInput.ReadByte;
    LCache[i] := symbol;//по таблице длин(она же высота в дереве) будем строить дерево
  end;

  Table := Ftree.GetFTable(LCache);
  root := Ftree.MakeTree(Table);

  SizeOfFile := msInput.Size - 256 - 4 - 1 - 1;   //4 solg 256 table 1 - last nil
  Pbar := SizeOfFile;
  PbarC := 1;//progress bar
  tmp := root;
  Byte_ := '00000000';

  while SizeOfFile <> 0 do begin
    symbol := msInput.ReadByte;
    for i := 0 to 7 do begin
      if ((symbol and round(power(2, 7 - i))) <> 0) and (tmp^.right <> nil) then
        tmp := tmp^.right//если 7-i бит == 1
      else if tmp^.left <> nil then
        tmp := tmp^.left;
      if tmp^.flag = True then begin
        Write(output, chr(tmp^.key));
        tmp := root;
      end;
    end;

    PbarC += 1;
    if (PbarC mod (Pbar div 100)) = 0 then begin
      clrscr;
      writeln('progress ', round((PbarC / pbar) * 100), ' %');
    end;

    SizeOfFile -= 1;
  end;

  symbol := msInput.ReadByte;
  Byte_ := '00000000';
  for i := 0 to 7 do begin
    if (symbol and round(power(2, 7 - i))) <> 0 then
      Byte_[i + 1] := '1'
    else
      Byte_[i + 1] := '0';
  end;
  LastNills := msInput.ReadByte;

  if LastNills <> 11 then begin
    for i := 1 to lastNills do
      Byte_ := copy(Byte_, 2, length(Byte_));  //2 - убирает 1й ноль
  end;

  for i := 1 to length(Byte_) do begin
    if (Byte_[i] = '1') and (tmp^.right <> nil) then
      tmp := tmp^.right
    else if tmp^.left <> nil then
      tmp := tmp^.left;
    if tmp^.flag = True then begin
      Write(output, chr(tmp^.key));
      tmp := root;
    end;
  end;
  msInput.Free;
  Close(output);
  Result := True;
end;

function THuffman.Pack(filename: string): boolean;
var
  output: Text;
  msInput: TMemoryStream;
  sizeoffile: int64;
  symbol, i: byte;

  BCache: BitCache;
  Lcache: LengthCache;
  Buffer, temp: longword;
  BufLength: byte;
  t_start, t_end: TDateTime;
begin
  msInput := TMemoryStream.Create;
  msInput.LoadFromFile(filename);
  Assign(output, filename + '.testpb');
  rewrite(output);

  Table := FFile.GetFrequency(msInput);

  Routes := Ftree.GetTable(Table);
  LCache := Fbit.GetLengthCache(Routes);
  BCache := Ftree.GetBCache(LCache);

  Write(output, 'SOLG');
  for i := 0 to 255 do
    Write(output, chr(LCache[i]));

  sizeoffile := msInput.Size;
  Buffer := 0;
  BufLength := 0;

  t_start := Time;
  msInput.Seek(0, soBeginning);
  while SizeOfFile <> 0 do begin
    while (bufLength < 8) and (SizeOfFile <> 0) do begin
      symbol := msInput.ReadByte;
      temp := BCache[symbol];//BCache-путь к символу по дереву, записанный в битах числа
      BufLength += LCache[symbol];//LCache - длина пути
      temp := temp shl (32 - bufLength);//buffer - очередь битов путей в lworde
      Buffer := Buffer or temp;          //кладем пути в очередь
      SizeOfFile -= 1;
    end;

    if SizeOfFile = 0 then
      break;

    asm
             MOVSS   XMM0, BUFFER
             PSRLD   XMM0, 24
             MOVSS   TEMP, XMM0
             MOVSS   XMM0, BUFFER      //вытаскиваем 8 бит из очереди в temp
             PSLLD   XMM0, 8
             MOVSS   BUFFER, XMM0
             SUB     BUFLENGTH, 8
    end;
    Write(output, chr(temp));
  end;

  while BufLength >= 8 do begin //если в очереди больше 1 байта
    temp := buffer shr 24;
    buffer := buffer shl 8;
    BufLength -= 8;
    Write(output, chr(temp));
  end;

  if BufLength <> 0 then begin
    LastNills := 8 - BufLength; //LastNills - последний байт файла отчечающий за
    buffer := buffer shr lastnills;//остаток, те если остаток < 8 бит то к нему
    buffer := buffer shr 24;//накинутся LastNills нулей
    Write(output, chr(buffer));
  end;

  if (LastNills < 8) and (LastNills > 0) then
    Write(output, chr(LastNills))
  else
    Write(output, chr(11));//если нулей нет
  t_end := time;

  writeln('TIME: ', TimeToStr(t_end - t_start));
  writeln('PRESS ANY KEY TO CONTINUE');
  readln;
  readln;
  msInput.Free;
  Close(output);
  Result := True;
end;

end.
