unit CardTypes;

{$H+}

interface

uses
	Classes, SysUtils;

type
	TCardSuit = (cskNone, cskDiamonds, cskClubs, cskHearts, cskSpades);
	TCardFace = (cfkBack, cfkAce, cfkTwo, cfkThree, cfkFour, cfkFive, cfkSix,
			cfkSeven, cfkEight, cfkNine, cfkTen, cfkJack, cfkQueen, cfkKing,
			cfkJokerRed, cfkJokerBlack, cfkSignature);

	TDeckCard = packed record
		Suit: TCardSuit;
		Face: TCardFace;
	end;

//	PCardIndex = ^TCardIndex;
	TCardIndex = 0..55;

	TPlayingCard = 1..52;
	TGreaterCard = 1..54;

	TCardSet = set of TCardIndex;

	TCardImageSize = (cisDefault, cisSmall, cisMedium, cisLarge);

	TStandardDeck = array[TPlayingCard] of TPlayingCard;


const
	ARR_REC_DECKCARDS: array[TCardIndex] of TDeckCard = (
			(Suit: cskNone; Face: cfkBack),
			(Suit: cskDiamonds; Face: cfkAce),
			(Suit: cskDiamonds; Face: cfkTwo),
			(Suit: cskDiamonds; Face: cfkThree),
			(Suit: cskDiamonds; Face: cfkFour),
			(Suit: cskDiamonds; Face: cfkFive),
			(Suit: cskDiamonds; Face: cfkSix),
			(Suit: cskDiamonds; Face: cfkSeven),
			(Suit: cskDiamonds; Face: cfkEight),
			(Suit: cskDiamonds; Face: cfkNine),
			(Suit: cskDiamonds; Face: cfkTen),
			(Suit: cskDiamonds; Face: cfkJack),
			(Suit: cskDiamonds; Face: cfkQueen),
			(Suit: cskDiamonds; Face: cfkKing),
			(Suit: cskClubs; Face: cfkAce),
			(Suit: cskClubs; Face: cfkTwo),
			(Suit: cskClubs; Face: cfkThree),
			(Suit: cskClubs; Face: cfkFour),
			(Suit: cskClubs; Face: cfkFive),
			(Suit: cskClubs; Face: cfkSix),
			(Suit: cskClubs; Face: cfkSeven),
			(Suit: cskClubs; Face: cfkEight),
			(Suit: cskClubs; Face: cfkNine),
			(Suit: cskClubs; Face: cfkTen),
			(Suit: cskClubs; Face: cfkJack),
			(Suit: cskClubs; Face: cfkQueen),
			(Suit: cskClubs; Face: cfkKing),
			(Suit: cskHearts; Face: cfkAce),
			(Suit: cskHearts; Face: cfkTwo),
			(Suit: cskHearts; Face: cfkThree),
			(Suit: cskHearts; Face: cfkFour),
			(Suit: cskHearts; Face: cfkFive),
			(Suit: cskHearts; Face: cfkSix),
			(Suit: cskHearts; Face: cfkSeven),
			(Suit: cskHearts; Face: cfkEight),
			(Suit: cskHearts; Face: cfkNine),
			(Suit: cskHearts; Face: cfkTen),
			(Suit: cskHearts; Face: cfkJack),
			(Suit: cskHearts; Face: cfkQueen),
			(Suit: cskHearts; Face: cfkKing),
			(Suit: cskSpades; Face: cfkAce),
			(Suit: cskSpades; Face: cfkTwo),
			(Suit: cskSpades; Face: cfkThree),
			(Suit: cskSpades; Face: cfkFour),
			(Suit: cskSpades; Face: cfkFive),
			(Suit: cskSpades; Face: cfkSix),
			(Suit: cskSpades; Face: cfkSeven),
			(Suit: cskSpades; Face: cfkEight),
			(Suit: cskSpades; Face: cfkNine),
			(Suit: cskSpades; Face: cfkTen),
			(Suit: cskSpades; Face: cfkJack),
			(Suit: cskSpades; Face: cfkQueen),
			(Suit: cskSpades; Face: cfkKing),
			(Suit: cskNone; Face: cfkJokerRed),
			(Suit: cskNone; Face: cfkJokerBlack),
			(Suit: cskNone; Face: cfkSignature));


procedure ShuffleStandardDeck(var ADeck: TStandardDeck);

function  CardIndexToIdent(const ACard: TCardIndex): string;
function  CardIndexToText(const ACard: TCardIndex): string;


implementation

procedure ShuffleStandardDeck(var ADeck: TStandardDeck);
    var
	i,
	n: TPlayingCard;
	s: set of TPlayingCard;

	begin
	s:= [];

    for  i:= Low(TPlayingCard) to High(TPlayingCard) do
		while True do
			begin
            n:= Random(High(TPlayingCard)) + Low(TPlayingCard);

            if  n in s then
				Continue
			else
				begin
                ADeck[i]:= n;
				Include(s, n);

				Break;
				end;
			end;

	if  s <> [Low(TPlayingCard)..High(TPlayingCard)] then
		raise Exception.Create('Error in shuffle logic!');
	end;

function  CardIndexToIdent(const ACard: TCardIndex): string;
	const
	ARR_LIT_CARDFACE: array[cfkAce..cfkKing] of string = (
			'a', '2', '3', '4', '5' ,'6', '7', '8', '9', '10', 'j', 'q','k');
	ARR_LIT_CARDSUIT: array[cskDiamonds..cskSpades] of string = (
			'd', 'c', 'h', 's');

	begin
	Result:= '';

	if  ARR_REC_DECKCARDS[ACard].Suit = cskNone then
		case ARR_REC_DECKCARDS[ACard].Face of
			cfkBack:
				Result:= 'bk';
			cfkJokerRed:
				Result:= 'jr';
			cfkJokerBlack:
				Result:= 'jb';
			cfkSignature:
				Result:= 'bs';
			end
	else
		Result:= ARR_LIT_CARDSUIT[ARR_REC_DECKCARDS[ACard].Suit] +
				ARR_LIT_CARDFACE[ARR_REC_DECKCARDS[ACard].Face];

    Assert(Result <> '', 'Error in card ident logic!');
	end;


function  CardIndexToText(const ACard: TCardIndex): string;
	const
	ARR_LIT_CARDFACE: array[cfkAce..cfkKing] of string = (
			'Ace', 'Two', 'Three', 'Four', 'Five' ,'Six', 'Seven', 'Eight', 'Nine',
			'Ten', 'Jack', 'Queen','King');
	ARR_LIT_CARDSUIT: array[cskDiamonds..cskSpades] of string = (
			'Diamonds', 'Clubs', 'Hearts', 'Spades');

	begin
	Result:= '';

	if  ARR_REC_DECKCARDS[ACard].Suit = cskNone then
		case ARR_REC_DECKCARDS[ACard].Face of
			cfkBack:
				Result:= 'Back';
			cfkJokerRed:
				Result:= 'Red Joker';
			cfkJokerBlack:
				Result:= 'Black Joker';
			cfkSignature:
				Result:= 'Signature';
			end
	else
		Result:= ARR_LIT_CARDFACE[ARR_REC_DECKCARDS[ACard].Face] + ' of ' +
				ARR_LIT_CARDSUIT[ARR_REC_DECKCARDS[ACard].Suit];

	Assert(Result <> '', 'Error in card ident logic!');
	end;


initialization
	Randomize;

end.

