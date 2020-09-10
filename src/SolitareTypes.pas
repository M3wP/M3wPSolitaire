unit SolitareTypes;

interface

uses
	System.Types, System.Classes, System.SyncObjs, Generics.Collections,
	FMX.Objects, FMX.Graphics, FMX.Layouts, CardTypes;

type
	TSolitareFlipCnt = (sfcThree, sfcOne);


function  PrepGame(const AImages: array of TImage;
		const ALayouts: array of TLayout; const AScaleX, AScaleS: Single): TPointF;
procedure InitGame;
procedure StartGame;
procedure FinalGame;

procedure SaveGameState(const AStream: TStream);
procedure LoadGameState(const AStream: TStream);

procedure SetAutoSolv(const AAuto: Boolean);
procedure SetFlipCount(const ACount: TSolitareFlipCnt);

procedure CheckAutoSolve;
procedure CheckGameWin;

procedure AdvanceTime(const ATime: Single);
procedure RenderParticles(const ACanvas: TCanvas);

var
	GameLock: TCriticalSection;
	PartLock: TCriticalSection;

	IsPaused: Boolean;

implementation

uses
	System.SysUtils, FMX.Types, FMX.Forms, CardClasses, PDParticleSystem,
	DModM3wPSolitareMain;


type
	TCardPile = array of TCardIndex;

	TSolitareProxy = class(TObject)
	public
		procedure SpareDeckClick(ASender: TObject);
		procedure FlipCardClick(ASender: TObject);
		procedure OutCardClick(ASender: TObject);
		procedure SolvCardClick(ASender: TObject);
	end;

	TSolitareParticles = class(TObject)
	public
		PDParticles: TPDParticleSystem;
		LifeTime: Single;
		AutoFree: Boolean;
		RunTime: Single;
		Duration: Single;

		constructor Create(const AConfig: TStrings; const ATexture: TBitmap;
				const ALifeTime, ADuration: Single; const AAutoFree: Boolean);
		destructor  Destroy; override;
	end;

var
	MesgProxy: TSolitareProxy;
	CurrCDeck: TStandardDeck;
	DealPiles: array[0..6] of TCardPile;
	DealImges: array[0..6] of array of TImage;
	SparePile: TCardPile;
	CardPiles: array[0..7] of TCardPile;
	SolvPiles: array[Succ(Low(TCardSuit))..High(TCardSuit)] of TCardIndex;
	ImagPiles: array[0..7] of array of TImage;
	CardImges: TList<TImage>;
	ImgLyouts: array[0..8] of TLayout;
	ImagBases: array[0..4] of TImage;
	SpareIndx: Integer;
	IsPlaying: Boolean;
	CanAutoSl: Boolean;
	WllAutoSl: Boolean;
	CurrCrdSz: TPointF;
	GameScale: Single;
	ScrnScale: Single;
	FlipCount: Integer;

	Particles: TList<TSolitareParticles>;


procedure SetFlipCount(const ACount: TSolitareFlipCnt);
	begin
	if  ACount = sfcThree then
		FlipCount:= 3
	else
		FlipCount:= 1;
	end;

procedure SetAutoSolv(const AAuto: Boolean);
	begin
	WllAutoSl:= AAuto;
	if  CanAutoSl then
		CanAutoSL:= AAuto;
	end;

procedure AdvanceTime(const ATime: Single);
	var
	i: Integer;
	d: Boolean;

	begin
	for i:= Particles.Count - 1 downto 0 do
		begin
		d:= False;

		if  Particles[i].LifeTime >= 0 then
			begin
			Particles[i].LifeTime:= Particles[i].LifeTime - ATime;

			if  Particles[i].LifeTime < 0 then
				if  Particles[i].AutoFree then
					begin
					d:= True;
					Particles[i].Free;
					Particles.Delete(i);
					end
				else
					Particles[i].PDParticles.Stop(False);
			end;

		if  (not d)
		{and Particles[i].PDParticles.IsEmitting} then
			begin
			if  Particles[i].PDParticles.IsEmitting then
				begin
				Particles[i].RunTime:= Particles[i].RunTime + ATime;
				if  Particles[i].RunTime >= Particles[i].Duration then
					Particles[i].PDParticles.Stop(False);
				end;

			Particles[i].PDParticles.AdvanceTime(ATime);
			end;
		end;
	end;

