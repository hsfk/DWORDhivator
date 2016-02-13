unit BitOps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  Cache = array [0..255] of string;
  BitCache = array [0..255] of word;
  LengthCache = array [0..255] of byte;

  Tbit = class
  public
    function GetBitCache(Routes: cache): BitCache;
    function GetLengthCache(Routes: cache): LengthCache;
  private
    procedure AddBitsToNum(var num: word; bits: string);
  end;

var
  BCache: BitCache;
  LCache: lengthCache;

implementation

function Tbit.GetBitCache(Routes: Cache): BitCache;
var
  i: byte;
begin
  for i := 0 to 255 do begin
    Result[i] := 0;
    AddBitsToNum(Result[i], Routes[i]);
  end;
end;

function Tbit.GetLengthCache(Routes: cache): LengthCache;
var
  i: byte;
begin
  for i := 0 to 255 do
    Result[i] := length(Routes[i]);
end;

procedure Tbit.AddBitsToNum(var num: word; bits: string);
//добавляет несколько бит в конец
var
  i: byte;
begin
  if bits = '' then begin
    num := 0;
    exit;
  end;

  for i := 0 to length(bits) - 1 do begin
    num := num shl 1;
    if bits[i + 1] <> '0' then
      num := num xor 1;
  end;
end;

end.
