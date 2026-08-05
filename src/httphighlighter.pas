unit httphighlighter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, SynEditHighlighter;

type

  THTTPTokenKind = (
    tkDefault,
    tkMethod,
    tkURL,
    tkHeaderKey,
    tkHeaderValue,
    tkBodyKey,
    tkBodyValue,
    tkBodyNumber,
    tkBodySymbol
  );

  { THTTPHighlighter }

  THTTPHighlighter = class(TSynCustomHighlighter)
  private
    FLine:       string;
    FLineIndex:  Integer;
    FPos:        Integer;
    FLineLen:    Integer;
    FTokenStart: Integer;
    FTokenKind:  THTTPTokenKind;
    FInBody:     Boolean;

    FAttrMethod:      TSynHighlighterAttributes;
    FAttrURL:         TSynHighlighterAttributes;
    FAttrHeaderKey:   TSynHighlighterAttributes;
    FAttrHeaderValue: TSynHighlighterAttributes;
    FAttrBodyKey:     TSynHighlighterAttributes;
    FAttrBodyValue:   TSynHighlighterAttributes;
    FAttrBodyNumber:  TSynHighlighterAttributes;
    FAttrBodySymbol:  TSynHighlighterAttributes;
    FAttrDefault:     TSynHighlighterAttributes;

    procedure ScanFirstLine;
    procedure ScanHeaderLine;
    procedure ScanBodyLine;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetLine(const NewValue: string; LineNumber: Integer); override;
    procedure Next; override;
    function  GetEol: Boolean; override;
    function  GetTokenAttribute: TSynHighlighterAttributes; override;
    function  GetTokenKind: Integer; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: Integer); override;
    function  GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes; override;
  end;

implementation

const
  HTTP_METHODS: array[0..7] of string = (
    'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS', 'CONNECT'
  );

