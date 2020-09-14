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

TOPPILES_Y	=	$10

CARDWIDTH	=	4 * 8
CARDHEIGHT	=	6 * 8

SPAREDEK_X	=	$23
SPAREDEK_TOP 	=	TOPPILES_Y 	
SPAREDEK_BOTTOM = 	SPAREDEK_TOP + CARDHEIGHT- 1
SPAREDEK_LEFT	=	SPAREDEK_X * 8
SPAREDEK_RIGHT	=	SPAREDEK_LEFT + CARDWIDTH - 1

FLIPCOUNT	=	3

FLIPCRD0_X	=	$1A
FLIPPILE_TOP	=	TOPPILES_Y
FLIPPILE_BOTTOM = 	FLIPPILE_TOP + CARDHEIGHT - 1
FLIPPILE_LEFT	=	FLIPCRD0_X * 8
FLIPPILE_RIGHT	=	FLIPPILE_LEFT + (8 * 8) - 1
	
CARDPILE_Y	=	$48
CARDPLE0_X	=	$02
CARDPLE0_TOP	=	CARDPILE_Y
CARDPLE0_BOTTOM	=	$C7
CARDPLE0_LEFT	=	CARDPLE0_X * 8
CARDPLE0_RIGHT	=	CARDPLE0_LEFT + CARDWIDTH - 1
CARDPLE1_LEFT	=	CARDPLE0_LEFT + (5 * 8)
CARDPLE1_RIGHT	=	CARDPLE0_RIGHT + (5 * 8)
CARDPLE2_LEFT	=	CARDPLE1_LEFT + (5 * 8)
CARDPLE2_RIGHT	=	CARDPLE1_RIGHT + (5 * 8)
CARDPLE3_LEFT	=	CARDPLE2_LEFT + (5 * 8)
CARDPLE3_RIGHT	=	CARDPLE2_RIGHT + (5 * 8)
CARDPLE4_LEFT	=	CARDPLE3_LEFT + (5 * 8)
CARDPLE4_RIGHT	=	CARDPLE3_RIGHT + (5 * 8)
CARDPLE5_LEFT	=	CARDPLE4_LEFT + (5 * 8)
CARDPLE5_RIGHT	=	CARDPLE4_RIGHT + (5 * 8)
CARDPLE6_LEFT	=	CARDPLE5_LEFT + (5 * 8)
CARDPLE6_RIGHT	=	CARDPLE5_RIGHT + (5 * 8)

SOLVPILE_Y	=	TOPPILES_Y
SOLVPLE0_X	=	$01
SOLVPLE0_TOP	=	SOLVPILE_Y
SOLVPLE0_BOTTOM	=	SOLVPILE_Y + CARDHEIGHT - 1
SOLVPLE0_LEFT	=	SOLVPLE0_X * 8
SOLVPLE0_RIGHT 	=	SOLVPLE0_LEFT + CARDWIDTH - 1
SOLVPLE1_LEFT	=	SOLVPLE0_LEFT + CARDWIDTH + 8
SOLVPLE1_RIGHT 	=	SOLVPLE0_RIGHT + CARDWIDTH + 8
SOLVPLE2_LEFT	=	SOLVPLE1_LEFT + CARDWIDTH + 8
SOLVPLE2_RIGHT 	=	SOLVPLE1_RIGHT + CARDWIDTH + 8
SOLVPLE3_LEFT	=	SOLVPLE2_LEFT + CARDWIDTH + 8
SOLVPLE3_RIGHT 	=	SOLVPLE2_RIGHT + CARDWIDTH + 8


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
		AutoCan	.byte
		AutoEnb	.byte
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

	LDA	#TRUE
	STA	GAMECORE + GAMEDATA::AutoEnb

	LoadW	r0, ProcessData0
	LDA	#$01
	JSR	InitProcesses

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
	LDX	GAMECORE + GAMEDATA::FlipPl0
	BEQ	@card0

	JSR	FlipLoadLastRect
	
	JSR	IsMseInRegion
	CMP	#TRUE
	BNE	@card0

	JSR	FlipLoadLastCard

	JSR	GameFindNextPile

	LDA	r15H
	CMP	r13H
	BNE	@flip1
	
	JMP	@exit

@flip1:
	JSR	InvertRectangle
	
	JSR	FlipMoveCard
	
	JMP	@update
	
