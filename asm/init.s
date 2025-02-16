*
* Init Segment, Display logo while loading is happening
*
	rel
	dsk init.l

	ext LZ4_Unpack

	mx %00

;
; I'm pretty sure I don't have an assigned DP at this point
; As this is called in middle of loading the application
;
init ent

	php
	phb
	rep #$30

	jsr FadeToBorder

	jsr vsync

	; Zero out the SCBs using overlapping mem copy
	; Setting SHR into 320 mode
	lda #0
	sta >$e19d00
	lda #198
	ldx #$9d00
	ldy #$9d02
	mvn $E1,$E1

	phk
	plb

	; unpack just the pixels of the image
	pea ^logos_lz4
	pea logos_lz4
	pea ^$e12000
	pea $e12000
	jsl LZ4_Unpack

	Jsr FadeToLogoColors

	plb	; restore bank
	plp ; restore P
	rtl

********************************************************************************
FadeToBorderLong ent
	mx %00
	php
	phb

	jsr FadeToBorder

	plb
	plp
	rtl

********************************************************************************
*
* Load up source, and target colors, then call the fader
*
********************************************************************************
FadeToLogoColors mx %00

	; Source and Target Both are set to Border Color Right now, because
	; of the fade in

	lda #31	; 32 bytes copy
	ldx #logo_colors
	ldy #TargetColors
	mvn ^logo_colors,^TargetColors

	lda #16		; 16 color fade

	bra QuickFade


********************************************************************************
*
* Load up source, and target colors, then call the fader
*
********************************************************************************
FadeToBorder mx %00

	; Load up the SourceColors

	lda #511	      ; 512 Bytes copy
	ldx #$9e00		  ; Source $E19E00
	ldy #SourceColors ; Target our target buffer
	mvn ^$E19E00,^SourceColors  ; From bank E1 to this bank

	phk 			  ; restore bank
	plb

	; Load up the Target Colors

	lda >$E0C034 ; Border Color Register
	and #$F
	asl
	tax
	lda |border_colors,x
	sta |logo_colors		; Color Index 0 of the Logo is the background

	sta |TargetColors

	lda #509  ; 510 bytes copy, repeat the border color over and over
	ldx #TargetColors
	ldy #TargetColors+2
	mvn ^TargetColors,^TargetColors

	; B is set right after this move
	; drop through to the fade

	lda #256 	 ; pass in the number of colors to fade

QuickFade mx %00

fadeCount equ 1
numColors equ 3

	pha			; 1,s becomes the number of colors
	pea #15	    ; Fade counting loop

; 1.  Fill out the step tables

; for 16 steps
;   2.  Apply Step
;   3.  Sync
;   4.  Copy palette
;

;-------------------------------------------------------------------------------
;
; Fill out the step tables
;
;-------------------------------------------------------------------------------

	ldx #0   ; start at color 0

]step_loop

;
; Red Step
;
	lda |SourceColors,x
	and #$0F00 			; 8.8 format
	sta |Red,x  		; current Red
	lsr 			    ; pre-divide by 16
	lsr
	lsr
	lsr
	sta |RedStep,x

	lda |TargetColors,x
	and #$0F00			; 8.8 format
	lsr					; pre-divide by 16
	lsr
	lsr
	lsr
	sec
	sbc |RedStep,x		; difference

	; no sign extension needed, because pre-divided

	sta |RedStep,x		; save result

;
; Green Step
;
	lda |SourceColors,x
	and #$00F0  	   	; get into 8.8 format / pre divided by 16
	sta |GreenStep,x
	asl
	asl
	asl
	asl
	sta |Green,x		; current green 8.8

	lda |TargetColors,x
	and #$00F0  		; get into 8.8 format / pre divided by 16
	sec
	sbc |GreenStep,x	; difference

	; pre-shifted, no sign extension needed

	sta |GreenStep,x	; save result


;
; Blue Step
;
	lda |SourceColors,x
	and #$000F
	xba
	sta |Blue,x			; current blue 8.8 format
	lsr					; pre-divide by 16
	lsr
	lsr
	lsr
	sta |BlueStep,x

	lda |TargetColors,x
	and #$000F
	asl 		  		; 8.8 pre-divide by 16
	asl
	asl
	asl
	sec
	sbc |BlueStep,x	; difference

	; pre-shifted, no sign extension needed

	sta |BlueStep,x	; save result

	inx				; inc index counter
	inx

	txa
	lsr
	cmp numColors,s  ; are we done?
	bcc ]step_loop	 ; branch less than loop

;-------------------------------------------------------------------------------

]fade_loop

; Apply Step

	ldx #0
]apply_loop

	clc
	lda |Red,x     		; Current 8.8 red
	adc |RedStep,x 		; Add Fractional Step
	sta |Red,x			; Save Result
	clc
	lda |Green,x	    ; Current 8.8 green
	adc |GreenStep,x	; Add Fractional Step
	sta |Green,x		; Save Result
	clc
	lda |Blue,x			; Current 8.8 blue
	adc |BlueStep,x     ; Add Fractional Step 
	sta |Blue,x         ; Save Result

	; As part of the apply, coalesce the colors, and store back in SourceColors
	; Buffer, so we can blit from SourceColors back out into display memory

	lda |Red,x
	and #$F00
	sta |SourceColors,x
	lda |Green,x
	and #$F00
	lsr
	lsr
	lsr
	lsr
	ora |SourceColors,x
	sta |SourceColors,x
	lda |Blue,x
	and #$F00
	xba
	ora |SourceColors,x
	sta |SourceColors,x   	; SourceColors now has our color ready for VGC


	inx
	inx

	txa
	lsr
	cmp numColors,s
	bcc ]apply_loop

	jsr vsync		; Sync to line 200

	lda numColors,s 	; calc length
	asl					; 2 bytes per color
	dec					; -1 for the mvn
	ldx #SourceColors   ; source buffer
	ldy #$9E00		 	; dest buffer
	mvn ^SourceColors,$E19E00	

	phk 				; fix bank
	plb

	lda fadeCount,s  	; 16 count down
	dec
	sta fadeCount,s
	bmi :fade_done

	bra ]fade_loop


:fade_done

	pla 		; restore stack, and return
	pla
	rts



;
; Wait for Scanline 200
;
vsync	mx %00
	sei
	php
]lp
	ldal $e0c02e
	asl
	and #$00FF
	cmp #200
	bcc ]lp
	cmp #202
	bcs ]lp
	plp
	rts	

********************************************************************************
*
* Work Memory for the fades
*
********************************************************************************

SourceColors ds 512		; 256 colors * 2
TargetColors ds 512 	; 256 colors * 2

RedStep      ds 512		; 8.8 fraction for fading red channel
GreenStep    ds 512 	; 8.8 fraction for facing green channel
BlueStep     ds 512		; 8.8 fraction for fading blue channel

Red          ds 512     ; 8.8 fraction current red
Green        ds 512     ; 8.8 fraction current green
Blue         ds 512     ; 8.8 fraction current blue



logo_colors
	dw $055,$FF0,$1F0,$180,$444,$000,$D62,$F00
	dw $930,$800,$000,$D0F,$00F,$009,$000,$FFF

border_colors
 dw $0,$d03,$9,$d2d,$72,$555,$22f,$6af ; Border Colors
 dw $850,$f60,$aaa,$f98,$d0,$ff0,$5f9,$fff

logos_lz4
	putbin ../data/logos.lz4

********************************************************************************
	put lz4.s

