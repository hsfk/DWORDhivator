program UMain;

uses
  UTree,
  SysUtils,
  Classes,
  UPackUnpack,
  crt, UFileAnalization;

var
  FPack: THuffman;
  filename, tmp: string;

  function GetFile(mask: string): string;
  var
    Info: TSearchRec;
    Files: TStringList;
    i, n: integer;
  begin
    clrscr;
    Result := '';
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
    while Result = '' do begin
      writeln('Input file number: ');
      Read(n);
      if (n - 1 < 0) or ((n - 1) > (i - 1)) then begin
        writeln('Input correct file number');
      end
      else
        Result := files[n - 1];
    end;
  end;

begin
  writeln('DWORDhivator beta build 0.0.0');
  tmp := '';
  while (tmp <> 'p') and (tmp <> 'u') do begin
    writeln('write p/u to pack/unpack');
    readln(tmp);
  end;
  if tmp = 'p' then begin
    filename := GetFile('*');
    if Fpack.Pack(filename) = false then
      writeln('smthng went wrong');
  end
  else begin
    filename := GetFile('*.testpb');
    writeln('start unpacking');
     if Fpack.Unpack(filename) = false then
       writeln('wrong format');
  end;
end.
