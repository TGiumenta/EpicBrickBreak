*-----------------------------------------------------------
* Program    : 3
* Written by : Tony Giumenta
* Date       : 09/21/20
* Description: A subroutine which draws a bmp file to the console 
*              window given parameters outlined in the main.x68 pixel-by-pixel
*              This subroutine assumes that the file is saved using 32-bit color depth.
*
* The arguments and descriptions are listed as follows:
* CornerDisplayX and CornerDisplayY -- The ordered pair that indicates the top-left corner of the image.
*                                      This ordered pair is relative to the overall dimensions.
* WidthDisplay -- How many pixels wide to print. This is not relative to the overall dimensions.
* HeightDisplay -- How many pixels high to print. This is not relative to the overall dimensions.
* LocationScreenX and LocationScreenY -- The ordered pair that indicates the offset from the top-left corner
*                                        of the console window.
*-----------------------------------------------------------
RotateSwapVal       EQU     8       ; Rotation amount for byteswapping values and for fixing padding
PixelToByteVal      EQU     2       ; Shift amount to convert from pixels to bytes
PixelOffset         EQU     $0A     ; Location of offset for pixel array

*Stack offset reference values*
CornerDisplayXRef   EQU     $8  
CornerDisplayYRef   EQU     $C  
WidthDisplayRef     EQU     $10 
WidthFileOffsetRef  EQU     $14 
HeightFileOffsetRef EQU     $18 
HeightDisplayRef    EQU     $1C 
LocationScreenXRef  EQU     $20 
LocationScreenYRef  EQU     $24 

*Stack offset reference values for locals*
AmountOfSpace       EQU     8           ; Space amount needed for locals
WidthCoordOffset    EQU     $0      
HeightCoordOffset   EQU     $4      

TransparentColor    EQU     $00F200FF   ; If the pen color is this color, don't draw it, act as transparent

*A subroutine that byteswaps values -- mainly used for interpreting values in the BMP*
ByteSwap
    ror.w   #RotateSwapVal, d0  ; Swapping the first word's byte
    swap    d0                  ; Swapping both words in the long word
    ror.w   #RotateSwapVal, d0  ; Swapping the second word's byte
    rts

*Start Subroutine by allocating space for future local variables and byteswapping values*
DrawBitmap
    movem.l d0-d7/a0-a6, -(sp) ; Save all original variables onto the stack
                               ; This allows the use of d0-d7 as temporary spaces now
    sub.l   #AmountOfSpace,sp  ; Make room for two local variables (coordinates) and set stack pointer

*Byte Swaps the start of the pixel array*
ByteSwapPixelArray    
    move.l  PixelOffset(a0),d0
    jsr     ByteSwap           ; ByteSwap the pixel offset
    lea     (a0,d0),a4         ; Loads beginning of the pixel array
    
*Byte Swaps the width that was native to the .bmp file to be useable for drawing*
ByteSwapWidth
    move.w  d3,d0       ; Move width into temporary storage
    jsr     ByteSwap
    swap    d0          ; Final swap since the value is only a word and not a long
    move.w  d0,d3       ; Move the swapped value back into the width register    
   
*Byte Swaps the height that was native to the .bmp file to be useable for drawing*
ByteSwapHeight
    move.w  d4,d0       ; Move width into temporary storage
    jsr     ByteSwap
    swap    d0          ; Final swap since the value is only a word and not a long
    move.w  d0,d4       ; Move the swapped value back into the width register
    
*Gets information about number of rows to skip, as well as setting height coordinate/draw-counters*
HeightShiftUp   
    move.l  d4,d5                       ; Move height into temporary space
    sub.l   HeightDisplayRef(sp),d5     ; Get the number of rows to skip from the bottom of the image
    sub.l   CornerDisplayYRef(sp),d5    ; Get the number of rows to skip from the top (and bottom)
    move.l  HeightDisplayRef(sp),d6     ; Stores the amount of rows to start drawing considering the Y offset
                                        ; Stores the height draw-counter
    move.l  d6,HeightCoordOffset(sp)
    
*Skips the amount of rows (in bytes) based on the height offset*
RowStartByteSkip
    move.l  d3,d7                       ; Move the full width of the image (in pixels) in a temporary space
    mulu.w  d5,d7                       ; Multiply this width by the number of rows needed to skip
    asl.l   #PixelToByteVal,d7 
    adda.l  d7,a4                       ; Skip to start initially reading pixels at correct height offset
    
*Stores the amount of bytes to skip from both left and right of each row*
WidthByteSkip
    move.l  d3,d5                       ; Reuse temporary space to store width
    sub.l   WidthDisplayRef(sp),d5      ; Gets how many "columns" to skip based on height
    sub.l   CornerDisplayXRef(sp),d5    ; Gets how many "columns" to skip based on offset and height
    move.l  WidthDisplayRef(sp),d3      ; Number of pixels to print per row
    
    move.l  d5,d7                       ; Reuse temporary space to get the number of pixels to skip at end of row printing
    asl.l   #PixelToByteVal,d7
    
    move.l  CornerDisplayXRef(sp),d4    ; Use an unused space to get number of pixels to skip from left of image
    asl.l   #PixelToByteVal,d4
    
*Resets width counters, coordinates and shift address offset to account for offset*
CounterAndCoordinateSetup
    cmp.l   #0,HeightCoordOffset(sp)    ; If height coordinate is less than or equal to 0, done with subroutine
    ble     Done
    clr.l   WidthCoordOffset(sp)        ; Reset width coordinate/counter
    adda.l  d4,a4                       ; Start reading pixels from correct offset
    
*Main drawing loop which sets pen colors and drawing location*
DrawingLoop
    move.l  (a4)+,d1                    ; Move pen color into d1 and advance address to look at next pixel
    ror.l   #RotateSwapVal,d1           ; Rotate to fix padding and converts the RGB->BGR
    
    move.w  #PenColorTrap,d0
    trap    #15                         ; Sets pen color
    cmpi.l  #TransparentColor,d1        ; If the color is equal to the transparent color, don't draw the pixel
    beq     SetWidthInformation

*Conditionally draws the pixel*
DrawPixel
    move.l  WidthCoordOffset(sp),d1     ; Move width coordinate into proper location for drawing
    add.l   LocationScreenXRef(sp),d1   ; Shift width coordinate based on offset
    move.l  HeightCoordOffset(sp),d2    ; Move height coordinate into proper location for drawing
    add.l   LocationScreenYRef(sp),d2   ; Shift height coordinate based on offset
    move.w  #DrawPixelTrap,d0      
    trap    #15                         ; Draws pixel

*Increments counters and checks if the last pixel in the row has been drawn*
SetWidthInformation
    addi.l  #1,WidthCoordOffset(sp)     ; Increment width coordinate/counter
    cmp.l   WidthCoordOffset(sp),d3     ; If width counter is less than width of the image, keep drawing
    bgt     DrawingLoop

*Shift address and set height coordinate to ensure pixel drawing occurs at correct location*
AddressAndStackTidying
    adda.w  d7,a4                       ; Shift over necessary bytes to compensate pixels on the right, these should only ever be a word or smaller
    subi.l  #1,HeightCoordOffset(sp)    ; Decrement height coordinate
    bra     CounterAndCoordinateSetup
    
*Fixing Stack and returning to main*
Done
    add.l   #AmountOfSpace,sp           ; Set stack pointer back to return properly
    movem.l (sp)+,d0-d7/a0-a6           ; Reset original registers and fix stack pointer
    rts                                 ; Return from subroutine back to main












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