@card0:
	LDA	#$00
	STA	r15H
	
@loop0:
	ASL
	TAX
	LDA	DealData0, X
	STA	a0L
	LDA	DealData0 + 1, X
	STA	a0H

	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H

	LDA	#$FF
	STA	r15L

	JSR	CardLoadPileRect
	
	JSR	IsMseInRegion
	CMP	#TRUE
	BNE	@next0
	
	JSR	CardFindMseCard
	BCC	@solv0
	
	JSR	GameFindNextPile

	LDA	r15H
	CMP	r13H
	BEQ	@exit

	JSR	InvertRectangle

	LDA	r15H
	ASL
	TAX
	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H

	JSR	CardMoveCard
	
	JMP	@update
	
@next0:
	INC	r15H
	LDA	r15H
	CMP	#$07
	BNE	@loop0
	
@solv0:
	LDA	#$08
	STA	r15H
	
@loop1:
	JSR	SolvLoadPileRect
	
	JSR	IsMseInRegion
	CMP	#TRUE
	BNE	@next1
	
	LDA	r15H
	SEC
	SBC	#$08
	TAX
	LDA	GAMECORE + GAMEDATA::SolvPl0, X
	
	STA	r13L
	ASL
	TAX
	LDA	Cards0 + 1, X
	
	CMP	#$02
	BCC	@exit
	
	LDA	#$00
	STA	r15L
	
	JSR	GameFindNextPile

	LDA	r15H
	CMP	r13H
	BEQ	@exit
	
	JSR	InvertRectangle

	JSR	SolvMoveCard
	
	JMP	@update
	
@next1:
	INC	r15H
	LDA	r15H
	CMP	#$0C
	BNE	@loop1
	
	JMP	@exit
	
@update:
	JSR	GameUpdatePiles

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
;	LDA	#$00
;	STA	(a1), Y

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

	JSR	DealPopCard

	JSR	DealDrawPile
	
	JSR	CardDrawPile
	
	LDX	r15H
	LDA	#$00
	STA	GAMECORE + GAMEDATA::DirtyPl, X
		
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
DealPopCard:
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
DealDrawPile:
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
CardMoveCard:
;	IN	r13L	card 
;		r15H	start pile
;		r15L	index
;		r13H	new pile
;		r14L	card suit
;		a0	deal pile
;		a1	card pile
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::AutoEnb
	STA	GAMECORE + GAMEDATA::AutoCan

	LDY	#$00
	LDA	(a1), Y
	TAY
	DEY
	CPY	r15L
	BEQ	@topcrd
	
	JMP	@mvlst

@topcrd:
;	Remove card from the pile
	LDX	r15H

	TAY
	STA	GAMECORE + GAMEDATA::LastLns, X
	
	DEY
	TYA
	LDY	#$00
	STA	(a1), Y
	
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	LDA	r13H
	CMP	#$08
	BCC	@topmov

	TAX

	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
	TXA
	
	SEC
	SBC	#$08
	TAX
	
	LDA	r13L
	STA	GAMECORE + GAMEDATA::SolvPl0, X
	
	JMP	@checkpop

@topmov:
	LDA	r13H
	ASL
	TAX
	LDA	CardData0, X
	STA	a2L
	LDA	CardData0 + 1, X
	STA	a2H
	
	LDY	#$00
	LDA	(a2), Y
	
	LDX	r13H
	STA	GAMECORE + GAMEDATA::LastLns, X
	
	TAX
	INX
	TXA
	STA	(a2), Y
	TAY
	LDA	r13L
	STA	(a2), Y

	LDX	r13H
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
	JMP	@checkpop

@mvlst:
	LDY	#$00
	LDA	(a1), Y
	LDX	r15H
	STA	GAMECORE + GAMEDATA::LastLns, X
	STA	r12L
	
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	LDA	r15L
	STA	(a1), Y

	LDA	r13H
	ASL
	TAX
	LDA	CardData0, X
	STA	a2L
	LDA	CardData0 + 1, X
	STA	a2H
	
	LDY	#$00
	LDA	(a2), Y
	STA	r12H
	
	LDX	r13H
	STA	GAMECORE + GAMEDATA::LastLns, X

	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
	LDA	r12L
	SEC
	SBC	r15L
	
	CLC
	ADC	r12H
	
	STA	(a2), Y
	
	INC	r15L
	INC	r12L
	INC	r12H
	
