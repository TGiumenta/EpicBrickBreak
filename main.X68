*---------------------------------------------------------------------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta
* Date       : 09/29/20
* Description: The main hub for handling all of the game's files and majority of its equates.
*              Main sets up the resolution, sounds, and sets up the starting UI for the game.
*              Main also hosts the game loop which just calls the respective "functions" over & over until
*              completion like inval'ing/drawing the player, updating/drawing the ball, and updating the LED displays.
*---------------------------------------------------------------------------------------------------------------------
    ORG $1000
bitmapdrawing   INCLUDE "bitmapdrawgame.x68"
inputhandler    INCLUDE "inputsetup.x68"
invalhandler    INCLUDE "invaldrawing.x68"
ballhandler     INCLUDE "ball.x68"
brickhandler    INCLUDE "bricks.x68"
randomnum       INCLUDE "randomNum.x68"
uihandler       INCLUDE "startendui.x68"
livesandscore   INCLUDE "livesandscore.x68"
ledsegment      INCLUDE "ledsegment.x68"
poweruphandler  INCLUDE "powerups.x68"
soundhandler    INCLUDE "musicandsound.x68"

*File offsets for bmp file format*
WidthFileOffset         EQU     $12
HeightFileOffset        EQU     $16

*Fixed Point Land*
LandShiftAmount         EQU     3           ; Shift by the land shift to get the correct pixel location

*Arguments for player drawing*
PaddleWidth             EQU     64          ; Width
PaddleHeight            EQU     8           ; Height
PlayerStartingPosX      EQU     2276        ; Character initial X position
LocationScreenY         EQU     613         ; Initial offset for height drawing location
PaddleVelocity          EQU     37          ; Static character velocity in 2^-3 land
VelocityToAdd           EQU     13          ; Added velocity after powerup collected
PaddleColor             EQU     $00FFF200   ; Color of the collider for the paddle
BlackColor              EQU     $00000000   ; Value to swap to after filling in rectangle drawing

*Default corner drawing, always draw the image starting from the top-left*
*This eliminates multiple equates that are using the same values
DefaultCornerX          EQU     0
DefaultCornerY          EQU     0

*Arguments for game background drawing*
BGWidthDisplay          EQU     640         ; Width
BGHeightDisplay         EQU     700         ; Height
BGLocationScreenX       EQU     0           ; Initial offset for width drawing location
BGLocationScreenY       EQU     0           ; Initial offset for height drawing location
BottomBlackBarOffset    EQU     50          ; Offset to the height to have a black bar at the bottom for score/time

*Ball information*
BallWidthDisplay        EQU     12          ; Width
BallHeightDisplay       EQU     12          ; Height
BallLocationScreenX     EQU     2496        ; Initial offset for width drawing location (in 2^-3 land)
BallLocationScreenY     EQU     2740        ; Initial offset for height drawing location (in 2^-3 land)
BallStartingVelocityX   EQU     1
BallStartingVelocityY   EQU     10
BallVelocityYRef        EQU     56          ; Reference to the magnitude of the velocity 
AmountOfBalls           EQU     8           ; Do not change -- helps the randomization for balls

*Arguments for brick drawing*
BrickWidthDisplay       EQU     40          ; Width
BrickHeightDisplay      EQU     20          ; Height
StartingXPosition       EQU     40          ; First x-position to print a brick
StartingYPosition       EQU     28          ; First y-position to print a brick
; Locations are set within DrawBricks

*Brick Information*
InnerGreenBrickColor    EQU     $0044FF00   ; Used for collision with ball
InnerYellowBrickColor   EQU     $0000FFF6   ; Used for collision with ball
GreenBrickScore         EQU     1
YellowBrickScore        EQU     10
BrickScoreShift         EQU     1           ; Shift by this amount when doubling/reducing the score

