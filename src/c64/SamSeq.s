;************************************************************************
;
;		SamSeq
;
;	This is the main file for the GeoProgrammer package sample
;	application. It contains all of the code and data required
;	for assembly.
;
;Copyright (c) 1987 Berkeley Softworks. Released to the Public Domain.
;
;Translation to the Ophis assembler by Daniel England, 2016.
;************************************************************************

	.include	"geosSym.inc"		;get GEOS definitions
	.include	"geosmac.ca65.inc"		;get GEOS macro definitions

GAMECORE	=	$7F40

CARDPILE_Y	=	$48
TOPPILES_Y	=	$10

SPAREDEK_X	=	$23
SPAREDEK_TOP 	=	TOPPILES_Y 	
SPAREDEK_BOTTOM = 	SPAREDEK_TOP + (6 * 8) - 1
SPAREDEK_LEFT	=	SPAREDEK_X * 8
SPAREDEK_RIGHT	=	SPAREDEK_LEFT + (4 * 8) - 1

FLIPCOUNT	=	3

FLIPCRD0_X	=	$1A
FLIPPILE_TOP	=	TOPPILES_Y
FLIPPILE_BOTTOM = 	FLIPPILE_TOP + (6 * 8) - 1
FLIPPILE_LEFT	=	FLIPCRD0_X * 8
FLIPPILE_RIGHT	=	FLIPPILE_LEFT + (8 * 8) - 1
	
	.struct		DEALPILE
		Length	.byte
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
		_5	.byte
		_6	.byte
	.endstruct
	
	.struct		CARDPILE
		Length	.byte
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
		_5	.byte
		_6	.byte
		_7	.byte
		_8	.byte
		_9	.byte
		_A	.byte
		_B	.byte
		_C	.byte
		_D	.byte
	.endstruct
	
	.struct		FLIPPILE
		Length	.byte
		_0	.byte
		_1	.byte
		_2	.byte
	.endstruct
	
	.struct		SOLVEPILE
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
	.endstruct
	
	.struct		DIRTYPILES
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
		_5	.byte
		_6	.byte
		_7	.byte
		_8	.byte
		_9	.byte
		_A	.byte
		_B	.byte
	.endstruct
	
	.struct		LASTLENPILES
		_0	.byte
		_1	.byte
		_2	.byte
		_3	.byte
		_4	.byte
		_5	.byte
		_6	.byte
		_7	.byte
	.endstruct
	
	.struct		GAMEDATA
		DealPl0	.tag	DEALPILE
		DealPl1	.tag	DEALPILE
		DealPl2	.tag	DEALPILE
		DealPl3	.tag	DEALPILE
		DealPl4	.tag	DEALPILE
		DealPl5	.tag	DEALPILE
		DealPl6	.tag	DEALPILE
		CardPl0	.tag	CARDPILE
		CardPl1	.tag	CARDPILE
		CardPl2	.tag	CARDPILE
		CardPl3	.tag	CARDPILE
		CardPl4	.tag	CARDPILE
		CardPl5	.tag	CARDPILE
		CardPl6	.tag	CARDPILE
		FlipPl0	.tag	FLIPPILE
		SolvPl0	.tag	SOLVEPILE
		DirtyPl	.tag	DIRTYPILES
		LastLns	.tag	LASTLENPILES
		SparIdx .byte	
	.endstruct

	.assert .sizeof(GAMEDATA) < 193, error, "GANEDATA too large!"
;	.out	.concat("- sizeof GAMEDATA:  ", .string(.sizeof(GAMEDATA)))

	.SEGMENT	"DIRENTRY"
	.SEGMENT	"FILEINFO"
	.SEGMENT	"STARTUP"

	.CODE				;program code section starts here
	.ORG	 $0400			;
	
;Our program starts here. The first thing we do is clear the screen and
;initialize our menus and icons. Then we RTS to GEOS mainloop.
;When an event happens, such as the user selects a menu item or one of our
;icons, GEOS will call one of our handler routines.

