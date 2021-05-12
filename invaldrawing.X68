*------------------------------------------------------------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta
* Date       : 09/30/20
* Description: The home for the invalidating all drawings and drawing various bitmaps.
*              Invalidating an image is the process of drawing over that image with a chunk of the
*              background. So for each invalidating "function", the background is loaded and the
*              the set of variables that follow are setup specifically to draw the part of the background
*              that will cover the image. 
*              Format:
*              a0 = Image to draw
*              d0/d1 = Top-left/right chunk of the loaded image to draw
*              d2 = The width (in pixels) to draw
*              d3 = The offset in the pixel array to read the width of the image at a0
*              d4 = The offset in the pixel array to read the height of the image at a0
*              d5 = The height (in pixels) to draw
*              d6/d7 = The x-location/y-location to draw the image in respect to the screen's resolution
*------------------------------------------------------------------------------------------------------------
*All Registers*
AllRegisters                    REG     D0-D7/A0-A6
InvalPlayerExtraBits            EQU     2            ; Extra pixels to draw to ensure it gets all the paddle pixels

*Yellow Brick Columns*
FirstCol                        EQU     40
SecondCol                       EQU     FirstCol+200
ThirdCol                        EQU     SecondCol+120
FourthCol                       EQU     ThirdCol+200

*Draws the entire background -- this only happens when the game gets reset*
DrawBackgroundFull
    lea     Background,a0
    move.l  #DefaultCornerX, d0
    move.l  #DefaultCornerY, d1
    move.l  #BGWidthDisplay, d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileOffset(a0),d4
    move.l  #BGHeightDisplay, d5
    move.l  #BGLocationScreenX,d6       ; Shift by the land shift to get the correct pixel location
    move.l  #BGLocationScreenY,d7
    subi.l  #1, d7                      ; Gets rid of the black pixel row on the top of each bitmap
    jsr     DrawBitmap
    rts

*The first instance of drawing the player, this is used when resetting the game*
DrawPlayerInitial
    move.l  #PlayerStartingPosX, CharXCoordinateLeftCurr    ; Reset character starting position
*Draws the player, which is a rectangle, hence why the DrawBitmap is never called*
DrawPlayer
    move.l  #PaddleColor,d1             ; Preps a space to hold the color of the outline of the rectangle
    move.l  #PenColorTrap,d0
    trap    #15
    move.l  #FillColorTrap,d0           ; Fill the rectangle with the Paddle color
    trap    #15
    
    lea     CharXCoordinateLeftCurr,a2  ; Load the current position of the player
    move.l  (a2),d1                     ; The left side of the player holds the x-position of the top left value
    lsr.l   #LandShiftAmount,d1         ; Shift by the land shift to get the correct pixel location
    move.l  #(LocationScreenY-1),d2     ; Gets rid of the black pixel row on the top of each bitmap
    move.l  d1,d3                       ; Can re-use the top-left x-value
    addi.l  #(PaddleWidth-1),d3         ; Add the paddle width to get the top-right x-value
    move.l  d2,d4                       ; Can reuse the upper-right y-value
    addi.l  #(PaddleHeight-1),d4        ; Gets rid of the black pixel row on the top of each bitmap
    move.l  #DrawRectangleTrap,d0
    trap    #15
    
    move.l  #BlackColor,d1              ; Reset fill color so that the UI can use a black fill color
    move.l  #FillColorTrap,d0
    trap    #15
    rts
    
