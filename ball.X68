*-----------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta
* Date       : 10/01/20
* Description: Handles a significant amount of logic for the ball.
*              Contains collision checks for all 4 corners of the ball and the left/right middle of the ball
*              After checking for this collision, logic is in place for setting up which brick to destroy 
*              (or that the paddle was hit) and how much score to add.
*              This .x68 also updates the ball's velocity every frame and checks for collision with the walls
*              (screen sides).               
*-----------------------------------------------------------
HorizontalCollisionOffset           EQU     1       ; Pixels to add at the end of the ball to check for x-velocity change

RandomizeBallSelection
    jsr     GetRandomByteIntoD6
    move.l  #(AmountOfBalls-1),d1   ; -1 because the amount of balls is 1 higher than the random value check
    and.l   d1,d6                   ; Gets a value 0-7
    lea     Balls,a0                ; Load the group of addresses into a temp space
    lsl.l   #2,d6                   ; Shift the random value to eventually get the offset
    adda.l  d6,a0                   ; Add this offset to the ball array to get to the address where that ball is stored
    move.l  (a0),RandomlyChosenBall ; Move the the ball address into the variable for use in DrawBall
    rts   
    
UpdateBall
*Checks for collision with all possible objects -- powerups, bricks, paddle, and screen walls*
CollisionCheck
    lea     BallLeftPosCurr,a6
    lea     BallTopPosCurr,a5
    *Prep width/height for collisions*
    move.l  (a6),d1
    lsr.l   #LandShiftAmount,d1
    move.l  (a5),d2
    lsr.l   #LandShiftAmount,d2
    
    *Check for x-velocity flip first*
    *Mid left of ball*
    addi.l  #(BallHeightDisplay>>1),d2      ; Go down half the ball
    subi.l  #HorizontalCollisionOffset,d1   ; Subtract by this offset to get a wider range for collision
    
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #InnerGreenBrickColor,d0
    beq     SideGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     SideYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle

    addi.l  #HorizontalCollisionOffset,d1   ; Add this back to get the mid-left of the ball exactly
    *Check for x-velocity flip first*
    *Mid right of ball*
    addi.l  #(BallWidthDisplay+HorizontalCollisionOffset),d1 ; Captures the mid-right of the ball plus the offset
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #InnerGreenBrickColor,d0
    beq     SideGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     SideYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle
    
    *Prep width/height for collisions*
    move.l  (a6),d1
    lsr.l   #LandShiftAmount,d1
    move.l  (a5),d2
    lsr.l   #LandShiftAmount,d2
    
    *Top-left of ball*
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #InnerGreenBrickColor,d0
    beq     TopGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     TopYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle

    *Bottom-left of ball*
    addi.l  #BallHeightDisplay,d2           ; Only need to add the height to the top-left of the ball to get bottom-left
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #PaddleColor,d0
    beq     HitPaddle
    cmpi.l  #InnerGreenBrickColor,d0
    beq     BottomGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     BottomYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle    
    
    *Bottom-right of ball*
    addi.l  #BallWidthDisplay,d1            ; Add the width of the ball to get from bottom-left to bottom-right
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #PaddleColor,d0
    beq     HitPaddle
    cmpi.l  #InnerGreenBrickColor,d0
    beq     BottomGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     BottomYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle
    
    ; Top-right of ball
    subi.l  #BallHeightDisplay,d2           ; Sub the height of the ball to get from bottom-right to top-right
    move.l  #GetPixelColorTrap,d0
    trap    #15
    cmpi.l  #InnerGreenBrickColor,d0
    beq     TopGreen
    cmpi.l  #InnerYellowBrickColor,d0
    beq     TopYellow
    cmpi.l  #DoubleColor,d0
    beq     EnableDoubleScore
    cmpi.l  #SpeedColor,d0
    beq     EnableSpeedPaddle
    
    bra     UpdateHorizontal
    
