program Foundation4DelphiTests;

{$IFDEF CONSOLE_TESTRUNNER}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Foundation.Pattern.Defer.Test in 'Foundation.Pattern.Defer.Test.pas',
  Foundation.Test.Mock.Classes in 'Foundation.Test.Mock.Classes.pas',
  Foundation.Test.Utils in '..\Sources\Foundation.Test.Utils.pas',
  Foundation.Pattern.Defer.Test.Consts in 'Foundation.Pattern.Defer.Test.Consts.pas',
  Foundation.System in '..\Sources\Foundation.System.pas',
  Foundation.Pattern.Defer in '..\Sources\Foundation.Pattern.Defer.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := True;
  RunRegisteredTests;
end.