function IsHTTPMethod(const S: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(HTTP_METHODS) to High(HTTP_METHODS) do
    if S = HTTP_METHODS[i] then
    begin
      Result := True;
      Exit;
    end;
end;

{ THTTPHighlighter }

constructor THTTPHighlighter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAttrMethod := TSynHighlighterAttributes.Create('Method', 'Method');
  FAttrMethod.Foreground := $00C56A31;
  FAttrMethod.Style := [fsBold];
  AddAttribute(FAttrMethod);

  FAttrURL := TSynHighlighterAttributes.Create('URL', 'URL');
  FAttrURL.Foreground := $00207020;
  AddAttribute(FAttrURL);

  FAttrHeaderKey := TSynHighlighterAttributes.Create('HeaderKey', 'Header Key');
  FAttrHeaderKey.Foreground := $00A05000;
  FAttrHeaderKey.Style := [fsBold];
  AddAttribute(FAttrHeaderKey);

  FAttrHeaderValue := TSynHighlighterAttributes.Create('HeaderValue', 'Header Value');
  FAttrHeaderValue.Foreground := $00505050;
  AddAttribute(FAttrHeaderValue);

  FAttrBodyKey := TSynHighlighterAttributes.Create('BodyKey', 'JSON Key');
  FAttrBodyKey.Foreground := $00A05000;
  AddAttribute(FAttrBodyKey);

  FAttrBodyValue := TSynHighlighterAttributes.Create('BodyValue', 'JSON String Value');
  FAttrBodyValue.Foreground := $00207020;
  AddAttribute(FAttrBodyValue);

  FAttrBodyNumber := TSynHighlighterAttributes.Create('BodyNumber', 'JSON Number/Bool/Null');
  FAttrBodyNumber.Foreground := $00C56A31;
  AddAttribute(FAttrBodyNumber);

  FAttrBodySymbol := TSynHighlighterAttributes.Create('BodySymbol', 'JSON Symbol');
  FAttrBodySymbol.Foreground := $00808080;
  AddAttribute(FAttrBodySymbol);

  FAttrDefault := TSynHighlighterAttributes.Create('Default', 'Default');
  AddAttribute(FAttrDefault);

  FInBody := False;
end;

procedure THTTPHighlighter.SetLine(const NewValue: string; LineNumber: Integer);
begin
  inherited SetLine(NewValue, LineNumber);
  FLine      := NewValue;
  FLineIndex := LineNumber;
  FLineLen   := Length(FLine);
  FPos       := 1;

  if LineNumber = 0 then
    FInBody := False
  else
    FInBody := (GetRange = Pointer(1));

  if (Trim(FLine) = '') and (not FInBody) and (LineNumber > 0) then
  begin
    FInBody := True;
    SetRange(Pointer(1));
  end;

  Next;
end;

procedure THTTPHighlighter.ScanFirstLine;
var
  SpacePos: Integer;
  Word: string;
begin
  if FPos > FLineLen then Exit;
  SpacePos := Pos(' ', FLine);

  if (FTokenStart = 1) and (SpacePos > 1) then
  begin
    Word := Copy(FLine, 1, SpacePos - 1);
    if IsHTTPMethod(Word) then
    begin
      FTokenKind := tkMethod;
      FPos := SpacePos;
      Exit;
    end;
  end;

  if (FPos <= FLineLen) and (FLine[FPos] = ' ') then
  begin
    FTokenKind := tkDefault;
    Inc(FPos);
    Exit;
  end;

  FTokenKind := tkURL;
  FPos := FLineLen + 1;
end;

procedure THTTPHighlighter.ScanHeaderLine;
var
  ColonPos: Integer;
begin
  if FPos > FLineLen then Exit;
  ColonPos := Pos(':', FLine);

  if (ColonPos > 0) and (FTokenStart < ColonPos) then
  begin
    FTokenKind := tkHeaderKey;
    FPos := ColonPos;
  end
  else if (ColonPos > 0) and (FTokenStart = ColonPos) then
  begin
    FTokenKind := tkDefault;
    Inc(FPos);
  end
  else
  begin
    FTokenKind := tkHeaderValue;
    FPos := FLineLen + 1;
  end;
end;

procedure THTTPHighlighter.ScanBodyLine;
var
  C: Char;
  PeekPos: Integer;
begin
  if FPos > FLineLen then Exit;
  C := FLine[FPos];

  case C of
    '{', '}', '[', ']', ':', ',':
      begin
        FTokenKind := tkBodySymbol;
        Inc(FPos);
      end;
    '"':
      begin
        Inc(FPos);
        while (FPos <= FLineLen) and (FLine[FPos] <> '"') do
        begin
          if FLine[FPos] = '\' then Inc(FPos);
          Inc(FPos);
        end;
        if FPos <= FLineLen then Inc(FPos);
        PeekPos := FPos;
        while (PeekPos <= FLineLen) and (FLine[PeekPos] = ' ') do
          Inc(PeekPos);
        if (PeekPos <= FLineLen) and (FLine[PeekPos] = ':') then
          FTokenKind := tkBodyKey
        else
          FTokenKind := tkBodyValue;
      end;
    '0'..'9', '-':
      begin
        while (FPos <= FLineLen) and
              (FLine[FPos] in ['0'..'9', '.', 'e', 'E', '+', '-']) do
          Inc(FPos);
        FTokenKind := tkBodyNumber;
      end;
    't', 'f', 'n':
      begin
        while (FPos <= FLineLen) and (FLine[FPos] in ['a'..'z']) do
          Inc(FPos);
        FTokenKind := tkBodyNumber;
      end;
    ' ', #9:
      begin
        while (FPos <= FLineLen) and (FLine[FPos] in [' ', #9]) do
          Inc(FPos);
        FTokenKind := tkDefault;
      end;
  else
    Inc(FPos);
    FTokenKind := tkDefault;
  end;
end;

procedure THTTPHighlighter.Next;
begin
  FTokenStart := FPos;
  if FPos > FLineLen then
  begin
    FTokenKind := tkDefault;
    Exit;
  end;

  if FInBody then
    ScanBodyLine
  else if FLineIndex = 0 then
    ScanFirstLine
  else
    ScanHeaderLine;
end;

function THTTPHighlighter.GetEol: Boolean;
begin
  Result := FTokenStart > FLineLen;
end;

function THTTPHighlighter.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case FTokenKind of
    tkMethod:      Result := FAttrMethod;
    tkURL:         Result := FAttrURL;
    tkHeaderKey:   Result := FAttrHeaderKey;
    tkHeaderValue: Result := FAttrHeaderValue;
    tkBodyKey:     Result := FAttrBodyKey;
    tkBodyValue:   Result := FAttrBodyValue;
    tkBodyNumber:  Result := FAttrBodyNumber;
    tkBodySymbol:  Result := FAttrBodySymbol;
  else
    Result := FAttrDefault;
  end;
end;

function THTTPHighlighter.GetTokenKind: Integer;
begin
  Result := Ord(FTokenKind);
end;

procedure THTTPHighlighter.GetTokenEx(out TokenStart: PChar; out TokenLength: Integer);
begin
  TokenStart  := PChar(FLine) + FTokenStart - 1;
  TokenLength := FPos - FTokenStart;
end;

function THTTPHighlighter.GetDefaultAttribute(Index: Integer): TSynHighlighterAttributes;
begin
  Result := FAttrDefault;
end;

end.
