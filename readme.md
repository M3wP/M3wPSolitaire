# M3wP Solitaire!

## Introduction

Hello and welcome to the **M3wP Solitaire** read me!

I got the urge to play Solitaire occasionally on my tablet.  All of the implementations I've seen have ads and I hate them.  I decided to write my own...

It took only a day to write the core logic and another two days to do the nice features and effects.  I had previously created a set of cards, modifying and fixing a freely available set.

I wrote the game using the Community Edition of Embarcadero's Delphi 10.3 with the FMX framework and was very impressed with how easily I was able to put it together.

As a result, the source can be compiled for almost any modern platform you can think of but I do not have the required tools (a Mac and Enterprise Edition) to compile for anything other than Windows and Android.  If someone were to compile this for other platforms (Linux and Mac in particular), I would be very keen to hear from you at the address given below.

In addition to the modern platform implementation, I have ported the code to GEOS for the Commodore 64!  This was a necessity, of course!  A further port to the Apple II should be very easy to do.


## Download and Installation

You will find the binaries for your platform in the relevant folder under the _bin_ folder in the repository main folder.  Simply download the binary file to some local folder and play!  

On Windows, you will likely need to tell Windows Defender that you want to "Run Anyway" because the executable is not properly signed as yet.

For Android, you will need to use adb to install the package on your device.  All Android  devices, using screens from 3" to 10" and versions 6 and above should be supported.

On the Commodore 64, you will need to have a copy of GEOS (which is now freely available) and using the disk image binary, launch the contained application.  You will need other tools (ZoomFloppy for example) to get the image onto a real disk for use on a real machine.


## Compiling

The modern implementation is written using Delphi FMX.  You should find all you need in the _src_ folder.  The apps can be compiled with the latest Community Edition of Delphi 10.3.  

A variety of systems should be supported including MacOS, Win32/Win64 and Linux (assuming compiler feature availability).

For the C64 platform, you will find the source in the _src/c64_ folder.  You will need ca65 and cl65 from the cc65 suite.  You will also require my GEOSBuild tool to build the final disk image which you can find at https://github.com/M3wP/GEOSBuild  

There is presently a bug in the GEOSBuild tool which will occasionally causes problems so the disk image needs to be deleted before calling it. 

The steps to build the Commodore 64 version are as follows:

	ca65 -o SolitaireHdr.obj SolitaireHdr.s
	cl65 -t none -o SolitaireHdr.bin SolitaireHdr.obj
	ca65 -o Solitaire.obj Solitaire.s
	cl65 -t geos-cbm -o Solitaire.bin Solitaire.obj
	del Solitaire.d64
	GEOSBuild Solitaire.gbuild


## Playing the Game

For all platforms, game play is easy.  Simply click (or tap) on the cards you want to move or on the spare deck to put cards into the flip pile.  You can click on any card in the card piles, the top card in the flip pile or solve piles and if there is a place for that card in the card piles, it (or all stacked cards) will be moved.

There are options for controlling whether "Auto Solve" is applied and the number of cards to flip into the flip pile.

For modern platforms, there are buttons down the left hand side of the screen.  In order from top to bottom they are:  New Game, Restart Game, Toggle Auto Solve, Set Flip Count and About.

For the Commodore 64, there are menus.  Under the GEOS menu you will find About and under the File menu, New, Restart and Quit while under the Options menu you will find the Auto Solve toggle and Flip Count setting.

On modern platforms, the current game is saved and restored between sessions.

You cannot "undo" a move.  This was a design decision and will not be changed at this time since I do not like it.  If you make a mistake, you can restart the game.


## Future Development

The modern platform implementation is complete.  No new features are planned.

The Commodore 64 implementation is currently in development.  Some colour fixes to the menus and end game effects are still to be done.


## Contact

Please feel free to contact me for further information.  You can reach me at:
	
	mewpokemon {at} hotmail {dot} com

Please include the string "M3wP Solitaire!" in the subject line or your mail might get lost.