procedure RenderParticles(const ACanvas: TCanvas);
	var
	i: Integer;

	begin
	for i:= 0 to Particles.Count - 1 do
		Particles[i].PDParticles.Render(ACanvas, {ACanvas.Scale * }GameScale);
	end;

function  CreateDealImage(const APile: Byte; const AIndex: Byte): TImage;
	begin
	Result:= TImage.Create(Application.MainForm);
	DealImges[APile, AIndex]:= Result;
	CardImges.Add(Result);

	Result.Bitmap.Assign(CardGraphics[0]);

	Result.Width:= CurrCrdSz.X;
	Result.Height:= CurrCrdSz.Y;
	Result.Parent:= ImgLyouts[APile];
	Result.Position.X:= 0;
	Result.Position.Y:= AIndex * (CurrCrdSz.Y / 24);
	Result.Align:= TAlignLayout.None;
	Result.Visible:= True;
	Result.BringToFront;
	end;

function  CreateCardImage(const APile: Byte; const ACardIdx: Word): TImage;
	var
	tag: Integer;

	begin
	tag:= (Length(CardPiles[APile]) shl 24) or (APile shl 16) or ACardIdx;

	Result:= TImage.Create(Application.MainForm);
	Result.Bitmap.Assign(CardGraphics[ACardIdx]);

	Result.Tag:= tag;
	Result.Width:= CurrCrdSz.X;
	Result.Height:= CurrCrdSz.Y;

	Result.Parent:= ImgLyouts[APile];

	if  APile = 7 then
		begin
		Result.Margins.Right:= (3 - (Length(ImagPiles[7]) + 1)) * (CurrCrdSz.X / 3);
		Result.Align:= TAlignLayout.FitRight;
		Result.OnClick:= MesgProxy.FlipCardClick;
		end
	else
		begin
		Result.Position.X:= 0;
		Result.Position.Y:= Length(CardPiles[APile]) * (CurrCrdSz.Y / 6) +
				Length(DealPiles[APile]) * (CurrCrdSz.Y / 24);
		Result.Align:= TAlignLayout.None;
		Result.OnClick:= MesgProxy.OutCardClick;
		end;

	SetLength(CardPiles[APile], Length(CardPiles[APile]) + 1);
	CardPiles[APile, High(CardPiles[APile])]:= ACardIdx;

	SetLength(ImagPiles[APile], Length(ImagPiles[APile]) + 1);
	ImagPiles[APile, High(ImagPiles[APile])]:= Result;

	CardImges.Add(Result);

	Result.Visible:= True;
	Result.BringToFront;
	end;

procedure GetImageCardDetail(const AImage: TImage; out AIndex, APile: Byte;
		out ACardIdx: Word);
	begin
	AIndex:= (AImage.Tag and $FF000000) shr 24;
	APile:= (AImage.Tag and $FF0000) shr 16;
	ACardIdx:= AImage.Tag and $FFFF;
	end;

procedure ReleaseImage(const AImage: TImage);
	begin
	CardImges.Remove(AImage);
	AImage.Visible:= False;
	AImage.Parent:= nil;
	AImage.Free;
	end;

function  PopCardFromDealPile(const APile: Byte): TCardIndex;
	begin
	if  Length(DealPiles[APile]) = 0 then
		Result:= High(TCardIndex)
	else
		begin
		Result:= DealPiles[APile, High(DealPiles[APile])];
		SetLength(DealPiles[APile], Length(DealPiles[APile]) - 1);
		ReleaseImage(DealImges[APile, High(DealImges[APile])]);
		SetLength(DealImges[APile], Length(DealImges[APile]) - 1);
		end;
	end;

procedure ClearPile(const APile: Byte);
	var
	i: Integer;

	begin
	for i:= 0 to High(ImagPiles[APile]) do
		ReleaseImage(ImagPiles[APile, i]);

	SetLength(ImagPiles[APile], 0);
	SetLength(CardPiles[APile], 0);
	end;

