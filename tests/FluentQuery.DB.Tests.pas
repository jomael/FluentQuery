unit FluentQuery.DB.Tests;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  TestFramework, FluentQuery.Core.Types, FluentQuery.DB, Data.DB,
  FireDAC.Comp.Client, FLuentQuery.Tests.Base,  System.SysUtils;

type
  TestTDBRecord = class(TTestCase)
  strict private
    FMemTable : TFDMemTable;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestFieldByName;
    procedure TestEditAndPost;
    procedure TestEditAndCancel;
  end;

  TestTDBRecordQuery = class(TFluentQueryTestCase<TDBRecord>)
  strict private
    FMemTable : TFDMemTable;
    FTransformer : TFunc<TDBRecord, TDBRecord>;
    FAgeGreaterThan43 : TPredicate<TDBRecord>;
    procedure EmptyTable;
  public
    procedure SetUp; override;
    procedure TearDown; override;
    constructor Create(MethodName: string; RunCount: Int64); override;
  published
    procedure TestPassthroughEmptyDataset;
    procedure TestPassthrough;
    procedure TestWherePredicate;
    procedure TestStringField;
    procedure TestStringFieldAllMatch;
    procedure TestStringFieldNoMatch;
    procedure TestStringFieldNoField;
    procedure TestIntegerField;
    procedure TestFirst;
    procedure TestFirstEmpty;
    procedure TestCount;
    procedure TestCountEmpty;
    procedure TestTakeOne;
    procedure TestTakeZero;
    procedure TestSkipOne;
    procedure TestSkipZero;
    procedure TestMapResetAge;
    procedure TestNullFields;
    procedure TestNotNullFields;
  end;

implementation
uses
  FluentQuery.Strings,
  FluentQuery.Integers;

procedure InitMemTable(MemTable : TFDMemTable);
var
  LNameField, LAgeField, LNotesField : TFieldDef;
begin
  LNameField := MemTable.FieldDefs.AddFieldDef;
  LNameField.Name := 'Name';
  LNameField.DataType := ftString;
  LNameField.Size := 50;

  LAgeField := MemTable.FieldDefs.AddFieldDef;
  LAgeField.Name := 'Age';
  LAgeField.DataType := ftInteger;

  LNotesField := MemTable.FieldDefs.AddFieldDef;
  LNotesField.Name := 'Notes';
  LNotesField.DataType := ftMemo;

  MemTable.Open;
  MemTable.Append;
  MemTable.Fields[0].AsString := 'Malcolm';
  MemTable.Fields[1].AsInteger := 45;
  MemTable.Fields[2].AsString := 'whatevs';
  MemTable.Post;

  MemTable.Append;
  MemTable.Fields[0].AsString := 'Julie';
  MemTable.Fields[1].AsInteger := 43;
  MemTable.Post;
end;

constructor TestTDBRecordQuery.Create(MethodName: string; RunCount: Int64);
begin
  inherited;
  FTransformer := function(Value : TDBRecord) : TDBRecord
                  begin
                    Value.Edit;
                    Value.FieldByName('Age').AsInteger := 0;
                    Value.Post;
                    Result := Value;
                  end;
  FAgeGreaterThan43 :=  function(Value : TDBRecord) : boolean
                        begin
                          Result := Value.FieldByName('Age').AsInteger > 43;
                        end;
end;

procedure TestTDBRecordQuery.EmptyTable;
begin
  FMemTable.Last;
  repeat
    FMemTable.Delete;
  until (FMemTable.Bof);
end;

procedure TestTDBRecordQuery.SetUp;
begin
  FMemTable := TFDMemTable.Create(nil);
  InitMemTable(FMemTable)
end;

procedure TestTDBRecordQuery.TearDown;
begin
  FMemTable.Close;
  FMemTable.Free;
end;


procedure TestTDBRecordQuery.TestCount;
begin
  CheckEquals(2, DBRecordQuery.From(FMemTable).Count);
end;