*Powerups* (All are 30x30 sprites)
PowerupWidthDisplay     EQU     30
PowerupHeightDisplay    EQU     30  
*2x Score*
DoubleLocationScreenX   EQU     85   
DoubleLocationScreenY   EQU     25       
DoubleColor             EQU     $000000FF   ; Color of the collider for the powerup
*PaddleSpeedIncrease*
SpeedLocationScreenX    EQU     BGWidthDisplay-DoubleLocationScreenX-PowerupWidthDisplay   
SpeedLocationScreenY    EQU     DoubleLocationScreenY   ; Align this powerup with the DoubleScore one       
SpeedColor              EQU     $00A41E9B               ; Color of the collider for the powerup

*ASCII Representations For String Printing*
CR                      EQU     $0D         ; ASCII for Carriage Return
LF                      EQU     $0A         ; ASCII for Line Feed

*Character Default Statistics*
MaxLives                EQU     3
StartingScore           EQU     0

*Sound Reference Values*
MainMenu                EQU     0
BrickDestroy            EQU     1
PowerupCollect          EQU     2

*Trap Code References*
GetTimeTrap             EQU     8
ClearScreenTrap         EQU     11
ClearScreenMagicVal     EQU     $FF00
DoubleBufferingVal      EQU     17          ; Value to set d1.b to to enable double buffering (with Trap 95)
UserInputTrap           EQU     19
DelayTrap               EQU     23
DelayTime               EQU     200         ; Amount of time the player must wait after losing a life
OutputResTrap           EQU     33
LoadWAVNonDirectTrap    EQU     71          ; Load the music file into the sound memory
LoadWAVDirectTrap       EQU     74          ; Load the music file into DirectX sound memory
PlayWAVDirectTrap       EQU     75          ; Plays sounds loaded with above trap code
StandardPlayerTrap      EQU     76          ; Plays sounds loaded with trap code 71
PenColorTrap            EQU     80
FillColorTrap           EQU     81
DrawPixelTrap           EQU     82
GetPixelColorTrap       EQU     83
DrawLineTrap            EQU     84
DrawRectangleTrap       EQU     87
DrawCircleTrap          EQU     88
SetDrawingModeTrap      EQU     92
RepaintFromBufferTrap   EQU     94  
DrawTextTrap            EQU     95  
    
START:
    jsr     SeedRandomNumber                ; Seed the random number only once at the start and use it later
    jsr     SetResolution
    jsr     LoadSounds                      ; Loads WAVs into sound memory
    jsr     SetDoubleBuffering
TitleAndLoadingScreens
    jsr     ShowStartingScreen
    jsr     ShowLegend
    jsr     StartScreenInput
    jsr     ShowLoadingScreen
    
*Set the game up for the game loop, initializing goes here*
GameInitialSetup
    jsr     ResetGame           ; UI, LEDs, Powerups, Initial ball/player and brick layout

GameLoop
    jsr     InvalPlayer
    jsr     PlayerInput
    jsr     DrawPlayer
    
    jsr     UpdateBall          ; Inval ball, update ball's position, check for collisions
    jsr     DrawBall
    jsr     UpdateLED           ; Updates both LEDs
    
    jsr     SwapBuffer
    bra     GameLoop

End
    SIMHALT                     ; Halt program
    