procedure ClearImages;
	var
	i,
	j: Byte;

	begin
	for i:= 0 to 7 do
		ClearPile(i);

	for i:= 0 to 6 do
		if  Length(DealImges[i]) > 0 then
			for j:= 0 to High(DealImges[i]) do
				if  Assigned(DealImges[i, j]) then
					ReleaseImage(DealImges[i, j]);
	end;

function  FindNextPile(const AIndex: Byte; const AStart: Byte;
		const ACard: Word): Byte;
	var
	i,
	j: Integer;
	s: TCardSuit;
	a: set of TCardSuit;
	f: TCardFace;

	begin
	Result:= AStart;

	s:= ARR_REC_DECKCARDS[ACard].Suit;
	f:= ARR_REC_DECKCARDS[ACard].Face;

	if  (AStart < 8)
	and (AIndex = High(CardPiles[AStart]))
	and (((SolvPiles[s] = 0)
	and   (f = cfkAce))
	or   (Succ(SolvPiles[s]) = ACard)) then
		Result:= Ord(s) - Ord(cskDiamonds) + 8
	else
		begin
		if  s in [cskDiamonds, cskHearts] then
			a:= [cskClubs, cskSpades]
		else
			a:= [cskDiamonds, cskHearts];

		i:= AStart;
		for j:= 0 to 6 do
			begin
			Inc(i);
			if  i > 6 then
				i:= 0;

			if  (Length(CardPiles[i]) = 0)
			and (f = cfkKing) then
				begin
				Result:= i;
				Break;
				end
			else if (Length(CardPiles[i]) > 0)
			and (ARR_REC_DECKCARDS[CardPiles[i, High(CardPiles[i])]].Suit in a)
			and (ARR_REC_DECKCARDS[CardPiles[i, High(CardPiles[i])]].Face > cfkAce)
			and (Pred(ARR_REC_DECKCARDS[CardPiles[i, High(CardPiles[i])]].Face) = f) then
				begin
				Result:= i;
				Break;
				end;
			end;
		end;
	end;

function PrepGame(const AImages: array of TImage;
		const ALayouts: array of TLayout; const AScaleX, AScaleS: Single): TPointF;
	var
	sz: TPointF;
	i: Integer;
	d: Integer;
	e: TSolitareParticles;
	f: TPointF;

	begin
	Assert(Length(AImages) = 5, 'Invalid image list in game prep.!');
	Assert(Length(ALayouts) = 9, 'Invalid layouts list in game prep.!');

	GameScale:= AScaleX;
	ScrnScale:= AScaleS;

	IsPlaying:= False;
	IsPaused:= False;
	MesgProxy:= TSolitareProxy.Create;
	CardImges:= TList<TImage>.Create;

	WllAutoSl:= True;

	FlipCount:= 3;

	Particles:= TList<TSolitareParticles>.Create;

{$IFDEF ANDROID}
	d:= 4;
	sz:= InitialiseCardGraphics(cisSmall);
{$ELSE}
	d:= 8;
	sz:= InitialiseCardGraphics(cisMedium);
{$ENDIF}

	CurrCrdSz:= sz;
	Result:= sz;

	for i:= 0 to 6 do
		SetLength(DealImges[i], 0);

	for i:= 0 to 8 do
		begin
		ImgLyouts[i]:= ALayouts[Low(ALayouts) + i];

		if  i = 8 then
			begin
			ImgLyouts[i].Height:= sz.Y{ + d * 2};
			ImgLyouts[i].Margins.Top:= d;
			ImgLyouts[i].Margins.Left:= d;
			ImgLyouts[i].Margins.Right:= d;
			ImgLyouts[i].Margins.Bottom:= d;
			end
		else
			begin
			ImgLyouts[i].Width:= sz.X{ + d * 2};
			ImgLyouts[i].Margins.Right:= d * 2;
			end;
		end;

	for i:= 0 to 4 do
		begin
		ImagBases[i]:= AImages[Low(AImages) + i];

		ImagBases[i].Width:= sz.X;
		ImagBases[i].Height:= sz.Y;

		if  i in [0..2] then
			ImagBases[i].Margins.Right:= d
		else if i = 3 then
			ImagBases[i].Margins.Right:= d * 2;
		end;

	ImagBases[4].OnClick:= MesgProxy.SpareDeckClick;

	for i:= 0 to 3 do
		begin
		e:= TSolitareParticles.Create(MainDMod.XMLParticleSolv.XML,
				MainDMod.TexParticleSolv.Texture, -1, 2.5, False);

		f:= ImagBases[i].LocalToAbsolute(PointF(0, 0));

		e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
		e.PDParticles.EmitterY:= (f.Y + CurrCrdSz.Y * GameScale / 2){ * ScrnScale};

		Particles.Add(e);
		end;
	end;

