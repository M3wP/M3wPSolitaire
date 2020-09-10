unit FormM3wPSolitareMain;

interface

uses
	System.SysUtils, System.Types, System.UITypes, System.Classes,
	System.Variants, FMX.Types, FMX.Graphics, FMX.Forms, FMX.Objects,
	FMX.Layouts, FMX.Controls, FMX.Controls.Presentation, FMX.StdCtrls;

type
	TForm1 = class(TForm)
		Layout1: TLayout;
		LOutTop: TLayout;
		GridLayout1: TGridLayout;
		ImgDeck: TImage;
		ImgSuit1: TImage;
		ImgSuit2: TImage;
		ImgSuit3: TImage;
		ImgSuit4: TImage;
		LOutDeck: TLayout;
		Layout4: TLayout;
		LOutPile1: TLayout;
		LoutPile2: TLayout;
		LoutPile3: TLayout;
		LOutPile4: TLayout;
		LOutPile5: TLayout;
		LOutPile6: TLayout;
		LOutPile7: TLayout;
		Image1: TImage;
		Image2: TImage;
		PaintBox1: TPaintBox;
		Timer1: TTimer;
		Label1: TLabel;
		Timer2: TTimer;
		Image3: TImage;
		ImgAutoUp: TImage;
		ImgDeckFlip: TImage;
		ImgAbout: TImage;
		Layout2: TLayout;
		Image4: TImage;
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure Image1Click(Sender: TObject);
		procedure Image2Click(Sender: TObject);
		procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
		procedure Timer1Timer(Sender: TObject);
		procedure Timer2Timer(Sender: TObject);
		procedure ImgAutoUpClick(Sender: TObject);
		procedure ImgDeckFlipClick(Sender: TObject);
		procedure ImgAboutClick(Sender: TObject);
		procedure Image4Click(Sender: TObject);
		procedure FormSaveState(Sender: TObject);
	private
		FLastTime: Single;
		FFPSCnt: Integer;
		FFPSTally: Single;

	public
		{ Public declarations }
	end;

var
	Form1: TForm1;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.XLgXhdpiTb.fmx ANDROID}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.SmXhdpiPh.fmx ANDROID}

uses
{.IFDEF WNDOWS}
	System.IOUtils,
{.ENDIF}
	System.Math.Vectors, DModM3wPSolitareMain, SolitareTypes;

procedure TForm1.FormCreate(Sender: TObject);
	var
	th,
	tm,
	ts,
	tms: Word;
	b: Byte;

	begin
{.IFDEF WINDOWS}
	SaveState.StoragePath:= System.IOUtils.TPath.GetHomePath;
{.ENDIF}

	ImgAutoUp.Bitmap.Assign(MainDMod.TexCardsAutoUp.Texture);
	ImgDeckFlip.Bitmap.Assign(MainDMod.TexDeckFlip3.Texture);

	GameLock.Acquire;
	try
		PrepGame([ImgSuit1, ImgSuit2, ImgSuit3, ImgSuit4, ImgDeck], [LOutPile1,
				LOutPile2, LOutPile3, LOutPile4, LOutPile5, LOutPIle6, LOutPile7,
				LOutDeck, LOutTop], Layout1.Scale.X, PaintBox1.Canvas.Scale);

		if  SaveState.Stream.Size > 0 then
			begin
			SaveState.Stream.Read(b, 1);
			ImgAutoUp.Tag:= b;

			SaveState.Stream.Read(b, 1);
			ImgDeckFlip.Tag:= b;

			if  ImgAutoUp.Tag = 1 then
				ImgAutoUp.Bitmap.Assign(MainDMod.TexCardsNoAuto.Texture)
			else
				ImgAutoUp.Bitmap.Assign(MainDMod.TexCardsAutoUp.Texture);

			if  ImgDeckFlip.Tag = 1 then
				ImgDeckFlip.Bitmap.Assign(MainDMod.TexDeckFlip1.Texture)
			else
				ImgDeckFlip.Bitmap.Assign(MainDMod.TexDeckFlip3.Texture);

			SetAutoSolv(ImgAutoUp.Tag = 1);
			SetFlipCount(TSolitareFlipCnt(ImgDeckFlip.Tag));

			LoadGameState(SaveState.Stream);
			end
		else
			InitGame;

		finally
		GameLock.Release;
		end;

	DecodeTime(GetTime, th, tm, ts, tms);
	FLastTime:= th * 3600 + tm * 60 + ts + tms / 1000;
	end;