@loop0:
	LDY	r15L
	LDA	(a1), Y
	
	LDY	r12H
	STA	(a2), Y
	
	INC	r12H
	INC	r15L
	LDA	r15L
	CMP	r12L
	BNE	@loop0

@checkpop:
	LDY	#$00
	LDA	(a1), Y
	BNE	@exit
	
	LDA	(a0), Y
	BEQ	@exit
	
	JSR	DealPopCard
	
@exit:
	RTS


;-------------------------------------------------------------------------------
CardFindMseCard:
;	IN	r15H	pile index
;		r15L	pile card index
;		a0	deal pile
;		a1	card pile
;		r2	
;	OUT	r13L	card 
;		r13H	length card pile
;		r15L	index
;		r2
;-------------------------------------------------------------------------------
	LDY	#$00
	STY	r15L
	STY	r14L
	
	LDA	(a1), Y
	STA	r13H
	BEQ	@exit

@loop0:
	LDA	r2L
	
	LDY	r15L
	INY
	CPY	r13H
	BNE	@tile0
	
	CLC
	ADC	#CARDHEIGHT - 1
	JMP	@cont0
	
@tile0:
	CLC
	ADC	#$07
	
@cont0:
	STA	r2H
	CMP	#$C0
	BCC	@cont1
	
	LDA	#$BF
	STA	r2H
	
@cont1:
	LDA	r14L
	BNE	@next0
	
	JSR	IsMseInRegion
	CMP	#TRUE
	BNE	@next0
	
	LDY	r15L
	INY
	LDA	(a1), Y
	STA	r13L

;	Store top y co-ord and continue
	LDA	r2L
	STA	r14L
	LDA	r15L
	STA	r14H
	
;	SEC
;	RTS
	
@next0:	
	INC	r2H
	LDA	r2H
	STA	r2L
	
	INC	r15L
	LDA	r15L
	CMP	r13H
	BNE	@loop0

@done0:
	LDA	r14L
	BEQ	@exit
	
	STA	r2L
	
	LDA	r14H
	STA	r15L
	
	SEC
	RTS

@exit:
	CLC
	
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
;	LDA	Cards0, X
;	ASL
;	TAX

	LDA	CardSuits0, X
	STA	r0L
	LDA	CardSuits0 + 1, X
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
CardDrawClip:
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
	LDA	#$1C
	STA	r2H
	
	LDA	r14H
	CLC
	ADC	#$0A
	STA	r14H
	
	CLC
	ADC	#$1B
	CMP	#$C8
	BCC	@cont0

	SEC
	LDA	#$C8
	SBC	r14H
	
	STA	r2H

@cont0:
	LDX	r12H
;	LDA	Cards0, X
;	ASL
;	TAX

	LDA	CardSuits0, X
	STA	r0L
	LDA	CardSuits0 + 1, X
	STA	r0H

	LDA	r14L
	STA	r1L
	LDA	r14H
	STA	r1H

	LDA	#$04
	STA	r2L
	
	JSR	BitmapUp
	
;	Draw bottom
	LDA	#$0A
	STA	r2H

	LDA	r14H
	CLC
	ADC	#$1C
	STA	r14H

;	CMP	#$C7		;Should negate the need to check neg
	CMP	#$BF
	BCS	@exit

	CLC
	ADC	#$0A	
	CMP	#$C0		;C8
	BCC	@cont1

	SEC
	LDA	#$C0		;C8
	SBC	r14H
	
	BCC	@exit		;Do it anyway
	BEQ	@exit
	
	STA	r2H

@cont1:
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
;	LDA	#$0A
;	STA	r2H
	
	JSR	BitmapUp

@exit:
	RTS


;-------------------------------------------------------------------------------
CardLoadPileRect:
;-------------------------------------------------------------------------------
;	Calc card pile y co-ord
	LDY	#$00
	LDA	(a0), Y		;Deal pile count

	ASL

	CLC
	ADC	#CARDPILE_Y
	
;	STA	r14H		
	STA	r2L		;Card pile y co-ord

	LDA	r15H
	ASL
	TAX
	
	LDA	CardPileLeft0, X
	STA	r3L
	LDA	CardPileLeft0 + 1, X
	STA	r3H

	LDA	CardPileRight0, X
	STA	r4L
	LDA	CardPileRight0 + 1, X
	STA	r4H

	LDA	r15L
	BPL	@last

