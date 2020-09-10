program M3wPSolitare;

uses
  System.StartUpCopy,
  FMX.Forms,
  CardClasses in 'CardClasses.pas',
  CardTypes in 'CardTypes.pas',
  FormM3wPSolitareMain in 'FormM3wPSolitareMain.pas' {Form1},
  SolitareTypes in 'SolitareTypes.pas',
  DModM3wPSolitareMain in 'DModM3wPSolitareMain.pas' {MainDMod: TDataModule},
  ParticleSystem in 'ParticleSystem.pas',
  PDParticleSystem in 'PDParticleSystem.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape, TFormOrientation.InvertedLandscape];
  Application.CreateForm(TMainDMod, MainDMod);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
