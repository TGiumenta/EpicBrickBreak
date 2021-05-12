*-----------------------------------------------------------
* Title      : 3 
* Written by : Tony Giumenta
* Date       : 10/01/20
* Description: BrickHandler
*-----------------------------------------------------------
*Stack equates*
InitializeSpaceAmount       EQU     8       ; Offset the stack for this/2 different local variables
BrickCounterOffset          EQU     0       ; Offset on the stack for this equate
BrickLocationOffset         EQU     4       ; Offset on the stack for this equate

BrickHeightOffset           EQU     8       ; Space in between rows of bricks

*Equates for checking wehich brick to destroy*
LongByteOffset              EQU     4       ; Used when doing a register offset during FindBrick
BricksPerRow                EQU     14 
RowsOfBricks                EQU     8
AmountOfBricks              EQU     BricksPerRow*RowsOfBricks
NextWordOffset              EQU     2
HeightWordOffset            EQU     2       ; Gets the last row of bricks given 
WidthWordOffset             EQU     4       ; Gets the last brick's x-coordinate in a row
BrickRowOffset              EQU     0    
BrickRowOffsetStarter       EQU     (LongByteOffset*AmountOfBricks)-HeightWordOffset
BrickInRowStarterValue      EQU     (LongByteOffset*AmountOfBricks)-WidthWordOffset

*Setup temporary spaces for repeated use for drawing bricks*
DrawBricks
    sub.l   #InitializeSpaceAmount,sp
    move.l  #AmountOfBricks,BrickCounterOffset(sp)
    clr.l   BrickLocationOffset(sp)
    lea     BrickArray,a6
    move.l  #StartingXPosition,d6   
    move.l  #StartingYPosition,d7           ; Starting y positions for bricks
    
*Loops through an entire row to print its bricks*
LoopBegin
    cmpi.l  #(BGWidthDisplay-BrickWidthDisplay),d6
    beq     ResetRow
    
    jsr     BrickDraw
    
    ; Move position of bricks to array
    move.l  BrickLocationOffset(sp),d5
    move.w  d6,(a6,d5)                      ; Move the x-position into the brick array
    addi.l  #NextWordOffset,d5              ; Add two to get to the next word
    move.w  d7,(a6,d5)                      ; Move the y-position into the brick array
    addi.l  #NextWordOffset,d5              ; Add two to get to the next word, a 0,0 position for next brick
    move.l  d5,BrickLocationOffset(sp)      ; Shift the location offset over by a long-word
    
    addi.l  #BrickWidthDisplay,d6           ; Next x-position should be the current position plus a brick's length
    
    subi.l  #1,BrickCounterOffset(sp)       ; Decrement amount of bricks to print
    cmpi.l  #0,BrickCounterOffset(sp)       ; If not 0, keep printing bricks
    bne     LoopBegin
    
    add.l   #InitializeSpaceAmount,sp       ; Add back the values to the stack pointer
    rts
*Got to the end of the row, move up a row and start back at x's start*
ResetRow
    move.l  #StartingXPosition,d6
    addi.l  #(BrickHeightDisplay+BrickHeightOffset),d7
    bra     LoopBegin
    
FindBrickPosition
    lea     BrickArray,a4
    move.l  #BrickRowOffsetStarter,d7
    move.w  (a4,d7),d7          ; This space now holds the height row offset
FindRowBrick
    cmp.l   d7,d2               ; If the height of collision is higher than the last row, it hit the last row
    bge     FindBrickInRow
    subi.l  #(BrickHeightDisplay+BrickHeightOffset),d7
    bra     FindRowBrick
FindBrickInRow
    move.l  #BrickInRowStarterValue,d6
    move.w  (a4,d6),d6          ; This space now holds the brick's x position value in the row
FindBrickInRowLoop
    cmp.l   d6,d1               ; If the x-value of collision is higher than the last brick, this is the brick hit
    bge     FoundBrick          ; Found brick to destroy
    subi.l  #BrickWidthDisplay,d6
    bra     FindBrickInRowLoop
FoundBrick
    jsr     InvalBrick          ; Once found, draw over it
    jsr     PlayBrickExplode    ; Sound
    rts














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
