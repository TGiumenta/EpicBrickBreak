*-----------------------------------------------------------
* Title      : 3
* Written by : Tony Giumenta
* Date       : 10/03/20
* Description: A hub for all things User Interface. 
*              Contains equates that are not meant to be changed because they are specifically text offsets
*              These equates are separated from main since they are very specific to UI
*              Contains a hub for game reset, as well as the logic for winning and losing the game
*              When drawing text UI, there's a particular process implemented:
*               1. Load the text from memory
*               2. Prep the width and height from a reused helper function
*               3. Add/Sub an offset defined by the equates that puts the image in the right spot
*               4. Execute the trap to show the image
*-----------------------------------------------------------
*Offsets for displaying text on the various menu/paused/loading screens, do not change*
*Main Menu UI*
TitleLeftOffset             EQU     115
TitleBottomOffset           EQU     100
StartLeftOffset             EQU     100
StartBottomOffset           EQU     TitleBottomOffset-25
UIShiftAmount               EQU     1       ; Used to get the middle of the screen in the preparation functions
QuitLeftOffset              EQU     103
QuitBottomOffset            EQU     TitleBottomOffset-50
ThanksLeftOffset            EQU     75

*Legend*
GoalLeftOffset              EQU     304
GoalBottomOffset            EQU     25
GreenBrickXPosition         EQU     250
GreenBrickYPosition         EQU     350
GreenBrickTextLeftOffset    EQU     20
GreenBrickTextBottomOffset  EQU     GoalBottomOffset-28
YellowBrickXPosition        EQU     GreenBrickXPosition
YellowBrickYPosition        EQU     GreenBrickYPosition+30
YellowBrickTextLeftOffset   EQU     GreenBrickTextLeftOffset
YellowBrickTextBottomOffset EQU     GreenBrickTextBottomOffset-28
PowerupsTextLeftOffset      EQU     220
PowerupsTextBottomOffset    EQU     YellowBrickTextBottomOffset+5      ; Depends on the brick's left/bottom offset
DoubleScoreXPosition        EQU     GreenBrickXPosition+5
DoubleScoreYPosition        EQU     YellowBrickYPosition+55
PaddleSpeedXPosition        EQU     DoubleScoreXPosition
PaddleSpeedYPosition        EQU     DoubleScoreYPosition+35
DoubleScoreInfoLeftOffset   EQU     YellowBrickTextLeftOffset
DoubleScoreInfoBottomOffset EQU     YellowBrickTextBottomOffset-62
PaddleSpeedInfoLeftOffset   EQU     DoubleScoreInfoLeftOffset
PaddleSpeedInfoBottomOffset EQU     DoubleScoreInfoBottomOffset+57      ; Depends on the bottom offset of the double score

*Loading Screen*
LoadingLeftOffset           EQU     40
LoadingScreenStartVelocity  EQU     2       ; Starting velocity for moving in the loading text (0.5)
LoadingTextStopLocation     EQU     552960  ; Stopping location for the text 270*2048 = 552960 (2^-11 land) 
LoadingScreenLandShift1     EQU     8       ; 2^-11 land for this specific loading text
LoadingScreenLandShift2     EQU     3       ; 2^-11 land for this specific loading text
LoadingScreenAcceleration   EQU     1      

*In-Game*
LivesLeftOffset             EQU     15
ScoreLeftOffset             EQU     480     ; Used in combination with LivesLeftOffset to prevent double loading
DoubleScoreLeftOffset       EQU     75
DoubleScoreBottomOffset     EQU     355
PaddleSpeedLeftOffset       EQU     75
PaddleSpeedBottomOffset     EQU     375
GameOverLeftOffset          EQU     40
GameOverBottomOffset        EQU     25
GameWinLeftOffset           EQU     200
PlayAgainLeftOffset         EQU     GameOverLeftOffset
PlayAgainBottomOffset       EQU     GameOverBottomOffset
GoBackLeftOffset            EQU     115

*Stack offset*
*Do not change, adds back the stack pointer from jumping to the subroutine and branches directly to end*
StackOffsetForEarlyQuit     EQU     4     

*Sets the width and height edge of the text to the approximate center of the screen
PrepWidthHeightUI
    move.w  #(BGWidthDisplay>>UIShiftAmount),d1
    move.w  #(BGHeightDisplay>>UIShiftAmount),d2
    rts
*Sets the width height edge of the text to the approximate center of the bottom black bar 
PrepWidthHeightInGameUI
    move.w  #0,d1
    move.w  #BGHeightDisplay,d2
    addi.w  #(BottomBlackBarOffset>>UIShiftAmount),d2
    rts

SetResolution
    move.l  #BGWidthDisplay,d1                          ; Move width into the last 16 bits for output resolution setting
    swap    d1                                          ; Move width to the first 16 bits for output resolution setting
    move.w  #(BGHeightDisplay+BottomBlackBarOffset),d1  ; Move height into the last 16 bits for output resolution setting
    move.l  #OutputResTrap, d0  
    trap    #15                                         ; Sets output resolution
    rts
    
