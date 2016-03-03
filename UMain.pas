program UMain;

uses
  UTree,
  SysUtils,
  Classes,
  UPackUnpack,
  UBitOps,
  Crt;

var
  FPack: THuffman;
  Input: string;

begin
  Tree := THuffmanTree.Create;
  BitOps := TBitOps.Create;

  writeln('DWORDhivator beta build 0.0.0');
  while (Input <> 'p') and (Input <> 'u') do begin
    writeln('write p/u to pack/unpack');
    readln(Input);
  end;
  if Input = 'p' then begin
    Fpack := THuffman.Create('*');
    Fpack.Pack;
  end
  else begin
    Fpack := THuffman.Create('*.testpb');
    writeln('Start unpacking...');
    Fpack.Unpack;
  end;

end.