*Replaces the entire player with the background*
*This can be optimized based on directional movement but this is done for safety and concise code*
InvalPlayer
    lea     CharXCoordinateLeftCurr,a2
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    lea     Background,a0
    move.l  (a2),d0
    lsr.l   #LandShiftAmount,d0         ; Shift by the land shift to get the correct pixel location
    move.l  #LocationScreenY,d1         ; The Y-chunk needs to start with the location of the paddle
    move.l  #PaddleWidth,d2             ; Width value
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileOffset(a0),d4
    move.l  #PaddleHeight,d5            ; Height value
    move.l  (a2),d6                     ; Load the player's x-position as the x-position to draw
    lsr.l   #LandShiftAmount,d6         ; Shift by the land shift to get the correct pixel location
    move.l  #LocationScreenY,d7         ; Load the player's y-position as the y-position to draw
    subi.l  #InvalPlayerExtraBits, d7   ; Gets rid of the extra pixel row on the top of each bitmap
    jsr     DrawBitmap
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts
   
*Replaces the ball with the background. The size of the ball is small enough to replace the whole background*
InvalBall
    lea     Background, a0
    lea     BallTopPosCurr,a5
    lea     BallLeftPosCurr,a6
    move.l  (a6),d0                     ; Use the ball's left position as the top-left chunk to inval
    lsr.l   #LandShiftAmount,d0         ; Shift by the land shift to get the correct pixel location
    move.l  (a5),d1                     ; Use the ball's top position as the top-right chunk to inval
    lsr.l   #LandShiftAmount,d1         ; Shift by the land shift to get the correct pixel location
    move.l  #BallWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4 
    move.l  #BallHeightDisplay,d5
    move.l  d0,d6                       ; Re-use the ball's location for the location to invaldiate
    move.l  d1,d7
    subi.l  #1, d7                      ; Gets rid of the extra pixel row on the top of each bitmap
    jsr     DrawBitmap
    rts
    
*The first instance of drawing the ball, this is used when resetting the game*
DrawBallInitial
    move.l  #BallLocationScreenY,BallTopPosCurr
    jsr     RandomizeBallSelection      ; Loads the randomized ball
*Draws the randomized ball chosen above, should be called after InvalBall and updating ball velocity*
DrawBall
    lea     BallTopPosCurr,a5
    lea     BallLeftPosCurr,a6
    lea     RandomlyChosenBall,a1       ; Loads the address of the variable which contains the address of the ball
    move.l  (a1),a0                     ; Loads the address of the ball into a0 for printing using DrawBitmap
    move.l  #DefaultCornerX,d0
    move.l  #DefaultCornerY,d1
    move.l  #BallWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileOffset(a0),d4
    move.l  #BallHeightDisplay,d5
    move.l  (a6),d6                     ; This is populated during UpdateBall and holds the horizontal movement
    lsr.l   #LandShiftAmount,d6         ; Shift by the land shift to get the correct pixel location 
    move.l  (a5),d7
    lsr.l   #LandShiftAmount,d7         ; This is populated during UpdateBall and holds the vertical movement
    subi.l  #1,d7                       ; Gets rid of the black pixel row on the top of each bitmap
    jsr     DrawBitmap
    
    rts
    
*Draws a brick to a particular location, location already set beforehand (See DrawBricks)*
BrickDraw
CheckForYellowBrickDraw
    cmpi.l  #FirstCol,d6                ; First column chosen to draw a yellow brick
    beq     LoadYellow
    cmpi.l  #SecondCol,d6
    beq     LoadYellow
    cmpi.l  #ThirdCol,d6
    beq     LoadYellow
    cmpi.l  #FourthCol,d6
    beq     LoadYellow
*Loads either the green or yellow brick into the image area*
LoadGreen
    lea     GreenBrick,a0 
    bra     FinishDraw
LoadYellow 
    lea     YellowBrick,a0
*Actually draws the brick after loading the correct brick into the image location
FinishDraw
    addi.l  #(BrickWidthDisplay>>1),d6      ; Check the space ahead if there is a powerup
    move.l  d6,d1                           ; Prep local spaces to check for pixel color at a location
    move.l  d7,d2
    move.l  #GetPixelColorTrap,d0           ; Requires that the center of the powerup be of certain color
    trap    #15
    subi.l  #(BrickWidthDisplay>>1),d6
    
    cmpi.l  #DoubleColor,d0
    beq     DontDraw 
    cmpi.l  #SpeedColor,d0
    beq     DontDraw

    move.l  #DefaultCornerX,d0
    move.l  #DefaultCornerY,d1
    move.l  #BrickWidthDisplay, d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileOffset(a0),d4
    move.l  #BrickHeightDisplay,d5
    jsr     DrawBitmap
    jsr     SwapBuffer                      ; Show the brick that was just drawn