;	LDA	r14H
;	STA	r2L
	LDA	#$C7
	STA	r2H
	
	RTS
	
@last:
	LDA	r2L
	STA	r11L

	LDA	r15L
	STA	r2L
	LDA	#$08
	STA	r1L
	
	LDX	#r1
	LDY	#r2
	
	JSR	BBMult
	
	LDA	r1L
	CLC
	ADC	r11L
	
	STA	r2L
	
	CLC
	ADC	#(CARDHEIGHT - 1)
	
	CMP	#$C0
	BCC	@done
	
	LDA	#$BF
	
@done:
	STA	r2H
	
	RTS


;-------------------------------------------------------------------------------
CardDrawPile:
;	IN	a0	address of deal pile
;		a1	address of card pile 
;		r15H	card pile index
;	USES	r14H	card pile y co-ord
;		r12L	card pile count
;		r12H	card index * 2
;		r13L
;		r13H
;
;	THIS ROUTINE NEEDS OPTIMISATION.  ALWAYS DRAWING WHOLE PILE
;
;-------------------------------------------------------------------------------
	LDA	r15L
	STA	r11L
	
	LDA	#$FF
	STA	r15L
	JSR	CardLoadPileRect
	
	LDA	r11L
	STA	r15L
	
	LDA	r2L
	STA	r14H

	LDA	#$02
	JSR	SetPattern
	
	JSR	Rectangle
	
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

;	Draw tops
	LDA	#$01
	STA	r13H

	LDA	r12L
	CMP	r13H 
	BEQ	@last

	TAX
	DEX	
	STX	r13L

@loop0:
	LDY	r13H
	LDA	(a1), Y
	ASL
	TAX
	
	INC	r13H
	INC	r13L
	
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
	LDA	#$08
	STA	r2H
	
	JSR	BitmapUp
	
	CLC
	LDA	r14H
	ADC	#$08
	STA	r14H
	
	LDA	r13H
	CMP	r12L
	BNE	@loop0

;	Draw last
@last:
	LDY	r12L
	LDA	(a1), Y
	ASL
	
	STA	r12H
	
	JSR	CardDrawClip

@exit:
	RTS


;-------------------------------------------------------------------------------
SolvMoveCard:
;-------------------------------------------------------------------------------
	LDA	#FALSE
	STA	GAMECORE + GAMEDATA::AutoCan

	LDX	r15H
	
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
	LDX	r13H

	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	TXA
	ASL
	TAX
	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H
	
	LDY	#$00
	LDA	(a1), Y
	
	STA	GAMECORE + GAMEDATA::LastLns, X
	
	TAX
	INX
	TXA
	STA	(a1), Y
	TAY
	LDA	r13L
	STA	(a1), Y

	LDA	r15H
	SEC
	SBC	#$08
	TAX
	
	DEC	GAMECORE + GAMEDATA::SolvPl0, X
	
	RTS
	

;-------------------------------------------------------------------------------
SolvLoadPileRect:
;-------------------------------------------------------------------------------
	LDA	r15H
	SEC
	SBC	#$08
	ASL
	TAX

	LDA	#SOLVPLE0_TOP
	STA	r2L		;pile y co-ord

	LDA	#SOLVPLE0_BOTTOM
	STA	r2H

	LDA	SolvPileLeft0, X
	STA	r3L
	LDA	SolvPileLeft0 + 1, X
	STA	r3H

	LDA	SolvPileRight0, X
	STA	r4L
	LDA	SolvPileRight0 + 1, X
	STA	r4H

	RTS


;-------------------------------------------------------------------------------
SolvDrawPile:
;-------------------------------------------------------------------------------
	LDA	r15H		;Solve pile index
	CLC
	ADC	#$08
	TAX	

	LDA	#$00
	STA	GAMECORE + GAMEDATA::DirtyPl, X

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
	LDX	GAMECORE + GAMEDATA::SparIdx
	JMP	@test0
@loop0:
	LDA	SpareData0, X
	BNE	@flip0
	
	INX
	STX	GAMECORE + GAMEDATA::SparIdx
@test0:
	CPX	#$18
	BCC	@loop0
	
	LDA	#$00
	STA	r12L
	STA	GAMECORE + GAMEDATA::SparIdx
	
