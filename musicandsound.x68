*----------------------------------------------------------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta 
* Date       : 10/08/20
* Description: A handler which contains the logic for loading all the sounds into sound memory and playing
*              music, and sfx when prompted. Music is played at game start and loops until completion, and
*              sfx are manually called when needed.
*----------------------------------------------------------------------------------------------------------
*All Registers*
AllRegisters                    REG     D0-D7/A0-A6

PlayOnceValue                   EQU     0
LoopingValue                    EQU     1       ; Used in Trap 76 for looping a sound
StoppingValue                   EQU     2       ; Used in Trap 76 for stopping a sound

MainPosition                    EQU     0
PaddleWallSoundPosition         EQU     1
ExplodeBrickSoundPosition       EQU     2
PowerupSoundPosition            EQU     3
GameWinPosition                 EQU     4
GameLosePosition                EQU     5

LoadSounds
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
                                        
    lea     PaddleWallSound,a1
    move.l  #LoadWAVDirectTrap,d0
    move.b  #PaddleWallSoundPosition,d1
    trap    #15
    
    lea     ExplodeBrickSound,a1
    move.l  #LoadWAVDirectTrap,d0      ; Need to move this in again because of the Trap's post-condition
    move.b  #ExplodeBrickSoundPosition,d1
    trap    #15
    
    lea     PowerupSound,a1
    move.l  #LoadWAVDirectTrap,d0      ; Need to move this in again because of the Trap's post-condition
    move.b  #PowerupSoundPosition,d1
    trap    #15
    
    lea     MainMusic,a1
    move.l  #LoadWAVNonDirectTrap,d0   ; Use Standard Controller for music so it can be looped and not interrupted by SFX       
    move.b  #MainPosition,d1
    trap    #15
    
    lea     GameWinMusic,a1
    move.l  #LoadWAVNonDirectTrap,d0   ; Use Standard Controller for music so it can be looped and not interrupted by SFX       
    move.b  #GameWinPosition,d1
    trap    #15
    
    lea     GameLoseMusic,a1
    move.l  #LoadWAVNonDirectTrap,d0   ; Use Standard Controller for music so it can be looped and not interrupted by SFX       
    move.b  #GameLosePosition,d1
    trap    #15
    
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer 
    rts
    
*Plays the music at the start of the game and loops until closing*
PlayMusic
    jsr     StopGameEndMusic
    move.l  #StandardPlayerTrap,d0
    move.l  #MainPosition,d1
    move.l  #LoopingValue,d2
    trap    #15
    rts
   
*SFX played when the ball hits the paddle or wall*
PlayPaddleWall
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    lea     PaddleWallSound,a1
    move.b  #PaddleWallSoundPosition,d1
    move.l  #PlayWAVDirectTrap,d0
    trap    #15    
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts

*SFX played when the bricks are destroyed*
PlayBrickExplode
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    lea     ExplodeBrickSound,a1
    move.b  #ExplodeBrickSoundPosition,d1
    move.l  #PlayWAVDirectTrap,d0
    trap    #15    
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts
    
*SFX played when a powerup is collected*
PlayPowerup
    movem.l AllRegisters,-(sp)          ; Save all original variables onto the stack
                                        ; This allows the use of d0-d7 as temporary spaces now
    lea     PowerupSound,a1
    move.b  #PowerupSoundPosition,d1
    move.l  #PlayWAVDirectTrap,d0
    trap    #15    
    
    movem.l (sp)+,AllRegisters          ; Reset original registers and fix stack pointer
    rts

*Stops the music -- called when the end game music is meant to play*
StopMusic
    move.l  #StandardPlayerTrap,d0
    move.l  #MainPosition,d1
    move.l  #StoppingValue,d2
    trap    #15
    rts
    
*On game win, play this sound*
PlayVictoryMusic
    jsr     StopMusic
    move.l  #StandardPlayerTrap,d0
    move.l  #GameWinPosition,d1
    move.l  #PlayOnceValue,d2
    trap    #15
    rts

*On game lose (lost all lives), play this sound*
PlayDefeatMusic
    jsr     StopMusic
    move.l  #StandardPlayerTrap,d0
    move.l  #GameLosePosition,d1
    move.l  #PlayOnceValue,d2
    trap    #15
    rts
    
*Stops both the winning and losing tracks when the game music starts*
StopGameEndMusic
    move.l  #StandardPlayerTrap,d0
    move.l  #GameWinPosition,d1
    move.l  #StoppingValue,d2
    trap    #15
    move.l  #GameLosePosition,d1
    move.l  #StandardPlayerTrap,d0
    trap    #15
    rts
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
