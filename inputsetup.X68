*-----------------------------------------------------------
* Title      : Epic Brick Break
* Written by : Tony Giumenta
* Date       : 09/30/20
* Description: Has all the handling for the player movement.
*              Allows the player to move both left and right, and checked for the collision with the left
*              and right side of the screen.
*-----------------------------------------------------------
*Character movement inputs*
KeyLeftInput            EQU     $25
KeyRightInput           EQU     $27

*UI-only inputs*
SpaceBarInput           EQU     $20
QuitButtonInput         EQU     $51

ShiftInputAmount        EQU     8   ; Use this to shift over the space for multi-word byte input

*Gets both input keys for checking movement*
InputMovementSetup
    move.b  #KeyRightInput,d1
    lsl.l   #ShiftInputAmount,d1
    move.b  #KeyLeftInput,d1
    rts
    
*Gets input for the introductory UI scene*
InputUISetup
    move.b  #SpaceBarInput,d1
    lsl.l   #8,d1
    move.b  #QuitButtonInput,d1
    rts

*The starting point for checking input for the player*
PlayerInput
    jsr     InputMovementSetup
    move.l  #UserInputTrap,d0       ; Check for a button press of either the left/right key
    trap    #15
    andi.l  #$FFFF,d1              
    beq     noInput                 ; If no keys are pressed, mark the boolean and return out without drawing
    
    lea     CharXCoordinateLeftCurr,a2
    *Check which key was actually pressed and branch to the specific method for the movement*
    cmpi.l  #$FF,d1
    beq     LeftInput               ; Branch to left input, otherwise fall into RightInput
RightInput
    jsr     GetVelocity             ; Prepares paddle velocity prior to adding it directly
    add.l   d0,(a2)
    move.l  #BGWidthDisplay, d0
    move.l  (a2),d1
    lsr.l   #LandShiftAmount,d1     ; Right shift the value so it is in 2^0
    addi.l  #PaddleWidth,d1         ; Add paddle width to the left side
    cmp.l   d0,d1
    bge     SetRightCollided
    rts
SetRightCollided
    move.l  #(BGWidthDisplay-PaddleWidth),d1    ; Data-driven setting of the paddle's left position
    lsl.l   #LandShiftAmount,d1                 ; Left shift the value so it is in the correct land  
    move.l  d1,(a2)                             ; Move that value into the left position of the paddle
    rts
LeftInput
    jsr     GetVelocity             ; Prepares paddle velocity prior to adding it directly
    sub.l   d0,(a2)
    ble     SetLeftCollided         ; If the paddle collides with the left of the window, set the left position to 0
    rts 
SetLeftCollided
    clr.l   (a2)                    ; Clear the x-position just in case the paddle went past the edge
    rts
    
*Prepares a local space to hold the velocity to add to the paddle
GetVelocity
    move.l  #PaddleVelocity,d0          ; Gets the actual paddle velocity
    move.b  (PaddleSpeedCollected),d1   
    bne     AddPaddleVelocity
    rts
AddPaddleVelocity
    addi.l  #VelocityToAdd,d0
    rts
   
*Indicates the player did not input left or right, nothing is done
noInput
    move.b  #1,HaveHadNoInput
    rts













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
