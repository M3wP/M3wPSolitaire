unit DModM3wPSolitareMain;

interface

uses
  System.SysUtils, System.Classes, Xml.xmldom, Xml.XMLIntf, FMX.Types,
  FMX.MaterialSources, Xml.XMLDoc;

type
  TMainDMod = class(TDataModule)
    XMLParticleSolv: TXMLDocument;
    TexParticleSolv: TTextureMaterialSource;
    XMLParticleOut: TXMLDocument;
    TexParticleOut: TTextureMaterialSource;
    XMLParticleDeal: TXMLDocument;
    TexParticleDeal: TTextureMaterialSource;
    XMLParticleWin: TXMLDocument;
    TexParticleWin: TTextureMaterialSource;
    TexCardsAutoUP: TTextureMaterialSource;
    TexCardsNoAuto: TTextureMaterialSource;
    TexDeckFlip1: TTextureMaterialSource;
    TexDeckFlip3: TTextureMaterialSource;
  private
    { Private declarations }
  public
	{ Public declarations }
  end;

var
  MainDMod: TMainDMod;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

end.