;	DEBUG
	STA	GAMECORE + GAMEDATA::FlipPl0 + 1
	STA	GAMECORE + GAMEDATA::FlipPl0 + 2
	STA	GAMECORE + GAMEDATA::FlipPl0 + 3
	
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
;	If last is less than current, just draw
	LDA	GAMECORE + GAMEDATA::LastLns + 7
	CMP	GAMECORE + GAMEDATA::FlipPl0
	
	BCC	@draw
	
;	Else if maximum, just draw
	LDA	GAMECORE + GAMEDATA::FlipPl0
	CMP	#FLIPCOUNT
	
	BEQ	@draw
	
;	Clear unused portion
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
FlipLoadLastRect:
;-------------------------------------------------------------------------------
	LDA	#FLIPPILE_TOP
	STA	r2L
	LDA	#FLIPPILE_BOTTOM
	STA	r2H
	LoadW	r3, FLIPPILE_LEFT
	
	LDX	GAMECORE + GAMEDATA::FlipPl0
	DEX
	TXA
	
	ASL
	ASL
	ASL
	ASL
	
	CLC
	ADC	r3L
	STA	r3L
	LDA	#$00
	ADC	r3H
	STA	r3H

	CLC	
	LDA	r3L
	ADC	#<(CARDWIDTH - 1)
	STA	r4L
	LDA	r3H
	ADC	#>(CARDWIDTH - 1)
	STA	r4H

	RTS
	

;-------------------------------------------------------------------------------
FlipLoadLastCard:
;	OUT	r13L	card 
;		r15H	start pile
;		r15L	index
;-------------------------------------------------------------------------------
	LDY	GAMECORE + GAMEDATA::FlipPl0
	LDA	GAMECORE + GAMEDATA::FlipPl0, Y
	STA	r13L
	DEY
	STY	r15L
	LDA	#$07
	STA	r15H
	
	RTS
	

;-------------------------------------------------------------------------------
FlipMoveCard:
;	IN	r13L	card 
;		r15H	start pile
;		r15L	index
;		r13H	new pile
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::AutoEnb
	STA	GAMECORE + GAMEDATA::AutoCan

;	Remove card from the flip pile
	LDA	GAMECORE + GAMEDATA::FlipPl0
	STA	GAMECORE + GAMEDATA::LastLns + 7
	
	DEC	GAMECORE + GAMEDATA::FlipPl0
	
	LDA	GAMECORE + GAMEDATA::DirtyPl + 7
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl + 7
	
;	Remove card from the spare deck (make 0 in spare deck)
	LDX	GAMECORE + GAMEDATA::SparIdx
	DEX

@loop0:
	BMI	@cont0		;This should panic
	
	LDA	SpareData0, X
	BNE	@found0
	
	DEX
	JMP	@loop0
	
@found0:
	LDA	#$00
	STA	SpareData0, X
	
@cont0:
	LDX	r13H

;	New pile is dirty
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	TXA

	CMP	#$08
	BCC	@cardpile
	
;	Move the card to the solve pile
	SEC
	SBC	#$08
	TAX
	
	LDA	r13L
	STA	GAMECORE + GAMEDATA::SolvPl0, X
	
	JMP	@done
	
@cardpile:
;	Add card to card pile
	ASL
	TAY
	LDA	CardData0, Y
	STA	a1L
	LDA	CardData0 + 1, Y
	STA	a1H
	
	LDY	#$00
	LDA	(a1), Y

	STA	GAMECORE + GAMEDATA::LastLns, X
	
	TAX
	INX
	TXA
	STA	(a1), Y
	
	TAY
	LDA	r13L
	STA	(a1), Y
	
@done:
	LDA	GAMECORE + GAMEDATA::FlipPl0
	BEQ	@more
	
	RTS
	
@more:
;	DEBUG
	LDA	#$00
	STA	GAMECORE + GAMEDATA::FlipPl0 + 1
	STA	GAMECORE + GAMEDATA::FlipPl0 + 2
	STA	GAMECORE + GAMEDATA::FlipPl0 + 3

;	Get the previous spare deck cards into flip pile
	LDY	#$00	;i:= 0
	
	LDX	GAMECORE + GAMEDATA::SparIdx
	DEX			;j:= Spare Index - 1
	
@loop1:
	BMI	@populate	;j < 0 then finish
	
	CPY	#FLIPCOUNT	
	BCS	@populate	;i >= FLIPCOUNT then finish
	
	LDA	SpareData0, X	
	BEQ	@next1		;if SpareDeck[j] = 0 then skip
	
	INY			;Inc(i)
	
