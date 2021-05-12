*-----------------------------------------------------------------------------------------------
* Title      : 3 
* Written by : Tony Giumenta
* Date       : 10/06/20
* Description: A handler for all things related to enabling and disabling powerups.
*              Each "function" needs to be separated due to its boolean setting as well as its 
*              different effects and potential sound effects
*-----------------------------------------------------------------------------------------------
EnableDoubleScore
    move.b  #1, (DoubleScoreCollected)      ; Sets the collected bool to true
    jsr     InvalDoubleScore                ; Remove the powerup from the scene to prevent double collection
    jsr     ShowDoubleScoreText             ; UI indicator in the black bar part of the screen
    jsr     PlayPowerup                     ; Sound
    rts
   
EnableSpeedPaddle
    move.b  #1, (PaddleSpeedCollected)      ; Sets the collected bool to true
    jsr     InvalPaddleSpeed                ; Remove the powerup from the scene to prevent double collection
    jsr     ShowPaddleSpeedText             ; UI indicator in the black bar part of the screen
    jsr     PlayPowerup                     ; Sound
    rts
    
*Used when resetting the game, sets the collected booleans back to false
DisablePowerups
    clr.b   (DoubleScoreCollected)
    clr.b   (PaddleSpeedCollected)
    rts


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