*Labels*
*BMP Files that must be drawn*
Background                  INCBIN  "Bitmaps\Background.bmp"
GreenBrick                  INCBIN  "Bitmaps\GreenBrick.bmp"
YellowBrick                 INCBIN  "Bitmaps\YellowBrick.bmp"
DoublePowerup               INCBIN  "Bitmaps\Double.bmp"
PaddleSpeed                 INCBIN  "Bitmaps\PaddleSpeed.bmp"
Ball1                       INCBIN  "Bitmaps\Ball1.bmp"
Ball2                       INCBIN  "Bitmaps\Ball2.bmp"
Ball3                       INCBIN  "Bitmaps\Ball3.bmp"
Ball4                       INCBIN  "Bitmaps\Ball4.bmp"
Ball5                       INCBIN  "Bitmaps\Ball5.bmp"
Ball6                       INCBIN  "Bitmaps\Ball6.bmp"
Ball7                       INCBIN  "Bitmaps\Ball7.bmp"
Ball8                       INCBIN  "Bitmaps\Ball8.bmp"
Balls                       dc.l    Ball1,Ball2,Ball3,Ball4,Ball5,Ball6,Ball7,Ball8
RandomValue                 ds.l    1                       ; Location to hold random number from generator
RandomlyChosenBall          dc.l    0                       ; Holds address to the randomly chosen ball of 8
*WAV Files*
MainMusic                   dc.b    'WAVs\music.wav',0
PaddleWallSound             dc.b    'WAVs\bonk.wav',0
ExplodeBrickSound           dc.b    'WAVs\explode.wav',0
PowerupSound                dc.b    'WAVs\powerup.wav',0
GameWinMusic                dc.b    'WAVs\gamewin.wav',0
GameLoseMusic               dc.b    'WAVs\gamelose.wav',0
*UI Text*
TitleText                   dc.b    'Welcome to Epic Brick Break!',0
StartText                   dc.b    'Press Spacebar to start!',0
QuitText                    dc.b    'Press Q to quit the game.',0
GoalText                    dc.b    'Your goal is to get the most amount of points without losing all your lives!',0
GreenBrickText              dc.b    '= 1 point',0
YellowBrickText             dc.b    '= 10 points',0
DoubleScoreInfoText         dc.b    '= Doubles point value of bricks',0
PaddleSpeedInfoText         dc.b    '= Increases your paddle speed',0
PowerupsText                dc.b    'Collect the following powerups to help you score more points!',0
ThanksText                  dc.b    'Thanks for playing!',0
GameOverText                dc.b    'Game Over!',0
GameWinText                 dc.b    'Congratulations! You have destroyed all the bricks!',0
PlayAgainText               dc.b    'Press Spacebar to play again!',0
LoadingText                 dc.b    'Loading... ',0 
LoadingTextPos              dc.l    0                       ; 0   starting * 8 (2^-3 land) = 0
LivesText                   dc.b    'Lives:',0
ScoreText                   dc.b    'Score:',0 
DoubleScoreText             dc.b    '2x Score Activated!',0   
PaddleSpeedText             dc.b    'Extra Paddle Speed!',0   
*Position information about player/ball/bricks*
HaveHadNoInput              dc.b    1                       ; Boolean to indicate when the player inputs for character movement
CharXCoordinateLeftCurr     dc.l    PlayerStartingPosX      ; Start the character near the center of the ball
BallLeftPosCurr             dc.l    BallLocationScreenX     ; Ball's left position
BallTopPosCurr              dc.l    BallLocationScreenY     ; Ball's top position
BallVelocityX               dc.l    BallStartingVelocityX   ; Dynamic character velocity in 2^-3 land
BallVelocityY               dc.l    BallStartingVelocityY   ; Dynamic character velocity in 2^-3 land
Score                       dc.l    StartingScore           
BrickCounter                dc.l    AmountOfBricks          ; Counts how many bricks were destroyed -- used for game win
Lives                       dc.l    MaxLives                
BrickArray                  dcb.l   AmountOfBricks,$0       
DoubleScoreCollected        dc.b    0                       ; Boolean to determine if the 2x score powerup has been collected
PaddleSpeedCollected        dc.b    0                       ; Boolean to determine if the extra paddle speed powerup has been collected
BallVelocityPaddleTable     dc.l    40,40,40,40,38,38,38,36,36,34,32,30,28,26,24,24,22,22,22,20,16,12,10,10,8,8,6,6,4,4,4,4
                            dc.l    -4,-4,-4,-4,-6,-6,-8,-8,-10,-10,-12,-16,-20,-22,-22,-22,-22,-24,-26,-28,-30
                            dc.l    -32,-34,-36,-36,-38,-38,-38,-40,-40,-40,-40                             
    END    START            ; Last line of source





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