@next1:
	DEX			;Dec(j)
	JMP	@loop1
	
@populate:
;	Build the flip pile with the found cards

	LDA	#$01
	STA	GAMECORE + GAMEDATA::LastLns + 7
	STY	GAMECORE + GAMEDATA::FlipPl0
	LDA	GAMECORE + GAMEDATA::DirtyPl + 7
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl + 7

	LDA	#$01
	STA	r12H	

	CPY	#$00
@loop2:
	BEQ	@exit
	
@loop2a:
	INX			;Inc(j)
	LDA	SpareData0, X
	BEQ	@loop2a
	
	STX	r12L
	LDX	r12H
	STA	GAMECORE + GAMEDATA::FlipPl0, X
	LDX	r12L
	INC	r12H

	DEY
	JMP	@loop2
	
@exit:
	RTS
	

;-------------------------------------------------------------------------------
GameFindCheckSolv:
;-------------------------------------------------------------------------------
	LDA	r15H
	ASL
	TAX
	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H
	
	LDY	#$00
	LDA	(a1), Y

	TAX
	DEX

	CPX	r15L
	BNE	@fail
	
	LDX	r14L
	BEQ	@fail
	
	DEX
	LDA	GAMECORE + GAMEDATA::SolvPl0, X
	STA	r12L		;Current suit's solve pile card
	BNE	@testnext
	
	LDA	r14H
	CMP	#$01
	BNE	@testnext
	
@found:
	TXA
	CLC
	ADC	#$08
	JMP	@success

@testnext:
	LDY	r12L
	INY
	CPY	r13L
	BNE	@fail
	
	JMP	@found

@fail:
	CLC
	RTS
	
@success:
	SEC
	RTS


;-------------------------------------------------------------------------------
GameFindNextPile:
;	IN	r13L	card 
;		r15H	start pile
;		r15L	index
;	USES	r14L	card suit
;		r14H	card face
;	OUT	r13H	new pile
;-------------------------------------------------------------------------------
	LDA	r15H
	STA	r13H
	
	LDA	r13L
	ASL
	TAX
	LDA	Cards0, X
	STA	r14L
	LDA	Cards0 + 1, X
	STA	r14H
	
	LDA	r15H
	CMP	#$08
	BCS	@begin
	
	JSR	GameFindCheckSolv
	BCC	@begin
	
	STA	r13H
	RTS
	
@begin:
	LDA	r14L
	CMP	#$01
	BNE	@testhearts
	
@wantblack:
	LDA	#$02
	STA	r12L		;Lowest matching suit
	JMP	@testpiles
	
@testhearts:
	CMP	#$03
	BEQ	@wantblack
	
	LDA	#$01
	STA	r12L
	
@testpiles:
	LDA 	r15H
	STA	r12H		;tested pile index (i)
	
	LDA	#$00
	STA	r11L		;testing pile counter (j)
	
@loop0:
	INC	r12H
	LDA	r12H
	CMP	#$07
	BCC	@cont0

	LDA	#$00
	STA	r12H

@cont0:
	ASL
	TAX
	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H
	
	LDY	#$00
	LDA	(a1), Y
	BNE	@testcard
	
	LDA	r14H
	CMP	#$0D
	BNE	@testcard
	
;	Found King for empty pile
	LDA	r12H
	STA	r13H
	RTS
	
@testcard:
	LDY	#$00
	LDA	(a1), Y
	BEQ	@next0

;	If matches suit
	TAY
	LDA	(a1), Y
	ASL
	TAX
	LDA	Cards0 + 1, X
	STA	r10H		;card pile's top card's face
	LDA	Cards0, X
	STA	r10L		;card pile's top card's suit
	
	CMP	r12L
	BNE	@testsuit2
	
	JMP	@testface

@testsuit2:
	LDX	r12L
	INX
	INX
	CPX	r10L
	BNE	@next0
	
@testface:
	LDX	r10H
	BEQ	@next0
	
	DEX
	CPX	r14H
	BNE	@next0
	
;	Found home for card on pile
	LDA	r12H
	STA	r13H	
	RTS

@next0:
	INC	r11L
	LDA	r11L
	CMP	#$07
	BEQ	@exit
	
	JMP	@loop0
	