procedure FinalGame;
	var
	i: Integer;

	begin
	IsPlaying:= False;
	ClearImages;
	CardImges.Free;
	FinaliseCardGraphics;
	MesgProxy.Free;

	for i:= Particles.Count - 1 downto 0 do
		begin
		Particles[i].Free;
		Particles.Delete(i);
		end;

	Particles.Free;
	end;

procedure StartGame;
	var
	c: TPlayingCard;
	i,
	j: Integer;

	begin
	ClearImages;

	for i:= Ord(Succ(Low(TCardSuit))) to Ord(High(TCardSuit)) do
		SolvPiles[TCardSuit(i)]:= 0;

	for i:= 0 to 6 do
		begin
		SetLength(DealPiles[i], i + 1);
		SetLength(DealImges[i], i + 1);

		SetLength(CardPiles[i], 0);
		SetLength(ImagPiles[i], 0);
		end;
	SetLength(CardPiles[7], 0);
	SetLength(ImagPiles[7], 0);
	SetLength(SparePile, 24);
	SpareIndx:= 0;

	c:= Low(TPlayingCard);
	for i:= 0 to 6 do
		for j:= i to 6 do
			begin
			DealPiles[j, i]:= CurrCDeck[c];
			CreateDealImage(j, i);

			Inc(c);
			end;

	for i:= c to High(TPlayingCard) do
		SparePile[i - c]:= CurrCDeck[i];

	for i:= 0 to 3 do
		begin
		ImagBases[i].Tag:= i;
		ImagBases[i].OnClick:= MesgProxy.SolvCardClick;
		ImagBases[i].Bitmap.Assign(CardGraphics[High(TCardIndex)]);
		end;

	ImagBases[4].Bitmap.Assign(CardGraphics[Low(TCardIndex)]);

	for i:= 0 to 6 do
		begin
		j:= PopCardFromDealPile(i);
		CreateCardImage(i, j);
		end;

	IsPlaying:= True;
	CanAutoSl:= WllAutoSl;
	end;

procedure InitGame;
	begin
	ShuffleStandardDeck(CurrCDeck);
	StartGame;
	end;

procedure CheckGameWin;
	var
	f1,
	f2,
	f3,
	f4: TCardFace;
	e: TSolitareParticles;
	pt: TPointF;
	cr,
	cb,
	cg: Single;

	begin
	f1:= ARR_REC_DECKCARDS[SolvPiles[cskDiamonds]].Face;
	f2:= ARR_REC_DECKCARDS[SolvPiles[cskClubs]].Face;
	f3:= ARR_REC_DECKCARDS[SolvPiles[cskHearts]].Face;
	f4:= ARR_REC_DECKCARDS[SolvPiles[cskSpades]].Face;

	if  (f1 = cfkKing)
	and (f2 = cfkKing)
	and (f3 = cfkKing)
	and (f4 = cfkKing) then
		begin
		pt.X:= Random(Application.MainForm.Width - 100) + 50;
		pt.Y:= Random(Application.MainForm.Height - 100) + 50;

		cr:= (Random(5) + 6) / 10;
		cg:= (Random(5) + 6) / 10;
		cb:= (Random(5) + 6) / 10;

		e:= TSolitareParticles.Create(MainDMod.XMLParticleWin.XML,
				MainDMod.TexParticleWin.Texture, 6, 4, True);

		e.PDParticles.EmitterX:= pt.X{ * ScrnScale};
		e.PDParticles.EmitterY:= pt.Y{ * ScrnScale};

		e.PDParticles.StartColor.red:= cr;
		e.PDParticles.StartColor.green:= cg;
		e.PDParticles.StartColor.blue:= cb;

		e.PDParticles.Start;
		e.PDParticles.Populate(20);

		PartLock.Acquire;
		try
			Particles.Add(e);

			finally
			PartLock.Release;
			end;
		end;
	end;

