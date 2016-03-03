unit UTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, crt, UBitOps;

type
  NodePtr = ^Node;

  Node = record
    Key: byte;
    Weight: longint;
    Prev: NodePtr;
    Next: NodePtr;
    Right: NodePtr;
    Left: NodePtr;
    IsLeave: boolean;
  end;

  THuffmanTree = class
  public
    constructor Create;
    function GetCache(FTable: FrequencyTable): Cache;
    function MakeTree(FTable: FrequencyTable): NodePtr;
    function GetBCache(LCache: LengthCache): BitCache;
    function GetFTable(LCache: LengthCache): FrequencyTable;
  private
    Qhead: NodePtr;
    Routes: Cache;
    procedure GetRoutes(Root: NodePtr; Str: string);
    function CreateNode(Key: byte; Weight: longint): NodePtr;
    function Merge(Node_A, Node_B: NodePtr): NodePtr;
    procedure AddToQueue(NewNode: NodePtr);
    function Pop: NodePtr;
  end;

var
  Tree: THuffmanTree;

implementation

constructor THuffmanTree.Create;
begin

end;

function THuffmanTree.GetCache(FTable: FrequencyTable): Cache;
var
  Root: NodePtr;
begin
  Root := MakeTree(FTable);
  if (Root^.Right = nil) and (Root^.Left = nil) then
    Routes[Root^.Key] := '1'
  else
    GetRoutes(Root, '');
  Result := routes;
end;

function THuffmanTree.MakeTree(FTable: FrequencyTable): NodePtr;
var
  i: integer;
  Root: NodePtr;
  NewNode: NodePtr;
begin
  new(Qhead);
  Qhead^.Next := nil;
  Qhead^.Prev := nil;
  for i := 0 to 255 do begin
    if FTable[i] > 0 then begin
      NewNode := CreateNode(i, FTable[i]);
      AddToQueue(NewNode);
    end;
  end;
  if Qhead^.Next^.Next = nil then begin
    Result := Pop;
    exit;
  end;
  while Qhead^.Next^.Next <> nil do begin
    Root := Merge(Pop, Pop);
    AddToQueue(Root);
  end;
  Result := Root;
end;

function THuffmanTree.GetBCache(LCache: LengthCache): BitCache;
var
  Root: NodePtr;
  FTable: FrequencyTable;
begin
  FTable := GetFTable(LCache);
  Root := MakeTree(FTable);
  GetRoutes(Root, '');
  Result := BitOps.GetBitCache(Routes);
end;

function THuffmanTree.GetFTable(LCache: LengthCache): FrequencyTable;
var
  Weights: array [0..24] of longword;
  i: byte;
begin
  Weights[0] := 0;
  Weights[1] := 8388608;
  for i := 2 to 24 do
    Weights[i] := Weights[i - 1] div 2;
  for i := 0 to 255 do
    Result[i] := Weights[LCache[i]];
end;

procedure THuffmanTree.GetRoutes(Root: NodePtr; Str: string);
begin
  if Root^.Right <> nil then
    GetRoutes(Root^.Right, Str + '1');
  if Root^.IsLeave = True then
    Routes[Root^.Key] := Str;
  if Root^.Left <> nil then
    GetRoutes(Root^.Left, Str + '0');
end;

function THuffmanTree.CreateNode(Key: byte; Weight: longint): NodePtr;
begin
  new(Result);
  Result^.Key := Key;
  Result^.Weight := Weight;
  Result^.Prev := nil;
  Result^.Next := nil;
  Result^.Right := nil;
  Result^.Left := nil;
  Result^.IsLeave := True;
end;

function THuffmanTree.Merge(Node_A, Node_B: NodePtr): NodePtr;
begin
  new(Result);
  Result^.Key := 0;
  Result^.Prev := nil;
  Result^.Next := nil;
  Result^.Right := Node_B;
  Result^.Left := Node_A;
  Result^.IsLeave := False;
  Result^.Weight := Node_A^.Weight + Node_B^.Weight;
end;

procedure THuffmanTree.AddToQueue(NewNode: NodePtr);
var
  Temp: NodePtr;
  TempPtr: NodePtr;
begin
  if Qhead^.Next = nil then begin
    Qhead^.Next := NewNode;
    NewNode^.Prev := Qhead;
  end
  else begin
    Temp := Qhead^.Next;
    while (Temp^.Next <> nil) and (Temp^.Weight < NewNode^.Weight) do
      Temp := Temp^.Next;
    if (Temp^.Next = nil) and (NewNode^.Weight > Temp^.Weight) then begin
      Temp^.Next := NewNode;
      NewNode^.Prev := Temp;
      NewNode^.Next := nil;
    end
    else begin
      TempPtr := Temp^.Prev;
      Temp^.Prev := NewNode;
      NewNode^.Next := Temp;
      NewNode^.Prev := TempPtr;
      NewNode^.Prev^.Next := NewNode;
    end;
  end;
end;

function THuffmanTree.Pop: NodePtr;
begin
  Result := Qhead^.Next;
  if Qhead^.Next <> nil then begin
    Qhead^.Next := Result^.Next;
    if Qhead^.Next <> nil then
      Qhead^.Next^.Prev := Qhead;
  end;
end;

end.
