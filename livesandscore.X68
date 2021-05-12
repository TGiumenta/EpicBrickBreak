*-----------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta 
* Date       : 10/04/20
* Description: The hub for all of the lives and score logic.
*              Used after bricks are inval'd (destroyed) and adds the correct score based on the color
*              Also used when the ball hits the bottom of the screen, indicating that the player lost a life
*              Also updates the LED displays of the score & lives
*              Contains setup "functions" for both game win and lose, calls information in the startendui.x68
*-----------------------------------------------------------
*All Registers*
AllRegisters                    REG     D0-D7/A0-A6

*Preps the value of the yellow brick to local space, considering if they collected the powerup or not*
AddYellowToScore
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    move.l  #YellowBrickScore,d0
    bra     AddScore
*Preps the value of the green brick to local space, considering if they collected the powerup or not*
AddGreenToScore
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    move.l  #GreenBrickScore,d0
*Finally adds the score based on brick color
AddScore
    move.b  (DoubleScoreCollected),d1
    asl.b   d1,d0                       ; If the powerup is enabled, the score to be added will be shifted by 1, or doubled
    add.l   d0,(Score)                  ; Increment score
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts

*Called after the ball hits the bottom of the screen, is a hub for calling "functions" required for resetting
*ball position and updating LEDs*
DecrementLives
    lea     Lives,a1
    subi.l  #1,Lives
    beq     GameOverSetup 
    jsr     InvalPlayer                 ; Remove the player from the scene
    jsr     DrawPlayerInitial           ; Move the player back to the starting point 
    jsr     ResetBallInformation        ; Reset ball position & velocity to get back to initial position
    jsr     DrawBall                    
    jsr     UpdateLED                   ; Update both here so that lives updates prior to delay and 
                                        ; as a precaution for updating score
    jsr     SwapBuffer                  ; Show the updated UI and player/ball position to the player
    move.l  #DelayTime,d1               ; Essentially pauses the game for a short while so the player can 
                                        ; gather surroundings and pla again
    move.l  #DelayTrap,d0
    trap    #15
    rts   
    
*Called within the game loop, both LEDs are updated*
UpdateLED
    jsr     InvalLED
    jsr     SetLivesLED                 ; Called every frame regardless if lives are lost or not, for clarity
                                        ; # digits is small enough to print quickly enough
    jsr     SetScoreLED
    rts
SetLivesLED
    move.l  (Lives),d0
    clr.l   (OriginOffset)
    jsr     LEDSegmentDisplay
    rts
SetScoreLED
    move.l  (Score),d0
    move.l  #LEDScoreOffset,OriginOffset
    jsr     LEDSegmentDisplay
    rts 
    
*Hub for game loss, calls supporting "functions"*
GameOverSetup
    jsr     ClearScreen
    jsr     SwapBuffer
    jsr     ShowGameOverUI
    jsr     SwapBuffer
    jsr     EndGameInput
ReturnToGameLoop
    rts                                 ; Back to game loop
    
*Hub for game win, calls supporting "functions"*
GameWinSetup
    jsr     ClearScreen
    jsr     SwapBuffer
    jsr     ShowGameWinUI
    jsr     SwapBuffer
    jsr     EndGameInput
    rts                                 ; Back to game loop





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