procedure CheckAutoSolve;
	var
	i: Integer;
	s: TCardSuit;
	f: TCardFace;
	c1,
	c2: TCardIndex;
	e: TSolitareParticles;
	ci: TImage;
	pt: TPointF;

	begin
	if  CanAutoSl then
		begin
		for i:= 0 to 6 do
			begin
			if  Length(CardPiles[i]) > 0 then
				begin
				c1:= CardPiles[i, High(CardPiles[i])];
				f:= ARR_REC_DECKCARDS[c1].Face;
				s:= ARR_REC_DECKCARDS[c1].Suit;

				c2:= SolvPiles[s];
				if  (f = Succ(ARR_REC_DECKCARDS[c2].Face))
				and ((c2 > 0)
				or   (f = cfkAce)) then
					begin
					ReleaseImage(ImagPiles[i, High(ImagPiles[i])]);
					SetLength(CardPiles[i], Length(CardPiles[i]) - 1);
					SetLength(ImagPiles[i], Length(ImagPiles[i]) - 1);

					SolvPiles[s]:= c1;
					ImagBases[Ord(s) - Ord(cskDiamonds)].Bitmap.Assign(
							CardGraphics[SolvPiles[s]]);

					PartLock.Acquire;
					try
						e:= Particles[Ord(s) - Ord(cskDiamonds)];

						e.LifeTime:= 2.5;
						e.RunTime:= 0;
						e.PDParticles.Start;
						e.PDParticles.Populate(5);

						finally
						PartLock.Release;
						end;

					if  (Length(CardPiles[i]) = 0)
					and (Length(DealPiles[i]) > 0) then
						begin
						c1:= PopCardFromDealPile(i);
						ci:= CreateCardImage(i, c1);

						e:= TSolitareParticles.Create(MainDMod.XMLParticleDeal.XML,
								MainDMod.TexParticleDeal.Texture, 3, 1, True);

						pt:= ci.LocalToAbsolute(PointF(0, 0));

						e.PDParticles.EmitterX:= (pt.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
						e.PDParticles.EmitterY:= pt.Y{ * ScrnScale};

						e.PDParticles.Start;
						e.PDParticles.Populate(5);

						PartLock.Acquire;
						try
							Particles.Add(e);

							finally
							PartLock.Release;
							end;
						end;

					Break;
					end;
				end;
			end;
		end;
	end;

procedure SaveGameState(const AStream: TStream);
	var
	i,
	j: Integer;
	b: Byte;

	begin
//	Magic
	i:= $534C5452;
	AStream.Write(i, 4);

//	Deck
	for i:= Low(TStandardDeck) to High(TStandardDeck) do
		begin
		b:= Byte(CurrCDeck[i]);
		AStream.Write(b, 1);
		end;

//	Spare Pile
	b:= Byte(Length(SparePile));
	AStream.Write(b, 1);
	for i:= Low(SparePile) to High(SparePile) do
		begin
		b:= Byte(SparePile[i]);
		AStream.Write(b, 1);
		end;

//	Spare Index
	b:= Byte(SpareIndx);
	AStream.Write(b, 1);

//	Deal Piles
	for i:= 0 to 6 do
		begin
		b:= Byte(Length(DealPiles[i]));
		AStream.Write(b, 1);

		if  Length(DealPiles[i]) > 0 then
			for j:= 0 to High(DealPiles[i]) do
				begin
				b:= Byte(DealPiles[i, j]);
				AStream.Write(b, 1);
				end;
		end;

//	Card Piles
	for i:= 0 to 7 do
		begin
		b:= Byte(Length(CardPiles[i]));
		AStream.Write(b, 1);

		if  Length(CardPiles[i]) > 0 then
			for j:= 0 to High(CardPiles[i]) do
				begin
				b:= Byte(CardPiles[i, j]);
				AStream.Write(b, 1);
				end;
		end;

//	Solve Piles
	for i:= 0 to 3 do
		begin
		b:= Byte(SolvPiles[TCardSuit(Ord(Low(SolvPiles)) + i)]);
		AStream.Write(b, 1);
		end;

//	Auto Solve
	AStream.Write(WllAutoSl, 1);
	end;

procedure LoadGameState(const AStream: TStream);
	var
	i,
	j,
	k: Integer;
	b: Byte;

	begin
//	Magic
	AStream.Read(i, 4);
	if  i <> $534C5452 then
		raise Exception.Create('Invalid save state!');

//	Deck
	for i:= Low(TStandardDeck) to High(TStandardDeck) do
		begin
		AStream.Read(b, 1);
		CurrCDeck[i]:= b;
		end;

//	Spare Pile
	AStream.Read(b, 1);
	SetLength(SparePile, b);

	for i:= Low(SparePile) to High(SparePile) do
		begin
		AStream.Read(b, 1);
		SparePile[i]:= b;
		end;

//	Spare Index
	AStream.Read(b, 1);
	SpareIndx:= b;

//	Deal Piles
	for i:= 0 to 6 do
		begin
		AStream.Read(b, 1);
		SetLength(DealPiles[i], b);
		SetLength(DealImges[i], b);

		if  Length(DealPiles[i]) > 0 then
			for j:= 0 to High(DealPiles[i]) do
				begin
				AStream.Read(b, 1);
				DealPiles[i, j]:= b;
				end;
		end;

	for i:= 0 to 6 do
		if  Length(DealPiles[i]) > 0 then
			begin
			Assert(Length(DealPiles[i]) > 0, 'Code error!');

			for j:= 0 to High(DealPiles[i]) do
				CreateDealImage(i, j);
			end;

//	Card Piles
	for i:= 0 to 7 do
		begin
		AStream.Read(b, 1);
//		SetLength(CardPiles[i], b);

		k:= b;
		if  k > 0 then
			for j:= 0 to k - 1 do
				begin
				AStream.Read(b, 1);
//				CardPiles[i, j]:= b;
				CreateCardImage(i, b);
				end;
		end;

//	Solve Piles
	for i:= 0 to 3 do
		begin
		AStream.Read(b, 1);
		SolvPiles[TCardSuit(Ord(Low(SolvPiles)) + i)]:= b;
		end;

//	Auto Solve
	AStream.Read(WllAutoSl, 1);

	for i:= 0 to 3 do
		begin
		ImagBases[i].Tag:= i;
		ImagBases[i].OnClick:= MesgProxy.SolvCardClick;

		if  SolvPiles[TCardSuit(Ord(Low(SolvPiles)) + i)] = 0 then
			ImagBases[i].Bitmap.Assign(CardGraphics[High(TCardIndex)])
		else
			ImagBases[i].Bitmap.Assign(
					CardGraphics[SolvPiles[TCardSuit(Ord(Low(SolvPiles)) + i)]]);
		end;

	ImagBases[4].Bitmap.Assign(CardGraphics[Low(TCardIndex)]);

	IsPlaying:= True;
	CanAutoSl:= WllAutoSl;
	end;


{ TSolitareProxy }

procedure TSolitareProxy.FlipCardClick(ASender: TObject);
	var
	i,
	p: Byte;
	c: Word;
	np: Byte;
	j: Integer;
	e: TSolitareParticles;
	ci: TImage;
	f: TPointF;

	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		GetImageCardDetail(ASender as TImage, i, p, c);

		if  i < High(CardPiles[7]) then
			Exit;

		np:= FindNextPile(i, p, c);

		if  np <> p then
			begin
			CanAutoSl:= WllAutoSl;

			ReleaseImage(ASender as TImage);
			SetLength(CardPiles[7], Length(CardPiles[7]) - 1);
			SetLength(ImagPiles[7], Length(ImagPiles[7]) - 1);

			j:= SpareIndx - 1;
			while j >= 0 do
				begin
				if  SparePile[j] <> 0 then
					begin
					SparePile[j]:= 0;
					Break;
					end;

				Dec(j);
				end;

			if  np > 7 then
				begin
				SolvPiles[TCardSuit(np - 7)]:= c;
				ImagBases[np - 8].Bitmap.Assign(CardGraphics[
						SolvPiles[TCardSuit(np - 7)]]);

				PartLock.Acquire;
				try
					e:= Particles[np - 8];

					e.LifeTime:= 2.5;
					e.RunTime:= 0;
					e.PDParticles.Start;
					e.PDParticles.Populate(5);

					finally
					PartLock.Release;
					end;
				end
			else
				begin
				ci:= CreateCardImage(np, c);

				e:= TSolitareParticles.Create(MainDMod.XMLParticleOut.XML,
						MainDMod.TexParticleOut.Texture, 3, 2, True);

				f:= ci.LocalToAbsolute(PointF(0, 0));

				e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
				e.PDParticles.EmitterY:= (f.Y + CurrCrdSz.Y * GameScale / 2){ * ScrnScale};

				e.PDParticles.Start;
				e.PDParticles.Populate(5);

				PartLock.Acquire;
				try
					Particles.Add(e);

					finally
					PartLock.Release;
					end;
				end;

			if  Length(CardPiles[7]) = 0 then
				begin
				i:= 0;
				j:= SpareIndx - 1;

				while (j >= 0) and (i < FlipCount) do
					begin
					if  SparePile[j] <> 0 then
						Inc(i);

					Dec(j);
					end;

				if  i > 0 then
					begin
					while  i > 0 do
						begin
						Inc(j);
						if  SparePile[j] > 0 then
							begin
							CreateCardImage(7, SparePile[j]);
							Dec(i);
							end;
						end;

	//				SpareIndx:= j;
					end;
				end;
			end;
		finally
		GameLock.Release;
		end;
	end;

procedure TSolitareProxy.OutCardClick(ASender: TObject);
	var
	i,
	p: Byte;
	c: Word;
	np: Byte;
	j: Integer;
	e: TSolitareParticles;
	ci: TImage;
	f: TPointF;

	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		GetImageCardDetail(ASender as TImage, i, p, c);

		np:= FindNextPile(i, p, c);

		if  np <> p then
			begin
			CanAutoSl:= WllAutoSl;

			if  i = High(CardPiles[p]) then
				begin
				ReleaseImage(ASender as TImage);
				SetLength(CardPiles[p], Length(CardPiles[p]) - 1);
				SetLength(ImagPiles[p], Length(ImagPiles[p]) - 1);

				if  np > 7 then
					begin
					SolvPiles[TCardSuit(np - 7)]:= c;
					ImagBases[np - 8].Bitmap.Assign(CardGraphics[
							SolvPiles[TCardSuit(np - 7)]]);

					PartLock.Acquire;
					try
						e:= Particles[np - 8];

						e.LifeTime:= 2.5;
						e.RunTime:= 0;
						e.PDParticles.Start;
						e.PDParticles.Populate(5);

						finally
						PartLock.Release;
						end;
					end
				else
					begin
					ci:= CreateCardImage(np, c);

					e:= TSolitareParticles.Create(MainDMod.XMLParticleOut.XML,
							MainDMod.TexParticleOut.Texture, 3, 2, True);

					f:= ci.LocalToAbsolute(PointF(0, 0));

					e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
					e.PDParticles.EmitterY:= (f.Y + CurrCrdSz.Y * GameScale / 2){ * ScrnScale};

					e.PDParticles.Start;
					e.PDParticles.Populate(5);

					PartLock.Acquire;
					try
						Particles.Add(e);

						finally
						PartLock.Release;
						end;
					end;

				if  (Length(CardPiles[p]) = 0)
				and (Length(DealPiles[p]) > 0) then
					begin
					c:= PopCardFromDealPile(p);
					ci:= CreateCardImage(p, c);

					e:= TSolitareParticles.Create(MainDMod.XMLParticleDeal.XML,
							MainDMod.TexParticleDeal.Texture, 3, 1, True);

					f:= ci.LocalToAbsolute(PointF(0, 0));

					e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
					e.PDParticles.EmitterY:= f.Y{ * ScrnScale};

					e.PDParticles.Start;
					e.PDParticles.Populate(5);

					PartLock.Acquire;
					try
						Particles.Add(e);

						finally
						PartLock.Release;
						end;
					end;
				end
			else if np < 7 then
				begin
				ci:= nil;

				for j:= i to High(CardPiles[p]) do
					begin
					ReleaseImage(ImagPiles[p, j]);
					ci:= CreateCardImage(np, CardPiles[p, j]);
					end;

				e:= TSolitareParticles.Create(MainDMod.XMLParticleOut.XML,
						MainDMod.TexParticleOut.Texture, 3, 2, True);

				f:= ci.LocalToAbsolute(PointF(0, 0));

				e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
				e.PDParticles.EmitterY:= (f.Y + CurrCrdSz.Y * GameScale / 2){ * ScrnScale};

				e.PDParticles.Start;
				e.PDParticles.Populate(5);

				PartLock.Acquire;
				try
					Particles.Add(e);

					finally
					PartLock.Release;
					end;

				SetLength(CardPiles[p], i);
				SetLength(ImagPiles[p], i);

				if  (Length(CardPiles[p]) = 0)
				and (Length(DealPiles[p]) > 0) then
					begin
					c:= PopCardFromDealPile(p);
					ci:= CreateCardImage(p, c);

					e:= TSolitareParticles.Create(MainDMod.XMLParticleDeal.XML,
							MainDMod.TexParticleDeal.Texture, 3, 1, True);

					f:= ci.LocalToAbsolute(PointF(0, 0));

					e.PDParticles.EmitterX:= (f.X + CurrCrdSz.X * GameScale / 2){ * ScrnScale};
					e.PDParticles.EmitterY:= f.Y{ * ScrnScale};

					e.PDParticles.Start;
					e.PDParticles.Populate(5);

					PartLock.Acquire;
					try
						Particles.Add(e);

						finally
						PartLock.Release;
						end;
					end;
				end;
			end;

		finally
		GameLock.Release;
		end;
	end;

procedure TSolitareProxy.SolvCardClick(ASender: TObject);
	var
	p: Integer;
	i: Byte;
	c: Word;

	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		p:= (ASender as TImage).Tag;
		c:= SolvPiles[TCardSuit(p + Ord(cskDiamonds))];
		if  (c > 0)
		and (ARR_REC_DECKCARDS[c].Face > cfkAce) then
			begin
			i:= FindNextPile(0, 8, c);
			if i < 8 then
				begin
				CanAutoSl:= False;

				SolvPiles[TCardSuit(p + Ord(cskDiamonds))]:=
						Pred(SolvPiles[TCardSuit(p + Ord(cskDiamonds))]);
				ImagBases[p].Bitmap.Assign(CardGraphics[Pred(c)]);
				CreateCardImage(i, c);
				end;
			end;
		finally
		GameLock.Release;
		end;
	end;

procedure TSolitareProxy.SpareDeckClick(ASender: TObject);
	var
	m: Integer;

	begin
	if  IsPlaying
	and (not IsPaused) then
		begin
		GameLock.Acquire;
		try
			ClearPile(7);

			while (SparePile[SpareIndx] = 0) and (SpareIndx < Length(SparePile)) do
				Inc(SpareIndx);

			if  SpareIndx > High(SparePile) then
				begin
				SpareIndx:= 0;
				Exit;
				end;

			m:= 0;
			while (m < FlipCount) and (SpareIndx < Length(SparePile)) do
				begin
				if  SparePile[SpareIndx] > 0 then
					begin
					CreateCardImage(7, SparePile[SpareIndx]);
					Inc(m);
					end;

				Inc(SpareIndx);
				end;

			finally
			GameLock.Release;
			end;
		end;
	end;

{ TSolitareParticles }

constructor TSolitareParticles.Create(const AConfig: TStrings;
		const ATexture: TBitmap; const ALifeTime, ADuration: Single;
		const AAutoFree: Boolean);
	begin
	inherited Create;

	PDParticles:= TPDParticleSystem.Create(AConfig, ATexture);
	LifeTime:= ALifeTime;
	AutoFree:= AAutoFree;
	RunTime:= 0;
	Duration:= ADuration;
	end;

destructor TSolitareParticles.Destroy;
	begin
	PDParticles.Stop(True);
	PDParticles.Free;

	inherited;
	end;

initialization
	GameLock:= TCriticalSection.Create;
	PartLock:= TCriticalSection.Create;

finalization
	PartLock.Free;
	GameLock.Free;


end.