*Sets up the second buffer so that the inval and drawing occurs on a separate screen from the player*
SetDoubleBuffering
    move.b  #DoubleBufferingVal,d1      ; Set drawing mode to enable double buffering
    move.l  #SetDrawingModeTrap,d0
    trap    #15
    rts
    
*Prepares the screen for the loading screen and following drawings*
ClearScreen
    move.b  #ClearScreenTrap,d0
    move.l  #ClearScreenMagicVal,d1
    trap    #15
    rts
    
*Used in conjunction with SetDoubleBuffering to show the screen that's being painted on behind-the-scenes*
SwapBuffer
	move.b  #RepaintFromBufferTrap,d0
    trap    #15
    rts
    
*Hub for resetting the game on start or when lives become 0 *
ResetGame
    clr.l   (Score)
    move.l  #MaxLives,(Lives)               ; Resets lives to the default
    move.l  #AmountOfBricks,BrickCounter    ; Resets brick counter for determining win condition
    jsr     ResetBallInformation            ; Resets ball location/velocity
    jsr     DrawBackgroundFull
    jsr     PlayMusic
    jsr     DrawUIText
    jsr     UpdateLED
    
    move.l  #DoubleLocationScreenX,d6       ; Prepare the width/height of the location of the powerup
    move.l  #DoubleLocationScreenY,d7
    jsr     DrawDoubleScore
    move.l  #SpeedLocationScreenX,d6        ; Prepare the width/height of the location of the powerup
    move.l  #SpeedLocationScreenY,d7
    jsr     DrawPaddleSpeed
    
    jsr     SwapBuffer                      ; Show the powerups and the background 
    jsr     DisablePowerups                 ; The player starts with no powerups enabled
    jsr     DrawBallInitial
    jsr     DrawPlayerInitial
    jsr     DrawBricks
    jsr     SwapBuffer
    rts
    
*Sets up the main-menu screen by showing multiple texts*
ShowStartingScreen
ShowTitleText
    lea     TitleText,a1 
    jsr     PrepWidthHeightUI
    subi.w  #TitleLeftOffset,d1
    subi.w  #TitleBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
ShowStartText
    lea     StartText,a1
    jsr     PrepWidthHeightUI
    subi.w  #StartLeftOffset,d1
    subi.w  #StartBottomOffset,d2
    trap    #15                         ; Trap code still what was set in ShowTitleText
ShowQuitText
    lea     QuitText,a1
    jsr     PrepWidthHeightUI
    subi.w  #QuitLeftOffset,d1
    subi.w  #QuitBottomOffset,d2
    trap    #15                         ; Trap code still what was set in ShowTitleText
    rts
    
*Contains a repeating loop that waits for player input on menu screen*
StartScreenInput
    clr.l   d1
    jsr     InputUISetup
    move.l  #UserInputTrap,d0           ; Check for a button press of either the spacebar/quit button
    trap    #15
    andi    #$FFFF,d1
    beq     StartScreenInput            ; No input, continue to wait for input
    cmpi.l  #$FF00,d1
    beq     ClearScreen                 ; Branching here also rts' back to main
    
*On quit, increment the stack pointer and branch to end -- rts would bring the code back to the game loop*
QuitEarlyInput
    add.l   #StackOffsetForEarlyQuit,sp
    jsr     ClearScreen
    jsr     ShowThanksText
    jsr     StopMusic
    bra     End
   
*Simply shows the thank you text when the player quits the game*
ShowThanksText
    lea     ThanksText,a1
    jsr     PrepWidthHeightUI
    subi.w  #ThanksLeftOffset,d1
    move.l  #DrawTextTrap,d0
    trap    #15
    rts
    
*Shows the instructions and information that the player will need to play the game
ShowLegend
ShowGoalText
    lea     GoalText,a1
    jsr     PrepWidthHeightUI
    subi.w  #GoalLeftOffset,d1
    subi.w  #GoalBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
*Prepares location variables for drawing the green brick*
ShowGreenBrick
    move.l  #GreenBrickXPosition,d6
    move.l  #GreenBrickYPosition,d7
    jsr     LoadGreen
*Prepares location variables for drawing the yellow brick*
ShowYellowBrick
    move.l  #YellowBrickXPosition,d6
    move.l  #YellowBrickYPosition,d7
    jsr     LoadYellow
ShowGreenText
    lea     GreenBrickText,a1
    jsr     PrepWidthHeightUI
    subi.w  #GreenBrickTextLeftOffset,d1
    subi.w  #GreenBrickTextBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
ShowYellowText
    lea     YellowBrickText,a1
    subi.w  #YellowBrickTextBottomOffset,d2
    trap    #15
ShowPowerupsText
    lea     PowerupsText,a1
    subi.w  #PowerupsTextLeftOffset,d1
    subi.w  #PowerupsTextBottomOffset,d2
    trap    #15