;-------------------------------------------------------------------------------
Main:
;-------------------------------------------------------------------------------
	LoadB	dispBufferOn, ST_WR_FORE | ST_WR_BACK
					;allow writes to foreground and background

	LoadW	r0, ClearScreen		;point to graphics string to clear screen
	JSR	GraphicsString

	LoadW	r0, MainMenu		;point to menu definition table
	LDA	#0			;place cursor on first menu item when done
	JSR	DoMenu			;have GEOS draw the menus on the screen

	JSR	GameInit

	LDA	#<HookPressVec
	STA	otherPressVec
	LDA	#>HookPressVec
	STA	otherPressVec + 1

	RTS

;-------------------------------------------------------------------------------
HookPressVec:
;-------------------------------------------------------------------------------
;	Not working as documented
;	LDA	pressFlag
;	AND	#MOUSE_BIT
;	BNE	@test0
;	
;	RTS
;	
;@test0:
	LDA	mouseData
	BPL	@begin
	
	RTS
	
@begin:
	LoadB	dispBufferOn, ST_WR_FORE

	JSR	SpareLoadRect
	
	JSR	IsMseInRegion
	CMP	#TRUE
	BNE	@flip0
	
	JSR	InvertRectangle
	
	JSR	SpareDeckClick
	
	JSR	FlipUpdatePile
	
	JSR	SpareLoadRect
	JSR	InvertRectangle
	
	JMP	@exit
	
@flip0:

@exit:
	LoadB	dispBufferOn, ST_WR_FORE | ST_WR_BACK

	RTS


;-------------------------------------------------------------------------------
DeckShuffle:
;-------------------------------------------------------------------------------
	LDX	#$00
	LDA	#$01
	
@loop0:
	STA	DeckData0, X
	TAY
	INY
	TYA
	INX
	CPX	#$34
	BNE	@loop0
	
	LDA	#$00
	STA	r15L
		
@loop1:
	JSR	GetRandom
	
;	GetRandom returns 0 - 65521.  Need 0 to 51
	LDA	#$FE
	STA	r2L
	LDA	#$04
	STA	r2H

	LDA	random
	STA	r1L
	LDA	random + 1
	STA	r1H
	
	LDX	#r1
	LDY	#r2
	
	JSR	Ddiv
	
	LDA	r1L
	CMP	#$34
	BCS	@loop1		;>= 52 redo
	
	TAY
	LDX	r15L
	LDA	DeckData0, X
	STA	r15H
	LDA	DeckData0, Y
	STA	DeckData0, X
	LDA	r15H
	STA	DeckData0, Y
	
	INC	r15L
	LDA	r15L
	
	CMP	#$34
	BNE	@loop1	

	RTS

;-------------------------------------------------------------------------------
DeckDeal:
;-------------------------------------------------------------------------------
	LDA	#$00
	STA	r13L		;Deck card index
	STA	r15L		;Deal pile count
	
@loop0:
	STA	r15H		;Deal pile index
	
	ASL
	TAX
	LDA	DealData0, X
	STA	a0L		;Deal pile data
	
	LDA	CardData0, X
	STA	a1L		;Card pile data
	
	INX
	LDA	DealData0, X
	STA	a0H

	LDA	CardData0, X
	STA	a1H		

;	Init  card pile len, dirty
	LDA	#$00
	LDY	#$00
	STA	(a1), Y
	LDY	r15H
	STA	GAMECORE + GAMEDATA::DirtyPl, Y
	
	INC	r15L
	LDA	r15L
	LDY	#$00
	STA	(a0), Y
	
;	ASL
;	STA	r14L
	
	LDA	#$00
	STA	(a1), Y

;	Deal cards from deck
	LDA	(a0), Y
	INY
	
	STA	r13H		;Deal card count
	STY	r12L		;Deal card index
	
