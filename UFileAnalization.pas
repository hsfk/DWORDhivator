unit UFileAnalization;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  FrequencyTable = array [0..255] of longword;

  blockptr = ^block;
  block = record
    t_num: int64;
    av_num: longword;
    amount: longword;
    FTable: FrequencyTable;
    nextBlock: blockPtr;
  end;

  TFile = class
  public
    function GetFrequency(var SomeStream: TmemoryStream): FrequencyTable;
  private
    procedure insert(e_num: longword; e_table: FrequencyTable);
    function CreateEmptyBlock: blockptr;
  end;

var
  QHead: blockptr;

implementation

function Tfile.GetFrequency(var SomeStream: TmemoryStream): FrequencyTable;
var
  sizeoffile: int64;
  symbol, i: byte;
begin
  SomeStream.Seek(0, soBeginning);
  for i := 0 to 255 do
    Result[i] := 0;
  sizeoffile := SomeStream.Size;

  while SizeOfFile <> 0 do begin
    symbol := SomeStream.ReadByte;
    Result[symbol] += 1;
    SizeOfFile -= 1;
  end;
  SomeStream.Seek(0, soBeginning);
end;

procedure TFile.insert(e_num: longword; e_table: FrequencyTable);
var
  i: integer;
  tmp, prev: blockptr;
begin
  if QHead^.amount = 0 then begin
    Qhead^.amount := 1;
    Qhead^.t_num := e_num;
    Qhead^.av_num := e_num;
    Qhead^.FTable := e_table;
    exit;
  end;

  tmp := Qhead;
  while tmp <> nil do begin
    if (e_num > round(tmp^.av_num * 0.66)) and (e_num < round(tmp^.av_num * 1.33))
    then begin
      tmp^.amount += 1;
      tmp^.t_num += e_num;
      tmp^.av_num := tmp^.t_num div tmp^.amount;
      for i := 0 to 255 do
        tmp^.FTable[i] += e_table[i];     //+
      exit;
    end;
    prev := tmp;
    tmp := tmp^.nextBlock;
  end;

  tmp := CreateEmptyBlock;
  prev^.nextBlock := tmp;
  tmp^.FTable := e_table;
  tmp^.t_num := e_num;
  tmp^.av_num := e_num;
  tmp^.amount := 1;
end;

function TFile.CreateEmptyBlock: blockptr;
var
  i: byte;
begin
  new(Result);
  Result^.amount := 0;
  Result^.av_num := 0;
  Result^.t_num := 0;
  Result^.nextBlock := nil;
  for i := 0 to 255 do
    Result^.FTable[i] := 0;
end;






















end.
