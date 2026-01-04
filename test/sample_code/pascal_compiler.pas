program PascalCompiler;

{ 
  Pascal Code Compiler and Parser
  Demonstrates Pascal records, classes, units, and structured programming
}

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, RegexPR;

type
  { Token types for lexical analysis }
  TTokenType = (ttIdentifier, ttNumber, ttString, ttOperator, ttKeyword, 
                ttSymbol, ttComment, ttWhitespace, ttUnknown);
  
  { Represents a lexical token }
  TToken = record
    TokenType: TTokenType;
    Value: string;
    Line: Integer;
    Column: Integer;
    Position: Integer;
  end;
  
  { AST node types }
  TAstNodeType = (ntProgram, ntUnit, ntUses, ntVarDecl, ntConstDecl, 
                  ntFunctionDecl, ntProcedureDecl, ntBeginEnd, ntAssignment,
                  ntIfStatement, ntWhileStatement, ntForStatement, ntExpression,
                  ntIdentifier, ntNumber, ntString);
  
  { Abstract Syntax Tree node }
  TAstNode = class
  public
    NodeType: TAstNodeType;
    Value: string;
    Line: Integer;
    Column: Integer;
    Children: array of TAstNode;
    
    constructor Create(ANodeType: TAstNodeType; AValue: string = '');
    destructor Destroy; override;
    procedure AddChild(Child: TAstNode);
    function GetChild(Index: Integer): TAstNode;
    function GetChildCount: Integer;
  end;
  
  { Pascal symbol table entry }
  TSymbol = record
    Name: string;
    SymbolType: string;
    DataType: string;
    Line: Integer;
    Column: Integer;
    IsConstant: Boolean;
    IsVariable: Boolean;
    IsFunction: Boolean;
    IsProcedure: Boolean;
  end;
  
  { Symbol table for scope management }
  TSymbolTable = class
  private
    FSymbols: array of TSymbol;
    FCapacity: Integer;
    FCount: Integer;
    FParent: TSymbolTable;
    FName: string;
    
  public
    constructor Create(AParent: TSymbolTable = nil; AName: string = '');
    destructor Destroy; override;
    function AddSymbol(const Name, SymbolType, DataType: string; 
                      IsConstant, IsVariable, IsFunction, IsProcedure: Boolean;
                      Line, Column: Integer): Boolean;
    function FindSymbol(const Name: string): Integer;
    function GetSymbol(Index: Integer): TSymbol;
    function GetSymbolCount: Integer;
    property Parent: TSymbolTable read FParent;
    property Name: string read FName;
  end;
  
  { Lexical analyzer for Pascal code }
  TLexer = class
  private
    FSource: string;
    FPosition: Integer;
    FLine: Integer;
    FColumn: Integer;
    FCurrentChar: Char;
    
    function IsLetter(C: Char): Boolean;
    function IsDigit(C: Char): Boolean;
    function IsIdentifierChar(C: Char): Boolean;
    procedure NextChar;
    function PeekChar: Char;
    
  public
    constructor Create(const ASource: string);
    destructor Destroy; override;
    function NextToken: TToken;
    function GetPosition: Integer;
    function GetLineNumber: Integer;
    function GetColumnNumber: Integer;
  end;
  
  { Parser for Pascal syntax }
  TParser = class
  private
    FLexer: TLexer;
    FCurrentToken: TToken;
    FAstRoot: TAstNode;
    FSymbolTable: TSymbolTable;
    FErrors: array of string;
    FErrorCount: Integer;
    
    procedure NextToken;
    function Expect(TokenType: TTokenType; const Value: string = ''): Boolean;
    function Match(TokenType: TTokenType; const Value: string = ''): Boolean;
    procedure AddError(const Message: string);
    
    { Parsing methods }
    function ParseProgram: TAstNode;
    function ParseUsesClause: TAstNode;
    function ParseDeclarations: TAstNode;
    function ParseBlock: TAstNode;
    function ParseStatement: TAstNode;
    function ParseAssignment: TAstNode;
    function ParseIfStatement: TAstNode;
    function ParseWhileStatement: TAstNode;
    function ParseForStatement: TAstNode;
    function ParseExpression: TAstNode;
    function ParseTerm: TAstNode;
    function ParseFactor: TAstNode;
    
  public
    constructor Create(const ASource: string);
    destructor Destroy; override;
    function Parse: Boolean;
    function GetAstRoot: TAstNode;
    function GetSymbolTable: TSymbolTable;
    function GetErrors: TArray<string>;
    function GetErrorCount: Integer;
  end;
  
  { Pascal compiler main class }
  TPascalCompiler = class
  private
    FSource: string;
    FLexer: TLexer;
    FParser: TParser;
    FTokens: array of TToken;
    FAstRoot: TAstNode;
    FSymbolTable: TSymbolTable;
    
  public
    constructor Create(const ASource: string);
    destructor Destroy; override;
    function Compile: Boolean;
    function GetTokens: TArray<TToken>;
    function GetAst: TAstNode;
    function GetSymbolTable: TSymbolTable;
    function GetErrors: TArray<string>;
    procedure PrintTokens;
    procedure PrintAst(Node: TAstNode; Indent: Integer = 0);
  end;