@loop1:
	LDX	r13L		;Get card
	LDA	DeckData0, X
	
	STA	(a0), Y
	INC	r13L
	INY
	
	DEC	r13H
	BNE	@loop1

	JSR	DealCardPop

	JSR	DealPileDraw
	
	JSR	CardPileDraw
		
	LDA	r15L
	CMP	#$07
	BNE	@loop0
	
	LDA	#$00
	LDY	#$00
	STA	GAMECORE + GAMEDATA::SolvPl0, Y
	INY
	STA	GAMECORE + GAMEDATA::SolvPl0, Y
	INY
	STA	GAMECORE + GAMEDATA::SolvPl0, Y
	INY
	STA	GAMECORE + GAMEDATA::SolvPl0, Y

	STA	GAMECORE + GAMEDATA::SparIdx

	LDY	#$1C
	LDX	#$00
@loop2:
	LDA	DeckData0, Y
	STA	SpareData0, X
	
	INX
	
	INY
	CPY	#$34
	BNE	@loop2
	
	RTS


;-------------------------------------------------------------------------------
DealCardPop:
;-------------------------------------------------------------------------------
	LDY	#$00
	LDA	(a0), Y		;Deal pile count
	
	TAY
	LDA	(a0), Y
	STA	r12L		;Card index

;	Decrement deal count
	LDY	#$00		
	LDA	(a0), Y

	TAX
	DEX
	TXA
	STA	(a0), Y

;	Update card pile last len, dirty
	LDX	r15H		;Deal pile index
	LDY	#$00
	LDA	(a1), Y
	STA	GAMECORE + GAMEDATA::LastLns, X
	
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
;	When pop, only have 1 card on pile
	LDA	#$01
	STA	(a1), Y		;Card pile data
	
	INY
	LDA	r12L
	STA	(a1), Y
	
	RTS


;-------------------------------------------------------------------------------
DealPileDraw:
;-------------------------------------------------------------------------------
	LDY	#$00
	LDA	(a0), Y
	BEQ	@exit
	
	STA	r12L		;Deal pile count
	
	LDA	r15H		;Deal pile index
	
	STA	r2L
	LDA	#$05
	STA	r1L
	
	LDX	#r1
	LDY	#r2
	
	JSR	BBMult
	
	INC	r1L
	INC	r1L
	
	LDA	r1L
	STA	r14L		;Deal pile x co-ord
	LDA	#CARDPILE_Y
	STA	r14H		;Deal pile y co-ord
	
@loop0:
	LDA	#<CardTopBK
	STA	r0L
	LDA	#>CardTopBK
	STA	r0H
	
	LDA	r14L
	STA	r1L
	LDA	r14H
	STA	r1H

	INC 	r14H
	INC	r14H
	
	LDA	#$04
	STA	r2L
	LDA	#$02
	STA	r2H
	
	JSR	BitmapUp
	
	DEC	r12L
	BNE	@loop0
	
@exit:
	RTS


;-------------------------------------------------------------------------------
CardDraw:
;	IN:	r12H	Card index * 2
;		r14L	x cell
;		r14H	y co-ord
;-------------------------------------------------------------------------------
;	Draw top
	LDX	r12H
	LDA	CardTops0, X
	STA	r0L
	LDA	CardTops0 + 1, X
	STA	r0H

	LDA	r14L
	STA	r1L
	LDA	r14H
	STA	r1H

	LDA	#$04
	STA	r2L
	LDA	#$0A
	STA	r2H
	
	JSR	BitmapUp
	
;	Draw suit
	LDA	r14H
	CLC
	ADC	#$0A
	STA	r14H
	
	LDX	r12H
	LDA	Cards0, X
	ASL
	TAX

	LDA	Suits0, X
	STA	r0L
	LDA	Suits0 + 1, X
	STA	r0H

	LDA	r14L
	STA	r1L
	LDA	r14H
	STA	r1H

	LDA	#$04
	STA	r2L
	LDA	#$1C
	STA	r2H
	
	JSR	BitmapUp
	
