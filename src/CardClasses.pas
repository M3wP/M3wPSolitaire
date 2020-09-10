unit CardClasses;

{$H+}

interface

uses
	System.Types, Classes, SysUtils, FMX.Graphics, CardTypes;

type
	TCardGraphics = array[TCardIndex] of TBitmap;

var
	CardGraphics: TCardGraphics;


function  InitialiseCardGraphics(const ASize: TCardImageSize = cisDefault;
		const ADeck: Char = 'a'): TPointF;
procedure FinaliseCardGraphics;


implementation

{$R deckA_small.RES}

{$IFDEF ANDROID}

{$ELSE}
{$R deckA_medium.RES}
{$R deckA_large.RES}
{$ENDIF}

function InitialiseCardGraphics(const ASize: TCardImageSize;
		const ADeck: Char): TPointF;
	var
	z,
	s: string;
	i: TCardIndex;
	r: TResourceStream;

	begin
	Assert((ADeck = '') or (ADeck = 'a'), 'Error determining card image set');

	if  ASize in [cisDefault, cisSmall] then
		z:= 's'
	else if ASize = cisMedium then
		z:= 'm'
	else if Asize = cisLarge then
		z:= 'l';

	for i:= Low(TCardIndex) to High(TCardIndex) do
		begin
		s:= 'card_a' + z + '_' + CardIndexToIdent(i);

		r:= TResourceStream.Create(HINSTANCE, s, RT_RCDATA);

		Assert(Assigned(r), 'Unable to read card resource image!');

		try
			CardGraphics[i]:= TBitmap.Create;
            CardGraphics[i].LoadFromStream(r);

			finally
            r.Free;
			end;
		end;

	Result:= PointF(CardGraphics[0].Width, CardGraphics[0].Height);
	end;


procedure FinaliseCardGraphics;
	var
    i: TCardIndex;

	begin
    for i:= Low(TCardIndex) to High(TCardIndex) do
    	CardGraphics[i].Free;
	end;




end.