{ TAstNode implementation }
constructor TAstNode.Create(ANodeType: TAstNodeType; AValue: string = '');
begin
  NodeType := ANodeType;
  Value := AValue;
  SetLength(Children, 0);
  Line := 0;
  Column := 0;
end;

destructor TAstNode.Destroy;
var
  i: Integer;
begin
  for i := 0 to High(Children) do
    if Children[i] <> nil then
      Children[i].Free;
  SetLength(Children, 0);
  inherited Destroy;
end;

procedure TAstNode.AddChild(Child: TAstNode);
begin
  SetLength(Children, Length(Children) + 1);
  Children[High(Children)] := Child;
  if Child <> nil then
  begin
    Child.Line := Line;
    Child.Column := Column;
  end;
end;

function TAstNode.GetChild(Index: Integer): TAstNode;
begin
  if (Index >= 0) and (Index < Length(Children)) then
    Result := Children[Index]
  else
    Result := nil;
end;

function TAstNode.GetChildCount: Integer;
begin
  Result := Length(Children);
end;

{ TSymbolTable implementation }
constructor TSymbolTable.Create(AParent: TSymbolTable = nil; AName: string = '');
begin
  FCapacity := 16;
  SetLength(FSymbols, FCapacity);
  FCount := 0;
  FParent := AParent;
  FName := AName;
end;

destructor TSymbolTable.Destroy;
begin
  SetLength(FSymbols, 0);
  inherited Destroy;
end;

function TSymbolTable.AddSymbol(const Name, SymbolType, DataType: string; 
  IsConstant, IsVariable, IsFunction, IsProcedure: Boolean;
  Line, Column: Integer): Boolean;
var
  Index: Integer;
begin
  // Check if symbol already exists in current scope
  Index := FindSymbol(Name);
  if Index >= 0 then
  begin
    Result := False;
    Exit;
  end;
  
  // Expand array if needed
  if FCount >= FCapacity then
  begin
    FCapacity := FCapacity * 2;
    SetLength(FSymbols, FCapacity);
  end;
  
  // Add new symbol
  with FSymbols[FCount] do
  begin
    Self.Name := Name;
    Self.SymbolType := SymbolType;
    Self.DataType := DataType;
    Self.Line := Line;
    Self.Column := Column;
    Self.IsConstant := IsConstant;
    Self.IsVariable := IsVariable;
    Self.IsFunction := IsFunction;
    Self.IsProcedure := IsProcedure;
  end;
  
  Inc(FCount);
  Result := True;
end;