;	Draw bottom
	LDA	r14H
	CLC
	ADC	#$1C
	STA	r14H

	LDX 	r12H
	LDA	CardBots0, X
	STA	r0L
	LDA	CardBots0 + 1, X
	STA	r0H

	LDA	r14L
	STA	r1L
	LDA	r14H
	STA	r1H

	LDA	#$04
	STA	r2L
	LDA	#$0A
	STA	r2H
	
	JSR	BitmapUp

	RTS


;-------------------------------------------------------------------------------
CardPileDraw:
;-------------------------------------------------------------------------------
	LDY	#$00
	LDA	(a1), Y
	BNE	@begin
	
	RTS
	
@begin:
	STA	r12L		;Card pile count

;	Calc card pile x co-ord
	LDA	r15H		;Card pile index

	STA	r2L
	LDA	#$05
	STA	r1L
	
	LDX	#r1
	LDY	#r2
	
	JSR	BBMult
	
	INC	r1L
	INC	r1L
	
	LDA	r1L
	STA	r14L		;Deal pile x co-ord

;	Calc card pile y co-ord
	LDY	#$00
	LDA	(a0), Y		;Deal pile count
	ASL
	
	CLC
	ADC	#CARDPILE_Y
	
	STA	r14H		;Card pile y co-ord
	
;	Draw top
	LDY	#$01
	LDA	(a1), Y
	ASL
	
	STA	r12H
	
	JSR	CardDraw

@exit:
	RTS


;-------------------------------------------------------------------------------
SolvDrawPile:
;-------------------------------------------------------------------------------
	LDX	r15H		;Solve pile index
	LDA	GAMECORE + GAMEDATA::SolvPl0, X
	
	ASL
	STA	r12H		;Card index * 2


	LDA	#TOPPILES_Y	;y co-ord
	STA	r14H

	LDA	#$05
	STA	r1L
	STX	r2L		;solve pile index
	
	LDX	#r1
	LDY	#r2
	
	JSR	BBMult
	
	INC	r1L
	
	LDA	r1L
	STA	r14L		;Solv pile x co-ord

	JSR	CardDraw

	RTS


;-------------------------------------------------------------------------------
SolvDrawAll:
;-------------------------------------------------------------------------------
	LoadB	dispBufferOn, ST_WR_FORE | ST_WR_BACK
	
	LDA	#$00
	STA	r15H
	
@loop0:
	JSR	SolvDrawPile
	
	INC	r15H
	LDA	r15H
	CMP	#$04
	BNE	@loop0

	LoadB	dispBufferOn, ST_WR_FORE 

	RTS


;-------------------------------------------------------------------------------
SpareLoadRect:
;-------------------------------------------------------------------------------
	LDA	#SPAREDEK_TOP
	STA	r2L
	LDA	#SPAREDEK_BOTTOM
	STA	r2H
	LoadW	r3, SPAREDEK_LEFT
	LoadW	r4, SPAREDEK_RIGHT

	RTS
	

;-------------------------------------------------------------------------------
SpareSetFlipDirty:
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::DirtyPl + 7
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl + 7
	
	LDA	GAMECORE + GAMEDATA::FlipPl0
	STA	GAMECORE + GAMEDATA::LastLns + 7

	LDA	r12L		;New length
	STA	GAMECORE + GAMEDATA::FlipPl0

	RTS
	

;-------------------------------------------------------------------------------
SpareDeckClick:
;-------------------------------------------------------------------------------
@loop0:
	LDX	GAMECORE + GAMEDATA::SparIdx
	LDA	SpareData0, X
	BNE	@flip0
	
	INX
	TXA
	STA	GAMECORE + GAMEDATA::SparIdx
	CMP	#$18
	BCC	@loop0
	
	LDA	#$00
	STA	r12L
	STA	GAMECORE + GAMEDATA::SparIdx
	
	JSR	SpareSetFlipDirty
	
	RTS
	
@flip0:
	LDA	#$00
	STA	r12L
	
@loop1:
	LDX	GAMECORE + GAMEDATA::SparIdx
	LDA	SpareData0, X
	
	BEQ	@next1
	
	INC	r12L
	
	LDX	r12L
	STA	GAMECORE + GAMEDATA::FlipPl0, X
	
