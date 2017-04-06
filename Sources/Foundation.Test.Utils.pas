unit Foundation.Test.Utils;

// Configurar: Project Manager > Right Click > Check "TestInsight Project"
// Visualizar: View Menu > TestInsight Explorer

interface

uses
{$IFDEF TESTINSIGHT}
  TestInsight.Client,
  TestInsight.DUnit,
{$ENDIF}
  DUnitTestRunner;

function IsTestInsightRunning: Boolean;
procedure RunRegisteredTests;

implementation

function IsTestInsightRunning: Boolean;
{$IFDEF TESTINSIGHT}
var
  TestInsightClient: ITestInsightClient;
begin
  TestInsightClient := TTestInsightRestClient.Create;
  TestInsightClient.StartedTesting(0);
  Result := not TestInsightClient.HasError;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

procedure RunRegisteredTests;
begin
  ReportMemoryLeaksOnShutdown := True;

{$IFDEF TESTINSIGHT}
  if IsTestInsightRunning then
    TestInsight.DUnit.RunRegisteredTests
  else
{$ENDIF}
    DUnitTestRunner.RunRegisteredTests;
end;

end.