DontDraw
    rts
FinishEarly
    rts

*Replaces the chosen brick with the background*
*Notice that the location x/y is already pre-loaded from FindBrickPosition, can't call this from anywhere*
InvalBrick
    lea     Background,a0
    move.l  d6,d0
    move.l  d7,d1
    move.l  #BrickWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4
    move.l  #BrickHeightDisplay,d5
    jsr     DrawBitmap
    
    rts

*On game reset, draws all of the powerup blocks in their decided location*
DrawPowerups
*The 2x Score block*
*Remember to prepare the locations prior to entering this draw function*
DrawDoubleScore
    lea     DoublePowerup,a0
    move.l  #DefaultCornerX,d0
    move.l  #DefaultCornerY,d1
    move.l  #PowerupWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4
    move.l  #PowerupHeightDisplay,d5
    ;move.l  #DoubleLocationScreenX,d6
    ;move.l  #DoubleLocationScreenY,d7
    jsr     DrawBitmap
    rts
*The Extra Paddle Speed block*
*Remember to prepare the locations prior to entering this draw function*
DrawPaddleSpeed
    lea     PaddleSpeed,a0
    move.l  #DefaultCornerX,d0
    move.l  #DefaultCornerY,d1
    move.l  #PowerupWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4
    move.l  #PowerupHeightDisplay,d5
    ;move.l  #SpeedLocationScreenX,d6
    ;move.l  #SpeedLocationScreenY,d7
    jsr     DrawBitmap
    rts
    
*After collecting the powerup, invalidate it and remove it from the game*
InvalDoubleScore
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
    lea     Background,a0
    move.l  #DoubleLocationScreenX,d0
    move.l  #DoubleLocationScreenY,d1
    move.l  #PowerupWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4
    move.l  #PowerupHeightDisplay,d5
    move.l  #DoubleLocationScreenX,d6
    move.l  #DoubleLocationScreenY,d7
    jsr     DrawBitmap
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts 
InvalPaddleSpeed
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
    lea     Background,a0
    move.l  #SpeedLocationScreenX,d0
    move.l  #SpeedLocationScreenY,d1
    move.l  #PowerupWidthDisplay,d2
    move.w  WidthFileOffset(a0),d3
    move.w  HeightFileoffset(a0),d4
    move.l  #PowerupHeightDisplay,d5
    move.l  #SpeedLocationScreenX,d6
    move.l  #SpeedLocationScreenY,d7
    jsr     DrawBitmap
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts 
    
*Draws over the LED values with a black rectangle since the LEDs are both displayed in the black bar*
InvalLED
    move.l  #BlackColor,d1              ; Preps a space to hold the color of the outside of the rectangle
    move.l  #PenColorTrap,d0
    trap    #15
    move.l  #FillColorTrap,d0           ; Fill the rectangle with the black background
    trap    #15
    
    *Lives*
    move.l  #LEDEdgeLeft,d1             ; Top x-value
    move.l  #LEDTopLeft,d2              ; Top y-value
    move.l  #LEDEdgeRight,d3            ; Bottom x-value
    move.l  #LEDBotRight,d4             ; Bottom y-value
    move.l  #DrawRectangleTrap,d0
    trap    #15
    
    *Score*
    addi.l  #(LEDScoreOffset-StartingSegOffset),d1  ; Add the offset to the beginning of the rectangle
    move.l  #BGWidthDisplay,d3                      ; Inval all the way to the edge of the screen to ensure its inval'd
    trap    #15

    rts























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