procedure TestTDBRecordQuery.TestCountEmpty;
begin
  EmptyTable;
  CheckEquals(0, FMemTable.RecordCount, 'FMemTable should be empty at this point');
  CheckEquals(0, DBRecordQuery.From(FMemTable).Count);
end;

procedure TestTDBRecordQuery.TestFirst;
begin
  CheckEquals(45, DBRecordQuery.From(FMemTable).First.FieldByName('Age').AsInteger);
end;

procedure TestTDBRecordQuery.TestFirstEmpty;
begin
  EmptyTable;
  CheckEquals(0, FMemTable.RecordCount, 'FMemTable should be empty at this point');
  StartExpectingException(EEmptyResultSetException);
  DBRecordQuery.From(FMemTable).First;
  StopExpectingException;
end;

procedure TestTDBRecordQuery.TestIntegerField;
begin
  CheckExpectedCountWithInnerCheck(DBRecordQuery.From(FMemTable).IntegerField('Age', IntegerQuery.GreaterThan(44)),
                                   function (Arg : TDBRecord) : Boolean
                                   begin
                                     Result := Arg.FieldByName('Name').AsString = 'Malcolm';
                                   end,
                                   1, 'Name should be ''Malcolm''');
end;

procedure TestTDBRecordQuery.TestMapResetAge;
begin
  CheckExpectedCountWithInnerCheck(DBRecordQuery.From(FMemTable).Map(FTransformer),
                                   function (Arg : TDBRecord) : Boolean
                                   begin
                                     Result := Arg.FieldByName('Age').AsInteger = 0;
                                   end,
                                   2, 'Age should be 0');
end;

procedure TestTDBRecordQuery.TestNotNullFields;
begin
  CheckExpectedCountWithInnerCheck(DBRecordQuery.From(FMemTable).NotNull('Notes'),
                                   function (Arg : TDBRecord) : Boolean
                                   begin
                                     Result := Arg.FieldByName('Name').AsString = 'Malcolm';
                                   end,
                                   1, 'Name should be ''Malcolm''');
end;

procedure TestTDBRecordQuery.TestNullFields;
begin
  CheckExpectedCountWithInnerCheck(DBRecordQuery.From(FMemTable).Null('Notes'),
                                   function (Arg : TDBRecord) : Boolean
                                   begin
                                     Result := Arg.FieldByName('Name').AsString = 'Julie';
                                   end,
                                   1, 'Name should be ''Julie''');
end;

procedure TestTDBRecordQuery.TestPassthrough;
begin
  CheckEquals(2, DBRecordQuery.From(FMemTable).Count);
end;

procedure TestTDBRecordQuery.TestPassthroughEmptyDataset;
begin
  EmptyTable;
  CheckEquals(0, FMemTable.RecordCount, 'FMemTable should be empty at this point');
  CheckEquals(0, DBRecordQuery.From(FMemTable).Count);
end;

procedure TestTDBRecordQuery.TestSkipOne;
begin
  CheckEquals(1, DBRecordQuery.From(FMemTable).Skip(1).Count);
end;

procedure TestTDBRecordQuery.TestSkipZero;
begin
  CheckEquals(2, DBRecordQuery.From(FMemTable).Skip(0).Count);
end;

procedure TestTDBRecordQuery.TestStringField;
begin
  CheckEquals(1, DBRecordQuery.From(FMemTable).StringField('Name', StringQuery.StartsWith('mal')).Count);
end;

procedure TestTDBRecordQuery.TestStringFieldAllMatch;
begin
  CheckEquals(2, DBRecordQuery.From(FMemTable).StringField('Name', StringQuery.Contains('l')).Count);
end;

procedure TestTDBRecordQuery.TestStringFieldNoField;
var
  LDBRecord : TDBRecord;
  LPassCount : Integer;
begin
  LPassCount := 0;

  ExpectedException := EDatabaseError;

  for LDBRecord in DBRecordQuery
                     .From(FMemTable)
                     .StringField('Blah', StringQuery.Contains('l')) do
    Inc(LPassCount);

  StopExpectingException;
  CheckEquals(0, LPassCount);
