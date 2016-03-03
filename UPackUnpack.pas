unit UPackUnpack;

{$mode objfpc}{$H+}
{$ASMMODE intel}
interface

uses
  Classes, SysUtils, Math, UTree, crt, UBitOps;

type
  THuffman = class
  public
    constructor Create(mask: string);
    procedure Pack;
    procedure Unpack;
  private
    filename: string;
    Table: FrequencyTable;
    Output: Text;
    LCache: LengthCache;
    msInput: TMemoryStream;
    function GetFrequency(var MStream: TMemoryStream): FrequencyTable;
    function ReadTitle(MStream: TMemoryStream): LengthCache;
    procedure WriteTitle(var Output_: Text);
  end;

implementation

constructor THuffman.Create(mask: string);
var
  Info: TSearchRec;
  Files: TStringList;
  i: integer;
  n: integer;
begin
  clrscr;
  i := 1;
  Files := TStringList.Create;
  if FindFirst(mask, faAnyFile - faDirectory, Info) = 0 then begin
    repeat
      with Info do begin
        writeln(i, '. ', Name, '  ', Size, ' byte');
        Files.Add(Name);
        i += 1;
      end;
    until FindNext(info) <> 0;
  end;
  FindClose(Info);
  while filename = '' do begin
    writeln('Input file number: ');
    Read(n);
    if (n - 1 < 0) or ((n - 1) > (i - 1)) then begin
      writeln('Input correct file number');
    end
    else
      filename := files[n - 1];
  end;
  msInput := TMemoryStream.Create;
  msInput.LoadFromFile(filename);
  msInput.seek(0, soBeginning);
end;

procedure THuffman.Unpack;
var
  LastNulls: byte;
  Root: NodePtr;
  Temp: NodePtr;
  Byte_s: string;
  SizeOfFile: int64;
  Symbol: byte;
  i: byte;
begin
  SetLength(filename, length(filename) - 7);
  filename := 'unp - ' + filename;
  Assign(Output, filename);
  rewrite(Output);

  LCache := ReadTitle(msInput);
  Table := Tree.GetFTable(LCache);
  Root := Tree.MakeTree(Table);

  SizeOfFile := msInput.Size - 256 - 4 - 1 - 1;
  Temp := Root;
  Byte_s := '00000000';

  while SizeOfFile <> 0 do begin
    Symbol := msInput.ReadByte;
    for i := 0 to 7 do begin
      if ((Symbol and round(power(2, 7 - i))) <> 0) and (Temp^.Right <> nil) then
        Temp := Temp^.Right
      else if Temp^.Left <> nil then
        Temp := Temp^.Left;
      if Temp^.IsLeave = True then begin
        Write(Output, chr(Temp^.Key));
        Temp := Root;
      end;
    end;
    SizeOfFile -= 1;
  end;

  Symbol := msInput.ReadByte;
  Byte_s := '00000000';
  for i := 0 to 7 do begin
    if (Symbol and round(power(2, 7 - i))) <> 0 then
      Byte_s[i + 1] := '1'
    else
      Byte_s[i + 1] := '0';
  end;
  LastNulls := msInput.ReadByte;

  if LastNulls <> 11 then begin
    for i := 1 to LastNulls do
      Byte_s := copy(Byte_s, 2, length(Byte_s));
  end;

  for i := 1 to length(Byte_s) do begin
    if (Byte_s[i] = '1') and (Temp^.Right <> nil) then
      Temp := Temp^.Right
    else if Temp^.Left <> nil then
      Temp := Temp^.Left;
    if Temp^.IsLeave = True then begin
      Write(Output, chr(Temp^.Key));
      Temp := Root;
    end;
  end;

  msInput.Free;
  Close(Output);
end;

procedure THuffman.Pack;
var
  BCache: BitCache;
  LastNulls: byte;
  Routes: Cache;
  Buffer: longword;
  Temp: longword;
  BufLength: byte;
  SizeOfFile: int64;
  Symbol: word;
  i: byte;
begin
  Assign(Output, filename + '.testpb');
  rewrite(Output);

  Table := GetFrequency(msInput);
  Routes := Tree.GetCache(Table);
  LCache := BitOps.GetLengthCache(Routes);
  BCache := Tree.GetBCache(LCache);

  WriteTitle(Output);

  SizeOfFile := msInput.Size;
  Buffer := 0;
  BufLength := 0;
  msInput.Seek(0, soBeginning);
  while SizeOfFile <> 0 do begin
    while (bufLength < 8) and (SizeOfFile <> 0) do begin
      Symbol := msInput.ReadByte;
      //asm
      //         MOV     ECX, Symbol
      //         MOV     AL, LCache[0 + ECX]
      //         ADD     BufLength, AL
      //         MOV     ECX, ECX
      //         MOV     EBX, BCache[ECX]
      //
      //         MOV     CL, 32
      //         SUB     CL, BufLength
      //         SHL     EAX, CL
      //         OR      Buffer, EAX
      //end;
      Temp := BCache[Symbol];
      BufLength += LCache[Symbol];
      Temp := Temp shl (32 - bufLength);
      Buffer := Buffer or Temp;
      SizeOfFile -= 1;
    end;
    if SizeOfFile = 0 then
      break;
    asm
             MOVSS   XMM0, Buffer
             PSRLD   XMM0, 24
             MOVSS   Temp, XMM0
             MOVSS   XMM0, Buffer
             PSLLD   XMM0, 8
             MOVSS   Buffer, XMM0
             SUB     BufLength, 8
    end;
    Write(Output, chr(Temp));
  end;

  while BufLength >= 8 do begin
    Temp := Buffer shr 24;
    Buffer := Buffer shl 8;
    BufLength -= 8;
    Write(Output, chr(Temp));
  end;

  if BufLength <> 0 then begin
    LastNulls := 8 - BufLength;
    Buffer := Buffer shr LastNulls;
    Buffer := Buffer shr 24;
    Write(Output, chr(Buffer));
  end;

  if (LastNulls < 8) and (LastNulls > 0) then
    Write(Output, chr(LastNulls))
  else
    Write(Output, chr(11));

  msInput.Free;
  Close(Output);
end;

function THuffman.GetFrequency(var MStream: TmemoryStream): FrequencyTable;
var
  SizeOfFile: int64;
  Symbol: byte;
  i: byte;
begin
  MStream.Seek(0, soBeginning);
  for i := 0 to 255 do
    Result[i] := 0;
  SizeOfFile := MStream.Size;
  while SizeOfFile <> 0 do begin
    Symbol := MStream.ReadByte;
    Result[Symbol] += 1;
    SizeOfFile -= 1;
  end;
  MStream.Seek(0, soBeginning);
end;

function THuffman.ReadTitle(MStream: TMemoryStream): LengthCache;
var
  i: byte;
  Symbol: byte;
  Byte_s: string;
begin
  Byte_s := '';
  for i := 0 to 3 do begin
    Symbol := MStream.ReadByte;
    Byte_s += chr(Symbol);
  end;
  if Byte_s <> 'SOLG' then begin
    writeln('Incorrect file format');
    readln;
    exit;
  end;
  for i := 0 to 255 do begin
    Symbol := MStream.ReadByte;
    Result[i] := Symbol;
  end;
end;

procedure THuffman.WriteTitle(var Output_: Text);
var
  i: byte;
begin
  Write(Output_, 'SOLG');
  for i := 0 to 255 do
    Write(Output_, chr(LCache[i]));
end;

end.