@exit:
	RTS
	
	
;-------------------------------------------------------------------------------
GameUpdatePiles:
;-------------------------------------------------------------------------------
	LoadB	dispBufferOn, ST_WR_FORE 
	
	LDA	#$00
	STA	r15H

@loop0:
	TAX
	ASL
	TAY
	
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	BPL	@next0

	LDA	#$00
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	LDA	DealData0, Y
	STA	a0L
	LDA	DealData0 + 1, Y
	STA	a0H
	
	LDA	CardData0, Y
	STA	a1L
	LDA	CardData0 + 1, Y
	STA	a1H

	JSR	CardDrawPile

@next0:
	INC	r15H
	LDA	r15H
	CMP	#$07
	BNE	@loop0
	
	JSR	FlipUpdatePile
	
	LoadB	dispBufferOn, ST_WR_FORE | ST_WR_BACK
	
	INC	r15H
	LDX	r15H
	STX	r13L
	LDA	#$00
	STA	r15H

@loop1:
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	BPL	@next1

	JSR	SolvDrawPile
	
@next1:
	INC	r15H
	INC	r13L
	LDX	r13L
	CPX	#$0C
	BNE	@loop1

	LoadB	dispBufferOn, ST_WR_FORE 
	
	RTS


;-------------------------------------------------------------------------------
GameInit:
;-------------------------------------------------------------------------------
	JSR	DeckShuffle
;-------------------------------------------------------------------------------
GameStart:
	LDA	GAMECORE + GAMEDATA::AutoEnb
	STA	GAMECORE + GAMEDATA::AutoCan

	LDX	#$00
	JSR	BlockProcess

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

	LDX	#$00
	JSR	RestartProcess
	
	RTS


;-------------------------------------------------------------------------------
ProcAutoSolve:
;-------------------------------------------------------------------------------
	LDA	GAMECORE + GAMEDATA::AutoCan
	CMP	#TRUE
	BEQ	@begin
	
	RTS

@begin:
	LDA	#$00
	STA	r15H
	
@loop:
	ASL
	TAX
	LDA	DealData0, X
	STA	a0L
	LDA	DealData0 + 1, X
	STA	a0H
	LDA	CardData0, X
	STA	a1L
	LDA	CardData0 + 1, X
	STA	a1H
	
	LDY	#$00
	LDA	(a1), Y
	
	BEQ	@next
	
	TAY
	LDA	(a1), Y
	
	STA	r13L
	
	ASL
	TAX
	LDA	Cards0, X
	BEQ	@next
	
	STA	r14L
	
	LDA	Cards0 + 1, X
	STA	r14H
	
	LDX	r14L
	DEX
	TXA
	
	CLC
	ADC	#$08
	STA	r13H
	
	LDA	GAMECORE + GAMEDATA::SolvPl0, X
	ASL
	TAX
	LDA	Cards0 + 1, X
	TAX
	INX
	
	CPX	r14H
	BEQ	@found
	
@next:
	INC	r15H
	LDA	r15H
	CMP	#$07
	BNE	@loop
	
	RTS
	
@found:
	LoadB	dispBufferOn, ST_WR_FORE
	
	LDY	#$00
	LDA	(a1), Y
	TAX
	DEX
	STX	r15L
	JSR	CardLoadPileRect
	
	JSR	InvertRectangle
	
	LDX	r13H
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X
	
	LDX	r14L
	DEX
	LDA	r13L
	STA	GAMECORE + GAMEDATA::SolvPl0, X

	LDX	r15H
	LDA	GAMECORE + GAMEDATA::DirtyPl, X
	ORA	#$80
	STA	GAMECORE + GAMEDATA::DirtyPl, X

	LDY	#$00
	LDA	(a1), Y
	
	STA	GAMECORE + GAMEDATA::LastLns, X
		
	TAX
	DEX
	TXA
	STA	(a1), Y
	
	BNE	@update
	
	LDY	#$00
	LDA	(a0),Y
	
	BEQ	@update
	
	JSR	DealPopCard
	
@update:
	JSR	GameUpdatePiles

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
DoOptionsAuto:
;-------------------------------------------------------------------------------
	JSR	GotoFirstMenu
	
	LDA	GAMECORE + GAMEDATA::AutoEnb
	CMP	#TRUE
	BNE	@turnon
	
	LDA	#FALSE
	STA	GAMECORE + GAMEDATA::AutoEnb
	STA	GAMECORE + GAMEDATA::AutoCan
	
	LDA	#<MainMenuText8
	STA	MenuAutoText0
	LDA	#>MainMenuText8
	STA	MenuAutoText0 + 1
	
	RTS
	