procedure TForm1.FormDestroy(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		FinalGame;

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.FormSaveState(Sender: TObject);
	var
	b: Byte;

	begin
	GameLock.Acquire;
	try
		SaveState.Stream.Clear;

		b:= ImgAutoUp.Tag;
		SaveState.Stream.Write(b, 1);

		b:= ImgDeckFlip.Tag;
		SaveState.Stream.Write(b, 1);

		SaveGameState(SaveState.Stream);

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.Image1Click(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		InitGame;

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.Image2Click(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		StartGame;

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.Image4Click(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		if  IsPaused then
			Exit;

		ImgAbout.Visible:= True;

		ImgAbout.Position.X:= (Layout1.Width - ImgAbout.Width) / 2;
		ImgAbout.Position.Y:= (Layout1.Height - ImgAbout.Height) / 2;

		ImgAbout.BringToFront;
		IsPaused:= True;

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.ImgAboutClick(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		ImgAbout.Visible:= False;
		IsPaused:= False;

		finally
		GameLock.Release;
		end;
	end;

procedure TForm1.ImgAutoUpClick(Sender: TObject);
	begin
	if  IsPaused then
		Exit;

	SetAutoSolv(ImgAutoUp.Tag = 1);

	ImgAutoUp.Tag:= Abs(ImgAutoUp.Tag - 1);
	if  ImgAutoUp.Tag = 1 then
		ImgAutoUp.Bitmap.Assign(MainDMod.TexCardsNoAuto.Texture)
	else
		ImgAutoUp.Bitmap.Assign(MainDMod.TexCardsAutoUp.Texture);
	end;

procedure TForm1.ImgDeckFlipClick(Sender: TObject);
	begin
	if  IsPaused then
		Exit;

	ImgDeckFlip.Tag:= Abs(ImgDeckFlip.Tag - 1);

	SetFlipCount(TSolitareFlipCnt(ImgDeckFlip.Tag));

	if  ImgDeckFlip.Tag = 1 then
		ImgDeckFlip.Bitmap.Assign(MainDMod.TexDeckFlip1.Texture)
	else
		ImgDeckFlip.Bitmap.Assign(MainDMod.TexDeckFlip3.Texture);

	StartGame;
	end;

procedure TForm1.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
	begin
//	m:= Canvas.Matrix;

	if  Canvas.BeginScene then
		try
//			Canvas.SetMatrix(Canvas.Matrix *
//					Canvas.Matrix.CreateScaling(Layout1.Scale.X, Layout1.Scale.Y));

			Canvas.Fill.Color:= TAlphaColorRec.Alpha;
			Canvas.Fill.Kind:= TBrushKind.None;
			Canvas.FillRect(RectF(0, 0, Canvas.Width, Canvas.Height), 0, 0, [], 0);

			PartLock.Acquire;
			try
				RenderParticles(Canvas);

				finally
				PartLock.Release;
				end;

			finally
//			Canvas.SetMatrix(m);
			Canvas.EndScene;
			end;
	end;

procedure TForm1.Timer1Timer(Sender: TObject);
	var
	t,
	p: Single;
	th,
	tm,
	ts,
	tms: Word;

	begin
	DecodeTime(GetTime, th, tm, ts, tms);
	t:= th * 3600 + tm * 60 + ts + tms / 1000;

	PartLock.Acquire;
	try
		AdvanceTime(t - FLastTime);

		finally
		PartLock.Release;
		end;

	p:= t - FLastTime;

	FFPSTally:= FFPSTally + 1 / p;
	Inc(FFPSCnt);

	if  FFPSCnt = 10 then
		begin
		Label1.Text:= 'FPS:  ' + FormatFloat('00.00', FFPSTally / 10);
		FFPSCnt:= 0;
		FFPSTally:= 0;
		end;

	FLastTime:= t;

	if  not IsPaused then
		PaintBox1.BringToFront;
	PaintBox1.Repaint;
	end;

procedure TForm1.Timer2Timer(Sender: TObject);
	begin
	GameLock.Acquire;
	try
		CheckGameWin;

		CheckAutoSolve;

		finally
		GameLock.Release;
		end;
	end;

end.