@next1:
	INC	GAMECORE + GAMEDATA::SparIdx
	
	LDA	GAMECORE + GAMEDATA::SparIdx
	CMP	#$18
	BCS	@done1
	
	LDA	r12L
	CMP	#FLIPCOUNT
	BCC	@loop1
	
@done1:
	JSR	SpareSetFlipDirty
	
	RTS


;-------------------------------------------------------------------------------
SpareDrawDeck:
;-------------------------------------------------------------------------------
	LDA	#$35
	ASL
	STA	r12H		;Card index * 2

	LDA	#TOPPILES_Y	;y co-ord
	STA	r14H

	LDA	#SPAREDEK_X
	STA	r14L		;spare deck x co-ord

	JSR	CardDraw

	RTS


;-------------------------------------------------------------------------------
FlipDrawPile:
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::LastLns + 7
	CMP	GAMECORE + GAMEDATA::FlipPl0
	
	BCC	@draw
	
	LDA	GAMECORE + GAMEDATA::FlipPl0
	CMP	#FLIPCOUNT
	
	BEQ	@draw
	
	ASL
	ASL
	ASL
	ASL
	
	CLC
	ADC	#<FLIPPILE_LEFT
	STA	r3L
	LDA	#$00
	ADC	#>FLIPPILE_LEFT
	STA	r3H
	
	LoadB	r2L, FLIPPILE_TOP
	LoadB	r2H, FLIPPILE_BOTTOM
	
	LoadW	r4, FLIPPILE_RIGHT
	
	LDA	#$02
	JSR	SetPattern
	
	JSR	Rectangle
	
@draw:
	LDA	GAMECORE + GAMEDATA::FlipPl0
	BNE	@cont
	
	RTS
	
@cont:

	LDA	#$00
	STA	r15L		;Flip pile index
	
	LDA	#FLIPCRD0_X
	STA	r14L		;x co-ord
	
@loop:
	LDA	#FLIPPILE_TOP
	STA	r14H		;y co-ord
	
	INC	r15L
	LDX	r15L
	
	LDA	GAMECORE + GAMEDATA::FlipPl0, X
	ASL
	STA	r12H		;card index * 2
	
	JSR	CardDraw

	INC	r14L
	INC	r14L

	LDX	r15L
	CPX	GAMECORE + GAMEDATA::FlipPl0
	BNE	@loop
	
	RTS


;-------------------------------------------------------------------------------
FlipUpdatePile:
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::DirtyPl + 7
	BPL	@exit

	JSR	FlipDrawPile
	
	LDA	#$00
	STA	GAMECORE + GAMEDATA::DirtyPl + 7

@exit:
	RTS


;-------------------------------------------------------------------------------
GameInit:
;-------------------------------------------------------------------------------
	JSR	DeckShuffle
;-------------------------------------------------------------------------------
GameStart:
	LoadB	dispBufferOn, ST_WR_FORE
	
	JSR	DeckDeal

	JSR	SolvDrawAll
	
	JSR	SpareDrawDeck
	
	LDA	#FLIPCOUNT
	STA	GAMECORE + GAMEDATA::LastLns + 7
	LDA	#$00
	STA	GAMECORE + GAMEDATA::FlipPl0
	STA	GAMECORE + GAMEDATA::SparIdx
	
	JSR	FlipDrawPile

	LoadB	dispBufferOn, ST_WR_FORE | ST_WR_BACK
	
	RTS


;Event handler routines: are called by GEOS when an event happens,
;such as user selecting a menu item or clicking on an icon.

;-------------------------------------------------------------------------------
DoGeosAbout:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu
	RTS


;-------------------------------------------------------------------------------
DoFileNew:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu
	JSR	GameInit
	RTS


;-------------------------------------------------------------------------------
DoFileRestart:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu
	JSR	GameStart
	RTS
	

;-------------------------------------------------------------------------------
DoFileQuit:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu
	JMP	EnterDeskTop		;return to deskTop!
	

