;************************************************************************
;
;	SamSeqHdr
;
;	This file contains the header block definition for the GeoProgrammer
;	package sample sequential application.
;
;Copyright (c) 1987 Berkeley Softworks. Released to the Public Domain.
;
;Translation to the Ophis assembler by Daniel England, 2016.
;************************************************************************

	.include	"geosSym.inc"		;get GEOS definitions
	
;Here is our header. The SamSeq.lnk file will instruct the linker
;to attach it to our sample application.

	.word	0				;first two bytes are always zero
						;dengland: These are replaced with sector
						;data by build tool.
	.byte	3				;Icon width in bytes
	.byte	21				;Icon height in scanlines

;		$03, $15, $00
	.byte	               $BF, $FF, $FF, $FF, $80	;Icon data
	.byte	$00, $01, $80, $00, $01, $80, $00, $01
	.byte	$80, $00, $01, $9F, $00, $01, $B7, $00
	.byte	$01, $B3, $1C, $79, $9C, $36, $D9, $86
	.byte	$3E, $D9, $B3, $30, $D9, $BB, $36, $D9
	.byte	$BE, $1C, $79, $80, $00, $19, $80, $00
	.byte	$3D, $80, $00, $01, $80, $00, $01, $80 
	.byte	$00, $01, $80, $00, $01, $80, $00, $01
	.byte	$FF, $FF, $FF

	.byte	$80 | USR			;Commodore file type, with bit 7 set.
	.byte	APPLICATION			;Geos file type
	.byte	SEQUENTIAL			;Geos file structure type
						;dengland: Need to specify this
	.word	$0400				;start address of program (where to load to)
	.word	$03FF				;usually end address, but only needed for
						;desk accessories.
						;dengland: Need to specify this
	.word	$0400				;init address of program (where to JMP to)
	.byte	"SampleSeq   V1.0",0,0,0,$00
						;permanent filename: 12 characters,
						;followed by 4 character version number,
						;followed by 3 zeroes,
						;followed by 40/80 column flag.
	.byte	"Eric E. Del Sesto  ",0
						;twenty character author name

						;dengland:  I didn't like space and 
						;	.advance won't work
						;dengland:  Lets make this proper :P
	.byte	$00, $00, $00, $00, $00, $00, $00, $00	; parent 20 bytes
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00
	
	.byte	$00, $00, $00, $00, $00, $00, $00, $00	; app data 23 bytes
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00
	
						;dengland:  The description is 96 bytes
	.byte	"This is the GeoProgrammer sample"	; 32
	.byte	" sequential GEOS application.",0,0,0	; 64
	.byte	0, 0, 0, 0, 0, 0, 0, 0			; 72
	.byte	0, 0, 0, 0, 0, 0, 0, 0			; 80
	.byte	0, 0, 0, 0, 0, 0, 0, 0			; 88
	.byte	0, 0, 0, 0, 0, 0, 0, 0			; 96