@turnon:
	LDA	#TRUE
	STA	GAMECORE + GAMEDATA::AutoEnb
	STA	GAMECORE + GAMEDATA::AutoCan
	
	LDA	#<MainMenuText7
	STA	MenuAutoText0
	LDA	#>MainMenuText7
	STA	MenuAutoText0 + 1

	RTS


;-------------------------------------------------------------------------------
DoOptionsFlip:
;-------------------------------------------------------------------------------
	jsr	GotoFirstMenu
	rts



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
		.word	$0058
		.byte	03 | HORIZONTAL
		.word	MainMenuText0
		.byte	SUB_MENU
		.word	MainMenuGeos
		.word	MainMenuText1
		.byte	SUB_MENU
		.word	MainMenuFile
		.word	MainMenuText2
		.byte	SUB_MENU
		.word	MainMenuOptions
MainMenuGeos:
;-------------------------------------------------------------------------------
		.byte	$0F
		.byte	$1E
		.word	$0000
		.word	$0027
		.byte	01 | VERTICAL 	; | CONSTRAINED
		.word	MainMenuText3
		.byte	MENU_ACTION
		.word	DoGeosAbout
MainMenuFile:
;-------------------------------------------------------------------------------
		.byte	$0F
		.byte	$38
		.word	$001C
		.word	$0041
		.byte	03 | VERTICAL 	; | CONSTRAINED
		.word	MainMenuText4
		.byte	MENU_ACTION
		.word	DoFileNew
		.word	MainMenuText5
		.byte	MENU_ACTION
		.word	DoFileRestart
		.word	MainMenuText6
		.byte	MENU_ACTION
		.word	DoFileQuit
MainMenuOptions:
;-------------------------------------------------------------------------------
		.byte	$0F
		.byte	$2D
		.word	$0030
		.word	$007D
		.byte	02 | VERTICAL 	; | CONSTRAINED
MenuAutoText0:
		.word	MainMenuText7
		.byte	MENU_ACTION
		.word	DoOptionsAuto
MenuFlipText0:
		.word	MainMenuText9
		.byte	MENU_ACTION
		.word	DoOptionsFlip
MainMenuText0:
		.byte	"geos", $00
MainMenuText1:
		.byte	"file", $00
MainMenuText2:
		.byte	"options", $00
MainMenuText3:
		.byte	"about", $00
MainMenuText4:
		.byte	"new", $00
MainMenuText5:
		.byte	"restart", $00
MainMenuText6:
		.byte	"quit", $00
MainMenuText7:
		.byte	"auto solve: on", $00
MainMenuText8:
		.byte	"auto solve: off", $00
MainMenuText9:
		.byte	"flip count: 3", $00
MainMenuTextA:
		.byte	"flip count: 1", $00


CardPileLeft0:
		.word	CARDPLE0_LEFT
		.word	CARDPLE1_LEFT
		.word	CARDPLE2_LEFT
		.word	CARDPLE3_LEFT
		.word	CARDPLE4_LEFT
		.word	CARDPLE5_LEFT
		.word	CARDPLE6_LEFT
		
CardPileRight0:
		.word	CARDPLE0_RIGHT
		.word	CARDPLE1_RIGHT
		.word	CARDPLE2_RIGHT
		.word	CARDPLE3_RIGHT
		.word	CARDPLE4_RIGHT
		.word	CARDPLE5_RIGHT
		.word	CARDPLE6_RIGHT

SolvPileLeft0:
		.word	SOLVPLE0_LEFT
		.word	SOLVPLE1_LEFT
		.word	SOLVPLE2_LEFT
		.word	SOLVPLE3_LEFT
		
SolvPileRight0:
		.word	SOLVPLE0_RIGHT
		.word	SOLVPLE1_RIGHT
		.word	SOLVPLE2_RIGHT
		.word	SOLVPLE3_RIGHT


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
	.word	GAMECORE + GAMEDATA::FlipPl0


ProcessData0:
;-------------------------------------------------------------------------------
	.word	ProcAutoSolve
	.word	$1E


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


