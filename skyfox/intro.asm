	processor 6502
	org $0801

	; Skyfox IDE64 Fix Intro Jan 3 2011   
  ; Schema/AIC   leif@schemafactor.com

BASIC ; 6 sys 2064
	dc.b $0c,$08,$06,$00,$9e,$20,$32,$30
	dc.b $36,$34,$00,$00,$00,$00,$00

START
  lda #$00
  sta $d020
  sta $d021
  
  jsr CLEARSCREEN
  jsr INTRO
  jsr SHOWPIC
  jsr BLANKSCREEN
  jmp LINK
  

; Note - the font cannot go between $1000 and $2000 as the VIC-II always 
; sees the Character ROM there.  So we need to put the font here instead. 

  org $0C00   ; Only using the "top half" of the font anyway.
FONT
  incbin "netracer.font.bin"   ; No Load Address!


; My Intro ------------------------------------------------------------------

  org $1000
INTRO
  
  ; Disable RUN-STOP/RESTORE
  lda #$c1
  sta $0319
  
  ; Disable shifting character sets
  lda #$80
  sta $0291
  
  ; Set VIC to Bank 0, because the font is at $0800.
  lda $DD00
  and #%11111100
  ora #%00000011
  sta $DD00

  ; Point the charset to $0800  (Bank 0)
  lda $d018
  and #%11110001
  ora #%00000010
  sta $d018
  
  ; Show the text
  ldx #$00
  
text1
  lda SKYFOX,x
  beq colors
  adc #$80     ; Because we're only using the top half of the font
  sta $05c9,x
  lda #$02
  sta $d9c9,x
  inx
  bne text1
  
  ;Set up colors

numcolors = 120   ; Decimal

colors 
  ldx #00
colorsloop
  lda FIXEDCOLORS,x
  sta $d9e0,x
  inx 
  cpx #numcolors
  bne colorsloop
  
  ldx #$00  
text2
  lda FIXEDBY,x
  beq effect
  adc #$80     ; Because we're only using the top half of the font
  sta $0608,x
  inx
  bne text2

  ; Scroll the colors
effect

count = $FE
  ldy #numcolors   ; Decimal
  sty count


effectloop
  ldx #numcolors   ; Note decimal

scroll
  lda $d9df,x
  sta $d9e0,x
  dex
  bne scroll
  
  jsr TENTHSECOND
  
  dec count
  bne effectloop
  rts

SKYFOX
  byte $13,$0b,$19,$06,$0f,$18,0 ; "skyfox"
  
FIXEDBY
  byte $08,$04,$05,$36,$34,$20,$06,$09,$18,$20,$20,$02,$19,$20,$13,$03,$08
  byte $05,$0d,$01,$2f,$01,$09,$03,$20,$26,$20,$13,$0f,$03,$09,$2f,$13
  byte $09,$0e,$07,$15,$0c,$01,$12,0
  ; "ide64 fix  by schema/aic & soci/singular"

FIXEDCOLORS
  byte $00,$06,$06,$0e,$0e,$03,$03,$01,$01,$03,$03,$0e,$0e,$06,$06  
  ds.b 25,0
  ds.b 80,0
  
  
; ==============================================================
; One-tenth second delay
; ==============================================================

TENTHSECOND
    ldy #3   ; was 6   ; - NTSC   use #5 for PAL
tlp:
    lda #$f8
tlp2:
    cmp $d012    ; reached the line
    bne tlp2
tlp3:
    cmp $d012    ; past the line
    beq tlp3
    
    ; Count down
    dey
    bne tlp

TENTHSECOND_x    
    rts
   
  
; Show the Picture ------------------------------------------------------------------

SHOWPIC
       lda #$3b ;<--- Turn on bitmap mode
       ldx #$18 ;<--- Turn on all bitmap characters     
       ldy #$03
       sta $d011
       stx $d018
       stx $d016
       sty $dd00
       ldx #$00
setpic lda VIDEORAM,x
       sta $0400,x
       lda VIDEORAM+$100,x
       sta $0500,x
       lda VIDEORAM+$200,x
       sta $0600,x
       lda VIDEORAM+$2e8,x
       sta $06e8,x
       lda COLORRAM,x
       sta $d800,x
       lda COLORRAM+$100,x
       sta $d900,x
       lda COLORRAM+$200,x
       sta $da00,x
       lda COLORRAM+$2e8,x
       sta $dae8,x
       inx
       bne setpic
       
hold   lda $dc01
       cmp #$ef
       bne hold

       rts

; Blank the screen --------------------------------------------------------

BLANKSCREEN
   lda $d011
   and #%11101111
   sta $d011
   rts

; Clear the screen --------------------------------------------------------  

CLEARSCREEN 
   ldx #$00
   lda #($20+$80)   ; Reverse-space, because of the half charset
clearloop
   sta $0400,x
   sta $0500,x
   sta $0600,x
   sta $06e8,x   ; to get to $07e7
   dex
   bne clearloop
   rts 
   

; Relocate the game to original memory location ---------------------------

codedest = $0180

LINK
      sei
      lda #$34
      sta $01
      ldx #$30

loopa
      lda code,x
      sta codedest,x
      dex
      bpl loopa
      ldx #$00;  was inx
      
      jmp codedest

code
mod1
      lda ORIGIN,x

mod2
      sta $0801,x
      inc codedest+$01 ; mod1+$01
      bne skip1
      inc codedest+$02 ; mod1+$01
      

skip1
      inc codedest+$04 ; mod2+$01
      bne skip2
      inc codedest+$05 ; mod2+$02

skip2
      lda codedest+$02
      bne mod1
      lda #$37
      sta $01
      cli

      jmp $080B    ; SYS 2059  
  

; Binary Include files here ------------------------------------------------------

  org $1400
VIDEORAM
  incbin "skyfox-videoram.bin"

  org $1800
COLORRAM
  incbin "skyfox-colourram.bin"

  org $2000
BITMAP
  incbin "skyfox-bitmap.bin"
  
; Main Game Image Here -----------------------------------------------------------

  org $4001
 
ORIGIN 
  incbin "skyfox-ide64.bin"  ; No Load address!

; Should end at $B710