function TSymbolTable.FindSymbol(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
  begin
    if FSymbols[i].Name = Name then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

function TSymbolTable.GetSymbol(Index: Integer): TSymbol;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FSymbols[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TSymbolTable.GetSymbolCount: Integer;
begin
  Result := FCount;
end;

{ TLexer implementation }
constructor TLexer.Create(const ASource: string);
begin
  FSource := ASource;
  FPosition := 1;
  FLine := 1;
  FColumn := 1;
  NextChar;
end;

destructor TLexer.Destroy;
begin
  inherited Destroy;
end;

function TLexer.IsLetter(C: Char): Boolean;
begin
  Result := (C >= 'A') and (C <= 'Z') or (C >= 'a') and (C <= 'z') or (C = '_');
end;

function TLexer.IsDigit(C: Char): Boolean;
begin
  Result := (C >= '0') and (C <= '9');
end;

function TLexer.IsIdentifierChar(C: Char): Boolean;
begin
  Result := IsLetter(C) or IsDigit(C);
end;

procedure TLexer.NextChar;
begin
  if FPosition <= Length(FSource) then
  begin
    if FSource[FPosition] = #10 then
    begin
      Inc(FLine);
      FColumn := 1;
    end
    else
      Inc(FColumn);
    
    FCurrentChar := FSource[FPosition];
    Inc(FPosition);
  end
  else
    FCurrentChar := #0;
end;

function TLexer.PeekChar: Char;
begin
  if FPosition <= Length(FSource) then
    Result := FSource[FPosition]
  else
    Result := #0;
end;

function TLexer.NextToken: TToken;
var
  StartPos: Integer;
  TokenType: TTokenType;
  TokenValue: string;
  
begin
  StartPos := FPosition;
  
  // Skip whitespace
  while (FCurrentChar in [' ', #9, #13, #10]) do
    NextChar;
  
  // Initialize token
  FillChar(Result, SizeOf(Result), 0);
  Result.Line := FLine;
  Result.Column := FColumn;
  Result.Position := StartPos;
  
  // Handle end of input
  if FCurrentChar = #0 then
  begin
    Result.TokenType := ttUnknown;
    Result.Value := 'EOF';
    Exit;
  end;
  
  // Handle comments
  if (FCurrentChar = '{') or ((FCurrentChar = '(') and (PeekChar = '*')) then
  begin
    TokenType := ttComment;
    TokenValue := FCurrentChar;
    NextChar;
    
    if FCurrentChar = '{' then
    begin
      // Pascal-style comment: { ... }
      while (FCurrentChar <> '}') and (FCurrentChar <> #0) do
      begin
        TokenValue := TokenValue + FCurrentChar;
        NextChar;
      end;
      if FCurrentChar = '}' then
      begin
        TokenValue := TokenValue + '}';
        NextChar;
      end;
    end
    else
    begin
      // Delphi-style comment: (* ... *)
      TokenValue := TokenValue + '*';
      NextChar;
      while not ((FCurrentChar = '*') and (PeekChar = ')')) and (FCurrentChar <> #0) do
      begin
        TokenValue := TokenValue + FCurrentChar;
        NextChar;
      end;
      if (FCurrentChar = '*') and (PeekChar = ')') then
      begin
        TokenValue := TokenValue + '*)';
        NextChar;
        NextChar;
      end;
    end;
  end
  
  // Handle strings
  else if FCurrentChar = '''' then
  begin
    TokenType := ttString;
    TokenValue := '';
    NextChar; // Skip opening quote
    
    while (FCurrentChar <> '''') and (FCurrentChar <> #0) do
    begin
      if FCurrentChar = #10 then
      begin
        Inc(FLine);
        FColumn := 1;
      end;
      TokenValue := TokenValue + FCurrentChar;
      NextChar;
    end;
    
    if FCurrentChar = '''' then
      NextChar; // Skip closing quote
  end
  
  // Handle numbers
  else if IsDigit(FCurrentChar) then
  begin
    TokenType := ttNumber;
    TokenValue := '';
    
    while IsDigit(FCurrentChar) do
    begin
      TokenValue := TokenValue + FCurrentChar;
      NextChar;
    end;
    
    // Handle decimal numbers
    if (FCurrentChar = '.') and IsDigit(PeekChar) then
    begin
      TokenValue := TokenValue + '.';
      NextChar;
      while IsDigit(FCurrentChar) do
      begin
        TokenValue := TokenValue + FCurrentChar;
        NextChar;
      end;
    end;
  end
  
  // Handle identifiers and keywords
  else if IsLetter(FCurrentChar) then
  begin
    TokenValue := '';
    while IsIdentifierChar(FCurrentChar) do
    begin
      TokenValue := TokenValue + FCurrentChar;
      NextChar;
    end;
    
    // Check if it's a keyword
    if UpperCase(TokenValue) = 'PROGRAM' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'UNIT' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'USES' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'VAR' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'CONST' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'FUNCTION' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'PROCEDURE' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'BEGIN' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'END' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'IF' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'THEN' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'ELSE' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'WHILE' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'DO' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'FOR' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'TO' then
      TokenType := ttKeyword
    else if UpperCase(TokenValue) = 'DOWNTO' then
      TokenType := ttKeyword
    else
      TokenType := ttIdentifier;
  end
  
  // Handle operators and symbols
  else
  begin
    case FCurrentChar of
      '+', '-', '*', '/', '=', '<', '>', ':', '&', '|', '^', '~':
        begin
          TokenType := ttOperator;
          TokenValue := FCurrentChar;
          NextChar;
        end;
      ';', ',', '.', ':', '(', ')', '[', ']', '{', '}', '!', '?', '@', '#', '$', '%':
        begin
          TokenType := ttSymbol;
          TokenValue := FCurrentChar;
          NextChar;
        end;
      else
        begin
          TokenType := ttUnknown;
          TokenValue := FCurrentChar;
          NextChar;
        end;
    end;
  end;
  
  Result.TokenType := TokenType;
  Result.Value := TokenValue;
end;

function TLexer.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TLexer.GetLineNumber: Integer;
begin
  Result := FLine;
end;

function TLexer.GetColumnNumber: Integer;
begin
  Result := FColumn;
end;

{ TParser implementation }
constructor TParser.Create(const ASource: string);
begin
  FLexer := TLexer.Create(ASource);
  FCurrentToken.TokenType := ttUnknown;
  FAstRoot := nil;
  FSymbolTable := TSymbolTable.Create(nil, 'Global');
  SetLength(FErrors, 0);
  FErrorCount := 0;
end;

destructor TParser.Destroy;
begin
  if FAstRoot <> nil then
    FAstRoot.Free;
  FLexer.Free;
  inherited Destroy;
end;

procedure TParser.NextToken;
begin
  FCurrentToken := FLexer.NextToken;
end;

function TParser.Expect(TokenType: TTokenType; const Value: string = ''): Boolean;
begin
  Result := False;
  
  if (FCurrentToken.TokenType = TokenType) and 
     ((Value = '') or (FCurrentToken.Value = Value)) then
  begin
    NextToken;
    Result := True;
  end
  else
    AddError(Format('Expected %s but found %s', [Value, FCurrentToken.Value]));
end;

function TParser.Match(TokenType: TTokenType; const Value: string = ''): Boolean;
begin
  Result := (FCurrentToken.TokenType = TokenType) and 
            ((Value = '') or (FCurrentToken.Value = Value));
end;

procedure TParser.AddError(const Message: string);
begin
  SetLength(FErrors, FErrorCount + 1);
  FErrors[FErrorCount] := Format('Line %d, Column %d: %s', 
    [FCurrentToken.Line, FCurrentToken.Column, Message]);
  Inc(FErrorCount);
end;

function TParser.Parse: Boolean;
begin
  NextToken;
  FAstRoot := ParseProgram;
  Result := (FErrorCount = 0);
end;

function TParser.ParseProgram: TAstNode;
var
  ProgramNode: TAstNode;
  IdentifierNode: TAstNode;
begin
  Result := TAstNode.Create(ntProgram);
  ProgramNode := Result;
  
  // Parse 'program' keyword
  if Expect(ttKeyword, 'program') then
  begin
    // Parse program name
    if FCurrentToken.TokenType = ttIdentifier then
    begin
      IdentifierNode := TAstNode.Create(ntIdentifier, FCurrentToken.Value);
      ProgramNode.AddChild(IdentifierNode);
      NextToken;
    end;
    
    // Parse semicolon
    Expect(ttSymbol, ';');
    
    // Parse uses clause
    if Match(ttKeyword, 'uses') then
      ProgramNode.AddChild(ParseUsesClause);
    
    // Parse declarations
    ProgramNode.AddChild(ParseDeclarations);
    
    // Parse main block
    ProgramNode.AddChild(ParseBlock);
    
    // Parse final period
    Expect(ttSymbol, '.');
  end
  else
    AddError('Expected program declaration');
    
  Result := ProgramNode;
end;

function TParser.ParseUsesClause: TAstNode;
begin
  Result := TAstNode.Create(ntUses);
  NextToken; // Skip 'uses'
  
  repeat
    if FCurrentToken.TokenType = ttIdentifier then
    begin
      Result.AddChild(TAstNode.Create(ntIdentifier, FCurrentToken.Value));
      NextToken;
    end;
  until not Match(ttSymbol, ',');
  
  Expect(ttSymbol, ';');
end;

function TParser.ParseDeclarations: TAstNode;
begin
  Result := TAstNode.Create(ntVarDecl);
  
  // Parse variable declarations
  while Match(ttKeyword, 'var') do
  begin
    NextToken; // Skip 'var'
    // Simple variable declaration parsing
    while FCurrentToken.TokenType = ttIdentifier do
    begin
      Result.AddChild(TAstNode.Create(ntVarDecl, FCurrentToken.Value));
      NextToken;
      if Match(ttSymbol, ':') then
      begin
        NextToken;
        if FCurrentToken.TokenType = ttIdentifier then
        begin
          Result.AddChild(TAstNode.Create(ntIdentifier, FCurrentToken.Value));
          NextToken;
        end;
      end;
      Expect(ttSymbol, ';');
    end;
  end;
  
  // Parse constant declarations
  while Match(ttKeyword, 'const') do
  begin
    NextToken; // Skip 'const'
    while FCurrentToken.TokenType = ttIdentifier do
    begin
      Result.AddChild(TAstNode.Create(ntConstDecl, FCurrentToken.Value));
      NextToken;
      Expect(ttOperator, '=');
      // Parse constant value (simplified)
      if FCurrentToken.TokenType in [ttNumber, ttString, ttIdentifier] then
      begin
        Result.AddChild(TAstNode.Create(ntExpression, FCurrentToken.Value));
        NextToken;
      end;
      Expect(ttSymbol, ';');
    end;
  end;
end;

function TParser.ParseBlock: TAstNode;
begin
  Result := TAstNode.Create(ntBeginEnd);
  
  if Expect(ttKeyword, 'begin') then
  begin
    // Parse statements
    while not Match(ttKeyword, 'end') do
    begin
      Result.AddChild(ParseStatement);
    end;
    
    Expect(ttKeyword, 'end');
  end;
end;

function TParser.ParseStatement: TAstNode;
begin
  if Match(ttKeyword, 'if') then
    Result := ParseIfStatement
  else if Match(ttKeyword, 'while') then
    Result := ParseWhileStatement
  else if Match(ttKeyword, 'for') then
    Result := ParseForStatement
  else if FCurrentToken.TokenType = ttIdentifier then
    Result := ParseAssignment
  else
  begin
    Result := TAstNode.Create(ntUnknown);
    NextToken; // Skip unexpected token
  end;
end;

function TParser.ParseAssignment: TAstNode;
var
  IdentifierNode: TAstNode;
  ExpressionNode: TAstNode;
begin
  Result := TAstNode.Create(ntAssignment);
  
  // Parse identifier
  if FCurrentToken.TokenType = ttIdentifier then
  begin
    IdentifierNode := TAstNode.Create(ntIdentifier, FCurrentToken.Value);
    Result.AddChild(IdentifierNode);
    NextToken;
  end;
  
  // Parse assignment operator
  if Match(ttOperator, ':') and Match(ttSymbol, '=') then
  begin
    NextToken; // Skip ':'
    NextToken; // Skip '='
  end
  else
    AddError('Expected assignment operator ":="');
  
  // Parse expression
  ExpressionNode := ParseExpression;
  Result.AddChild(ExpressionNode);
  
  // Expect semicolon
  Expect(ttSymbol, ';');
end;

function TParser.ParseIfStatement: TAstNode;
var
  ConditionNode: TAstNode;
  ThenNode: TAstNode;
  ElseNode: TAstNode;
begin
  Result := TAstNode.Create(ntIfStatement);
  NextToken; // Skip 'if'
  
  // Parse condition
  ConditionNode := ParseExpression;
  Result.AddChild(ConditionNode);
  
  Expect(ttKeyword, 'then');
  
  // Parse then statement
  ThenNode := ParseStatement;
  Result.AddChild(ThenNode);
  
  // Parse optional else clause
  if Match(ttKeyword, 'else') then
  begin
    NextToken; // Skip 'else'
    ElseNode := ParseStatement;
    Result.AddChild(ElseNode);
  end;
end;

function TParser.ParseWhileStatement: TAstNode;
var
  ConditionNode: TAstNode;
  StatementNode: TAstNode;
begin
  Result := TAstNode.Create(ntWhileStatement);
  NextToken; // Skip 'while'
  
  // Parse condition
  ConditionNode := ParseExpression;
  Result.AddChild(ConditionNode);
  
  Expect(ttKeyword, 'do');
  
  // Parse loop body
  StatementNode := ParseStatement;
  Result.AddChild(StatementNode);
end;

function TParser.ParseForStatement: TAstNode;
var
  VariableNode: TAstNode;
  StartNode: TAstNode;
  EndNode: TAstNode;
  StatementNode: TAstNode;
begin
  Result := TAstNode.Create(ntForStatement);
  NextToken; // Skip 'for'
  
  // Parse loop variable
  if FCurrentToken.TokenType = ttIdentifier then
  begin
    VariableNode := TAstNode.Create(ntIdentifier, FCurrentToken.Value);
    Result.AddChild(VariableNode);
    NextToken;
  end;
  
  Expect(ttOperator, ':=');
  
  // Parse start value
  StartNode := ParseExpression;
  Result.AddChild(StartNode);
  
  // Parse direction (to/downto)
  if Match(ttKeyword, 'to') or Match(ttKeyword, 'downto') then
  begin
    Result.AddChild(TAstNode.Create(ntIdentifier, FCurrentToken.Value));
    NextToken;
  end;
  
  // Parse end value
  EndNode := ParseExpression;
  Result.AddChild(EndNode);
  
  Expect(ttKeyword, 'do');
  
  // Parse loop body
  StatementNode := ParseStatement;
  Result.AddChild(StatementNode);
end;

function TParser.ParseExpression: TAstNode;
begin
  Result := ParseTerm;
  
  // Handle addition and subtraction
  while (FCurrentToken.TokenType = ttOperator) and 
        (FCurrentToken.Value[1] in ['+', '-']) do
  begin
    NextToken;
    Result.AddChild(ParseTerm);
  end;
end;

function TParser.ParseTerm: TAstNode;
begin
  Result := ParseFactor;
  
  // Handle multiplication and division
  while (FCurrentToken.TokenType = ttOperator) and 
        (FCurrentToken.Value[1] in ['*', '/']) do
  begin
    NextToken;
    Result.AddChild(ParseFactor);
  end;
end;

function TParser.ParseFactor: TAstNode;
begin
  if FCurrentToken.TokenType in [ttNumber, ttString] then
  begin
    if FCurrentToken.TokenType = ttNumber then
      Result := TAstNode.Create(ntNumber, FCurrentToken.Value)
    else
      Result := TAstNode.Create(ntString, FCurrentToken.Value);
    NextToken;
  end
  else if FCurrentToken.TokenType = ttIdentifier then
  begin
    Result := TAstNode.Create(ntIdentifier, FCurrentToken.Value);
    NextToken;
  end
  else if Match(ttSymbol, '(') then
  begin
    NextToken; // Skip '('
    Result := ParseExpression;
    Expect(ttSymbol, ')');
  end
  else
  begin
    Result := TAstNode.Create(ntUnknown);
    NextToken; // Skip unexpected token
  end;
end;

function TParser.GetAstRoot: TAstNode;
begin
  Result := FAstRoot;
end;

function TParser.GetSymbolTable: TSymbolTable;
begin
  Result := FSymbolTable;
end;

function TParser.GetErrors: TArray<string>;
begin
  Result := FErrors;
end;

function TParser.GetErrorCount: Integer;
begin
  Result := FErrorCount;
end;

{ TPascalCompiler implementation }
constructor TPascalCompiler.Create(const ASource: string);
begin
  FSource := ASource;
  FLexer := nil;
  FParser := nil;
  FAstRoot := nil;
  SetLength(FTokens, 0);
end;

destructor TPascalCompiler.Destroy;
begin
  if FAstRoot <> nil then
    FAstRoot.Free;
  if FParser <> nil then
    FParser.Free;
  inherited Destroy;
end;

function TPascalCompiler.Compile: Boolean;
begin
  Result := False;
  
  try
    FParser := TParser.Create(FSource);
    
    if FParser.Parse then
    begin
      FAstRoot := FParser.GetAstRoot;
      Result := True;
    end;
    
  except
    on E: Exception do
    begin
      // Handle compilation errors
      Result := False;
    end;
  end;
end;

function TPascalCompiler.GetTokens: TArray<TToken>;
begin
  Result := FTokens;
end;

function TPascalCompiler.GetAst: TAstNode;
begin
  Result := FAstRoot;
end;

function TPascalCompiler.GetSymbolTable: TSymbolTable;
begin
  if FParser <> nil then
    Result := FParser.GetSymbolTable
  else
    Result := nil;
end;

function TPascalCompiler.GetErrors: TArray<string>;
begin
  if FParser <> nil then
    Result := FParser.GetErrors
  else
    SetLength(Result, 0);
end;

procedure TPascalCompiler.PrintTokens;
var
  i: Integer;
  TokenTypeStr: string;
begin
  if FLexer = nil then Exit;
  
  WriteLn('Tokens:');
  WriteLn('--------');
  
  // This would require storing tokens during lexing
  // For now, just show token count
  WriteLn('Token analysis completed');
end;

procedure TPascalCompiler.PrintAst(Node: TAstNode; Indent: Integer = 0);
var
  i: Integer;
  IndentStr: string;
  NodeTypeStr: string;
begin
  if Node = nil then Exit;
  
  // Create indentation string
  SetLength(IndentStr, Indent * 2);
  FillChar(IndentStr[1], Indent * 2, ' ');
  
  // Convert node type to string
  case Node.NodeType of
    ntProgram: NodeTypeStr := 'PROGRAM';
    ntUnit: NodeTypeStr := 'UNIT';
    ntUses: NodeTypeStr := 'USES';
    ntVarDecl: NodeTypeStr := 'VAR_DECL';
    ntConstDecl: NodeTypeStr := 'CONST_DECL';
    ntFunctionDecl: NodeTypeStr := 'FUNCTION';
    ntProcedureDecl: NodeTypeStr := 'PROCEDURE';
    ntBeginEnd: NodeTypeStr := 'BEGIN_END';
    ntAssignment: NodeTypeStr := 'ASSIGNMENT';
    ntIfStatement: NodeTypeStr := 'IF_STATEMENT';
    ntWhileStatement: NodeTypeStr := 'WHILE_STATEMENT';
    ntForStatement: NodeTypeStr := 'FOR_STATEMENT';
    ntExpression: NodeTypeStr := 'EXPRESSION';
    ntIdentifier: NodeTypeStr := 'IDENTIFIER';
    ntNumber: NodeTypeStr := 'NUMBER';
    ntString: NodeTypeStr := 'STRING';
    else NodeTypeStr := 'UNKNOWN';
  end;
  
  WriteLn(IndentStr, NodeTypeStr, ': ', Node.Value);
  
  // Print children
  for i := 0 to Node.GetChildCount - 1 do
  begin
    PrintAst(Node.GetChild(i), Indent + 1);
  end;
end;

{ Test program }
var
  SourceCode: string;
  Compiler: TPascalCompiler;
  i: Integer;
  
begin
  SourceCode := 
    'program TestProgram;' + #13#10 +
    'var' + #13#10 +
    '  x, y: Integer;' + #13#10 +
    'begin' + #13#10 +
    '  x := 10;' + #13#10 +
    '  y := x + 5;' + #13#10 +
    '  if y > 15 then' + #13#10 +
    '    y := y * 2' + #13#10 +
    '  else' + #13#10 +
    '    y := y div 2;' + #13#10 +
    'end.' + #13#10;
  
  WriteLn('Pascal Compiler Test');
  WriteLn('====================');
  WriteLn;
  
  Compiler := TPascalCompiler.Create(SourceCode);
  
  try
    if Compiler.Compile then
    begin
      WriteLn('Compilation successful!');
      WriteLn;
      
      WriteLn('Abstract Syntax Tree:');
      Compiler.PrintAst(Compiler.GetAst);
    end
    else
    begin
      WriteLn('Compilation failed!');
      WriteLn('Errors:');
      for i := 0 to High(Compiler.GetErrors) do
        WriteLn('  ', Compiler.GetErrors[i]);
    end;
  finally
    Compiler.Free;
  end;
  
  WriteLn;
  WriteLn('Test completed.');
  ReadLn;
end.