ShowDoubleScoreIcon
    move.l  #DoubleScoreXPosition,d6
    move.l  #DoubleScoreYPosition,d7
    jsr     DrawDoubleScore
ShowPaddleSpeedIcon
    move.l  #PaddleSpeedXPosition,d6
    move.l  #PaddleSpeedYPosition,d7
    jsr     DrawPaddleSpeed
ShowDoubleScoreInfoText
    lea     DoubleScoreInfoText,a1
    jsr     PrepWidthHeightUI
    subi.w  #DoubleScoreInfoLeftOffset,d1
    subi.w  #DoubleScoreInfoBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
ShowPaddleSpeedInfoText
    lea     PaddleSpeedInfoText,a1
    subi.w  #PaddleSpeedInfoBottomOffset,d2
    trap    #15  
    jsr     SwapBuffer                  ; After all this drawing, show to screen
    rts                                 ; Returns from the entire ShowLegend "function"

*Preps the screen for the loading text*
ShowLoadingScreen
    lea     LoadingText,a1 
    lea     LoadingTextPos,a2
    move.l  #LoadingScreenStartVelocity,(a2)
    jsr     PrepWidthHeightUI
    clr.l   d1                          ; Clear out to ensure that the x position is 0
    clr.l   d3
*Makes the loading text fly in from the left side of the screen using acceleration*
AccelerateLoadingText
    move.l  #DrawTextTrap,d0
    trap    #15
    add.l   d3,(a2)                             ; Adds the velocity to the position of the text
    move.l  (a2),d1                             ; Move the position into the space that allows for printing text
    lsr.l   #LoadingScreenlandShift1,d1         ; Shift the acceleration to the 2^0 land for printing
    lsr.l   #LoadingScreenlandShift2,d1
    jsr     SwapBuffer                          ; Show the loading text right before moving it
    addi.l  #LoadingScreenAcceleration,d3       ; Add the acceleration to the velocity value over time
    cmpi.l  #(LoadingTextStopLocation>>LoadingScreenLandShift1>>LoadingScreenLandShift2),d1 ; Shift by the land bits
    blt     AccelerateLoadingText               ; If the text is not at the stopping location, accelerate the text forward again
    clr.l   (a2)
    rts 
    
*Shows the lives and score text that precedes the LEDs*
DrawUIText
ShowLivesText
    lea     LivesText,a1
    jsr     PrepWidthHeightInGameUI
    addi.l  #LivesLeftOffset,d1
    move.l  #DrawTextTrap,d0
    trap    #15
ShowScoreText
    lea     ScoreText,a1
    addi.l  #ScoreLeftOffset,d1         ; Also attached to the LivesLeftOffset to prevent another prep
    trap    #15
    rts
    
*When the double score is collected, show indicator text*
ShowDoubleScoreText
    lea     DoubleScoreText,a1
    jsr     PrepWidthHeightUI
    subi.l  #DoubleScoreLeftOffset,d1
    addi.l  #DoubleScoreBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
    rts
    
*When the paddle speed increase is collected, show indicator text*
ShowPaddleSpeedText
    lea     PaddleSpeedText,a1
    jsr     PrepWidthHeightUI
    subi.l  #PaddleSpeedLeftOffset,d1
    addi.l  #PaddleSpeedBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
    rts
    
*When the player runs out of lives, show the following UI window*    
ShowGameOverUI
    lea     GameOverText,a1
    jsr     PrepWidthHeightUI
    subi.w  #GameOverLeftOffset,d1
    subi.w  #GameOverBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
ShowPlayAgainText
    lea     PlayAgainText,a1            ; Play again text
    jsr     PrepWidthHeightUI
    subi.w  #GoBackLeftOffset,d1
    trap    #15 
    jsr     PlayDefeatMusic             ; Stops main music and plays defeat sound
    rts
    
*When the player destroys all the bricks, show the following UI window
ShowGameWinUI
    lea     GameWinText,a1
    jsr     PrepWidthHeightUI
    subi.l  #GameWinLeftOffset,d1
    subi.l  #PlayAgainBottomOffset,d2
    move.l  #DrawTextTrap,d0
    trap    #15
    jsr     ShowPlayAgainText
    jsr     PlayVictoryMusic            ; Stops main music and plays victory sound
    rts

*Sets up the input for the final screen, either game win or lose*
EndGameInput
    clr.l   d1
EndGameLoop
    move.b  #SpaceBarInput,d1
    move.l  #UserInputTrap,d0           ; Check for a button press of the spacebar
    trap    #15
    andi    #$FF,d1
    beq     EndGameLoop
PlayAgainEnabled
    jsr     ClearScreen                 
    jsr     ShowLoadingScreen           ; If the player wants to play again, show the loading screen
    jsr     SwapBuffer
    jsr     ResetGame                   ; Must reset when a player wants to play again
    rts





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