*If the ball hits the paddle, execute this*
HitPaddle
    move.l  CharXCoordinateLeftCurr,d7      ; Get current paddle position
    lsr.l   #LandShiftAmount,d7             ; Get back to 2^0 land
    sub.l   d7,d1                           ; Get position of ball relative to paddle
    lea     BallVelocityY,a0                ; Always flip y velocity
    move.l  #-BallVelocityYRef,(a0)
    lea     BallVelocityPaddleTable,a1      ; This table contains the velocity's to set at points on the paddle
    lea     BallVelocityX,a0
    asl.l   #2,d1                           ; Use this storage as an index in the table
    move.l  (a1,d1),d7                      ; Use this unused space to store the x velocity
    neg.l   d7                              ; Negate x velocity
    move.l  d7,(a0)                         ; Move the new velocity into the ball's x velocity
    jsr     PlayPaddleWall                  ; Sound
    bra     UpdateHorizontal
	
SideYellow
    jsr     AddYellowToScore
    bra     SideCollision
SideGreen
    jsr     AddGreenToScore
SideCollision
    jsr     FindBrickPosition
SideVelocityChange
    lea     BallVelocityX,a0
    neg.l   (a0)
    bra     CheckForWin
TopYellow
    jsr     AddYellowToScore
    bra     TopCollision
TopGreen
    jsr     AddGreenToScore
TopCollision                        ; When the top left or top right of the ball collides with something
    jsr     FindBrickPosition       ; Finds brick and removes it once found
TopVelocityChange
    lea     BallVelocityY,a0
    move.l  #BallVelocityYRef,(a0)
    bra     CheckForWin             ; Check to see if that was the last brick broken 
BottomYellow
    jsr     AddYellowToScore
    bra     BottomCollision
BottomGreen
    jsr     AddGreenToScore
BottomCollision                     ; When the bot left or bot right of the ball collides with something
    jsr     FindBrickPosition       ; Finds brick and removes it once found
BottomVelocityChange
    lea     BallVelocityY,a0
    move.l  #-BallVelocityYRef,(a0)  
                                    ; Fall through to win check
CheckForWin
    subi.l  #1,BrickCounter         ; Decrement brick counter
    beq     GameWinSetup            ; If 0, the player has won, set up the UI for that
    rts
    
*Assumes the player has not won and the brick (if collided with it) has already been destroyed*
*Updates the horizontal movement of the ball*
UpdateHorizontal
    jsr     InvalBall               ; Remove ball from scene
    lea     BallVelocityX,a0        ; Prep velocity change
    move.l  (a0),d0
    add.l   d0,(a6)
    
	cmpi.l	#(BGWidthDisplay-BallWidthDisplay)<<LandShiftAmount,(a6) ; Check if ball hit right side of screen
	ble	    noNegativeSetHorizontal
	jsr     PlayPaddleWall          ; Sound
	neg.l   (a0)                    ; Negate x-velocity
	bra	    noPositiveSetHorizontal
noNegativeSetHorizontal
	cmpi.l	#0,(a6)                 ; Check if ball hit left side of screen
	bgt	    noPositiveSetHorizontal
	jsr     PlayPaddleWall
	neg.l   (a0)                    ; Negate x-velocity
noPositiveSetHorizontal
                                    ; Do nothing in this case, and purposely fall through to UpdateVertical	
*Updates the vertical movement of the ball
UpdateVertical
    lea     BallVelocityY,a0
    move.l  (a0),d0                 
    add.l   d0,(a5)                 ; Add to the y-velocity here
    
	cmpi.l	#(BGHeightDisplay-BallHeightDisplay)<<LandShiftAmount,(a5) ; Check if ball hit bottom of screen
	ble	    noNegativeSetVertical
	
    jsr     DecrementLives          ; Ball hit bottom of screen, so try to decrement a life
	rts
noNegativeSetVertical
	cmpi.l	#0,(a5)                 ; Check if ball hit top of screen
	bgt	    noPositiveSetVertical
	move.l	#BallVelocityYRef,(a0)  ; Ball hit top of screen
	jsr     PlayPaddleWall
	rts
noPositiveSetVertical
    rts
    
*Sets the ball's information back to default values -- used when lives are decremented and game is reset*
ResetBallInformation
    move.l  #(BallLocationScreenY),BallTopPosCurr
    move.l  #(BallLocationScreenX),BallLeftPosCurr
    move.l  #BallStartingVelocityX, BallVelocityX
    move.l  #BallVelocityYRef,BallVelocityY
    rts



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
