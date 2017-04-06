program Foundation4DelphiExperimentalTests;

{$IFDEF CONSOLE_TESTRUNNER}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Foundation.Pattern.Defer.Auto in 'Foundation.Pattern.Defer.Auto.pas',
  Foundation.Pattern.Defer.Auto.Test in 'Foundation.Pattern.Defer.Auto.Test.pas',
  Foundation.Test.Mock.Classes in '..\Tests\Foundation.Test.Mock.Classes.pas',
  Foundation.Test.Utils in '..\Sources\Foundation.Test.Utils.pas',
  Foundation.Pattern.Defer.Test.Consts in '..\Tests\Foundation.Pattern.Defer.Test.Consts.pas',
  Foundation.System in '..\Sources\Foundation.System.pas',
  Foundation.Pattern.Defer in '..\Sources\Foundation.Pattern.Defer.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  RunRegisteredTests;
end.

