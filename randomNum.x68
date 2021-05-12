*---------------------------------------------------------------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta
* Date       : 09/29/20
* Description: A random number generator from Dr. Tom Carbone.
*              Contains a way to seed the value using the time since midnight
*---------------------------------------------------------------------------------------------------------------
ALL_REG                 REG     D0-D7/A0-A6
Counter                 EQU     18

*Seeds a random number -- assumes that the game is not played precisely at midnight
SeedRandomNumber
        movem.l ALL_REG,-(sp)
        clr.l   d6
        move.b  #GetTimeTrap,d0
        trap    #15

        move.l  d1,RandomValue
        movem.l (sp)+,ALL_REG
        rts

GetRandomByteIntoD6
        *Make room for 3 local variables*
        movem.l d0,-(sp)
        movem.l d1,-(sp)
        movem.l d2,-(sp)
        move.l  RandomValue,d0
       	moveq	#$AF-$100,d1
       	moveq	#Counter,d2             ; Counter for below
Ninc0	
	add.l	d0,d0
	bcc	Ninc1
	eor.b	d1,d0
Ninc1
        dbf	d2,Ninc0
	move.l	d0,RandomValue
	clr.l	d6
	move.b	d0,d6
	
	*Fix stack pointer*
        movem.l (sp)+,d2
        movem.l (sp)+,d1
        movem.l (sp)+,d0
        rts

TEMPRANDOMLONG  ds.l    1








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