;-------------------------------------------------------------------------------
DoAbout:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu		;roll menu back up
					;code to handle this event goes here
	
	JSR	GameInit
					
	RTS				;all done

;-------------------------------------------------------------------------------
DoClose:
;-------------------------------------------------------------------------------
	jsr	GotoFirstMenu		;roll menu back up
					;code to handle this event goes here
	rts				;all done

;-------------------------------------------------------------------------------
DoQuit:
;-------------------------------------------------------------------------------
	jsr	GotoFirstMenu		;roll menu back up
	jmp	EnterDeskTop		;return to deskTop!



;-------------------------------------------------------------------------------
;DATA SECTION
;-------------------------------------------------------------------------------

;Here are some data tables for the init code shown above:

ClearScreen:				;graphics string table to clear screen
;-------------------------------------------------------------------------------
	.byte	NEWPATTERN, 2		;set new pattern value
	.byte	MOVEPENTO		;move pen to:
	.word	0			;top left corner of screen
	.byte	0
	.byte	RECTANGLETO		;draw filled rectangle to bottom right corner
	.word	319
	.byte	199
	.byte	NULL			;end of GraphicsString

MainMenu:
;-------------------------------------------------------------------------------
		.byte	$00
		.byte	$0E
		.word	$0000
		.word	$0031
		.byte	02 | HORIZONTAL 
		.word	MainMenuText0
		.byte	SUB_MENU
		.word	MainGeos
		.word	MainMenuText1
		.byte	SUB_MENU
		.word	MainFile
MainGeos:
;-------------------------------------------------------------------------------
		.byte	$0F
		.byte	$1E
		.word	$0000
		.word	$0027
		.byte	01 | VERTICAL | CONSTRAINED
		.word	MainMenuText2
		.byte	MENU_ACTION
		.word	DoGeosAbout
MainFile:
;-------------------------------------------------------------------------------
		.byte	$0F
		.byte	$38
		.word	$001C
		.word	$0041
		.byte	03 | VERTICAL | CONSTRAINED
		.word	MainMenuText3
		.byte	MENU_ACTION
		.word	DoFileNew
		.word	MainMenuText4
		.byte	MENU_ACTION
		.word	DoFileRestart
		.word	MainMenuText5
		.byte	MENU_ACTION
		.word	DoFileQuit
MainMenuText0:
		.byte	"geos", $00
MainMenuText1:
		.byte	"file", $00
MainMenuText2:
		.byte	"about", $00
MainMenuText3:
		.byte	"new", $00
MainMenuText4:
		.byte	"restart", $00
MainMenuText5:
		.byte	"quit", $00


;-------------------------------------------------------------------------------
	.include	"cards.inc"
;-------------------------------------------------------------------------------


DealData0:
;-------------------------------------------------------------------------------
	.word	GAMECORE + GAMEDATA::DealPl0
	.word	GAMECORE + GAMEDATA::DealPl1
	.word	GAMECORE + GAMEDATA::DealPl2
	.word	GAMECORE + GAMEDATA::DealPl3
	.word	GAMECORE + GAMEDATA::DealPl4
	.word	GAMECORE + GAMEDATA::DealPl5
	.word	GAMECORE + GAMEDATA::DealPl6

CardData0:
;-------------------------------------------------------------------------------
	.word	GAMECORE + GAMEDATA::CardPl0
	.word	GAMECORE + GAMEDATA::CardPl1
	.word	GAMECORE + GAMEDATA::CardPl2
	.word	GAMECORE + GAMEDATA::CardPl3
	.word	GAMECORE + GAMEDATA::CardPl4
	.word	GAMECORE + GAMEDATA::CardPl5
	.word	GAMECORE + GAMEDATA::CardPl6

DeckData0:
;-------------------------------------------------------------------------------
	.repeat (52), I
		.byte	$00
	.endrep
	
SpareData0:
;-------------------------------------------------------------------------------
	.repeat (24), I
		.byte	$00
	.endrep


Heap0:


