program project1;

{$ifdef fpc}
{$mode delphi}{$H+}
{$endif}

 {$apptype console}
uses
  lp_defs, lp_main, lp_form, Unit1;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLpForm1, lpForm1);
  Application.Run;
end.