end;

procedure TestTDBRecordQuery.TestStringFieldNoMatch;
begin
  CheckEquals(0, DBRecordQuery.From(FMemTable).StringField('Name', StringQuery.Contains('z')).Count);
end;

procedure TestTDBRecordQuery.TestTakeOne;
begin
  CheckEquals(1, DBRecordQuery.From(FMemTable).Take(1).Count);
end;

procedure TestTDBRecordQuery.TestTakeZero;
begin
  CheckEquals(0, DBRecordQuery.From(FMemTable).Take(0).Count);
end;

procedure TestTDBRecordQuery.TestWherePredicate;
begin
  CheckEquals(1, DBRecordQuery.From(FMemTable).Where(FAgeGreaterThan43).Count);
end;

{ TestTDBRecord }


procedure TestTDBRecord.SetUp;
begin
  FMemTable := TFDMemTable.Create(nil);
  InitMemTable(FMemTable);
end;

procedure TestTDBRecord.TearDown;
begin
  FMemTable.Free;
end;

procedure TestTDBRecord.TestEditAndCancel;
var
  LPassCount : Integer;
begin
  DBRecordQuery.From(FMemTable).Map(function(Value : TDBRecord) : TDBRecord
                                    begin
                                      Value.Edit;
                                      Value.FieldByName('Age').AsInteger := 5;
                                      Value.Cancel;
                                      Result := Value;
                                    end).Count; // should really have another terminating function called Execute.

  LPassCount := 0;
  FMemTable.First;
  while not FMemTable.Eof do
  begin
    Inc(LPassCount);
    case LPassCount of
       1 : begin
             CheckEqualsString('Malcolm', FMemTable.FieldByName('Name').AsString);
             CheckEquals(45, FMemTable.FieldByName('Age').AsInteger);
           end;
       2 : begin
             CheckEqualsString('Julie', FMemTable.FieldByName('Name').AsString);
             CheckEquals(43, FMemTable.FieldByName('Age').AsInteger);
           end;
    end;
    FMemTable.Next;
  end;
end;

procedure TestTDBRecord.TestEditAndPost;
var
  LPassCount : Integer;
begin
  DBRecordQuery.From(FMemTable).Map(function(Value : TDBRecord) : TDBRecord
                                    begin
                                      Value.Edit;
                                      Value.FieldByName('Age').AsInteger := 5;
                                      Value.Post;
                                      Result := Value;
                                    end).Count; //should really have an Execute terminating function

  LPassCount := 0;
  FMemTable.First;
  while not FMemTable.Eof do
  begin
    Inc(LPassCount);
    case LPassCount of
       1 : begin
             CheckEqualsString('Malcolm', FMemTable.FieldByName('Name').AsString);
             CheckEquals(5, FMemTable.FieldByName('Age').AsInteger);
           end;
       2 : begin
             CheckEqualsString('Julie', FMemTable.FieldByName('Name').AsString);
             CheckEquals(5, FMemTable.FieldByName('Age').AsInteger);
           end;
    end;
    FMemTable.Next;
  end;
end;

procedure TestTDBRecord.TestFieldByName;
var
  LDBRecord : TDBRecord;
  LPassCount : Integer;
begin
  LPassCount := 0;
  for LDBRecord in DBRecordQuery.From(FMemTable) do
  begin
    Inc(LPassCount);
    case LPassCount of
       1 : begin
             CheckEqualsString('Malcolm', LDBRecord.FieldByName('Name').AsString);
             CheckEquals(45, LDBRecord.FieldByName('Age').AsInteger);
           end;
       2 : begin
             CheckEqualsString('Julie', LDBRecord.FieldByName('Name').AsString);
             CheckEquals(43, LDBRecord.FieldByName('Age').AsInteger);
           end;
    end;
  end;
end;

initialization
  // Register any test cases with the test runner
  RegisterTest('DB', TestTDBRecordQuery.Suite);
  RegisterTest('DB', TestTDBRecord.Suite);
end.

