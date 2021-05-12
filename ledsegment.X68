*-----------------------------------------------------------
* Title      : 3
* Written by : Tony Giumenta
* Date       : 10/07/20
* Description: LED 7-Segment Display
*-----------------------------------------------------------
AllRegisters            REG     D0-D7/A0-A6  
LengthOfTables          EQU     48          ; The amount of words in the segment tables
                                            ; Used as an offset for either lives (not used) or score (used)
                                        
OriginOffset            dc.l    0           ; The value added to the x coordinates for offsetting either the score or lives
                                            ; 0 will be the value for the lives, and LEDScoreOffset for the score
LEDScoreOffset          EQU     516         ; Value added to x position of the score digits
DigitOffset             EQU     16          ; Subtract this value to put the current digit to the left of the previous

DivideAmount            EQU     10          ; Divide out 10 to get digits and their remainders
WhiteColor              EQU     $00FFFFFF   ; Hex representation of the color white for pen color

*X values*
LEDEdgeLeft             EQU     72          ; X-value on the left-side of the screen
LEDEdgeRight            EQU     82          ; X-value on the right-side of the screen
*Y values*
LEDTopLeft              EQU     722
LEDMidLeft              EQU     732
LEDBotLeft              EQU     742
LEDTopRight             EQU     722
LEDMidRight             EQU     732
LEDBotRight             EQU     742 

NextWordOffset          EQU     2
StartingSegOffset       EQU     48                  ; Starting offset in the table to get the desired segment set
DynamicSegmentOffset    dc.l    StartingSegOffset   ; Dynamic offset in the table tracking current segment offset
OffsetSubtract          EQU     8                   ; Amount of words to subtract from segment offset to get next segment

LEDSegmentDisplay
    lea     OriginOffset,a1
OuterLoop
    divu    #DivideAmount,d0        ; Divide out the first
    swap    d0                      ; Got first digit into 1st word of d0
    move.w  d0,d7                   ; Move the value into a space used by the loop
    jsr     InnerSetup
    subi.l  #DigitOffset,(a1)       ; As each digit gets printed, subtract out an offset and orientate origin
    clr.w   d0                      ; This digit is done, clear it it out
    swap    d0                      ; Swap in the remainder from the previous division
    move.l  #StartingSegOffset,(DynamicSegmentOffset)   ; Reset the offset in the segmentWHTable to start looking at the top segment (G)
    cmpi.l  #0,d0                   ; If the remainder was 0, the value is done being printed
    beq     FinishedSubroutine
    bra     OuterLoop
   
InnerSetup
    movem.l AllRegisters,-(sp)      ; Save all original variables onto the stack
    lea     segmentTable,a0
    
    move.b  (a0,d7),d5              ; This space has the binary representation of the 7-Segment LED
    move.b  d5,d6                   ; Use this space as a place to loop and operations without destroying the binary segment representation
Loop
    andi.l  #1,d6                   ; If 1, print the segment, otherwise shift the value out of the representation and check if done
    bne     DrawSegment
    bra     ShiftValAndCheckForDone  
DrawSegment
    move.l  #WhiteColor,d1          
    move.l  #PenColorTrap,d0
    trap    #15                     ; Sets the pen color to white
    clr.l   d1
    lea     segmentWHTable,a0
    jsr     PopulateFromTable       ; Gets the line coordinates prepared for drawing
    move.l  #DrawLineTrap,d0       
    trap    #15                     ; Draw the line that's made through PopulateFromTable
    
    bra     ShiftValAndCheckForDone
ShiftValAndCheckForDone
    lsr.b   #1,d5                                   ; Shift out the least significant bit
    beq     DoneDigit                               ; If the representation is 0, done printing segments for that digit
    move.l  d5,d6
    subi.l  #OffsetSubtract,DynamicSegmentOffset    ; Changes the offset value to read in the segmentWHTable
    bra     Loop
    
PopulateFromTable
    move.l  (DynamicSegmentOffset),d0   ; The holds the offset for the current segment
    move.w  (a0,d0),d1                  ; Get the beginning of the line's x value
    add.l   (OriginOffset),d1
    addi.l  #NextWordOffset,d0          ; Shift the offset up to read the next word to get the next position
    move.w  (a0,d0),d2                  ; Get the beginning of the line's y value
    addi.l  #NextWordOffset,d0          ; Shift the offset up to read the next word to get the next position
    move.w  (a0,d0),d3                  ; Get the end of the line's x value
    add.l   (OriginOffset),d3       
    addi.l  #NextWordOffset,d0          ; Shift the offset up to read the next word to get the next position
    move.w  (a0,d0),d4                  ; Get the end of the line's y value
    addi.l  #NextWordOffset,d0          ; Shift the offset up to read the next word to get the next position
    rts

DoneDigit
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts                                 ; Go back to OuterLoop to check if digits are done printing
FinishedSubroutine
    rts                                 ; All digits are printed, return back

                                        ;      ABC DEFG
segmentTable            dc.b    $7E     ; 0 = 0111 1110
                        dc.b    $30     ; 1 = 0011 0000
                        dc.b    $6D     ; 2 = 0110 1101
                        dc.b    $79     ; 3 = 0111 1001
                        dc.b    $33     ; 4 = 0011 0011
                        dc.b    $5B     ; 5 = 0101 1011
                        dc.b    $5F     ; 6 = 0101 1111
                        dc.b    $70     ; 7 = 0111 0000
                        dc.b    $7F     ; 8 = 0111 1111
                        dc.b    $7B     ; 9 = 0111 1011

segmentWHTable          dc.w    LEDEdgeLeft,LEDTopLeft,LEDEdgeRight,LEDTopRight     ; Top left to top right   (A)
                        dc.w    LEDEdgeRight,LEDTopRight,LEDEdgeRight,LEDMidRight   ; Top right to mid right  (B)
                        dc.w    LEDEdgeRight,LEDMidRight,LEDEdgeRight,LEDBotRight   ; Mid right top bot right (C)
                        dc.w    LEDEdgeLeft,LEDBotRight,LEDEdgeRight,LEDBotLeft     ; Bot right to bot left   (D)
                        dc.w    LEDEdgeLeft,LEDBotLeft,LEDEdgeLeft,LEDMidLeft       ; Bot left to mid left    (E)
                        dc.w    LEDEdgeLeft,LEDMidLeft,LEDEdgeLeft,LEDTopLeft       ; Mid left to top left    (F)
                        dc.w    LEDEdgeLeft,LEDMidLeft,LEDEdgeRight,LEDMidRight     ; Mid left to mid right   (G)




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
