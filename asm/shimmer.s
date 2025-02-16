*
* Shimmer, 135 color SHR image viewer
*

*
* This is called shimmer because it will page flip 2 SHR images as quickly as
* as video interface on the machine allows
*

*
* We display as 128x100 pixel image, which is capable of up to 135 unique
* colors, all colors available on all lines, cheating our way past the 16
* colors per line limitation, by using persistence of vision to mix colors
*

*
* Prepare a 16 color $C1 Image, where
*
*     128x100 page 1 is on the upper left
*     128x100 page 1 is placed vertically below
*

	dsk shimmer.l

	use   drm.macs
	use   common.i
	use   dp.i

; Variables we need
pInPixels = temp6
pInSCB    = temp7
StackPos = temp8
SCBPos = temp9

CompileShimmer ent
	mx %00
	phk
	plb

	; to help us see it compile
	lda #$2000
	sta pTarget
	lda #$01
	sta pTarget+2

	; long pointer to the source pixels
	lda pImageBank
	sta pInPixels
	lda pImageBank+2
	sta pInPixels+2

	clc
	lda pInPixels
	adc #$7d00
	sta pInSCB
	lda pInPixels+2
	sta pInSCB+2

	lda pCodeBank0
	sta pDest
	lda pCodeBank0+2
	sta pDest+2

	lda #$2000+{160*50}+112
	sta StackPos

	lda #50
	sta SCBPos

	jsr Compile100Lines

	lda pCodeBank1
	sta pDest
	lda pCodeBank1+2
	sta pDest+2

	lda #$2000+{160*50}+112
	sta StackPos

	lda #50
	sta SCBPos

	jsr Compile100Lines

	rtl

*******************************************************************************
*
* Generate the 100 line blit
*
Compile100Lines mx %00

	stz lineCount

	sep #$20

	; Preserve Stack
	lda #$BA	; TSX
	jsr Emit

	lda #$9B	; TXY
	jsr Emit

]loop
	sep #$20

	jsr CompileLine

	rep #$30
	jsr ClearLine

	lda lineCount
	inc
	sta lineCount
	cmp #100
	bcc ]loop

	sep #$20

	; Fix Stack
	lda #$BB	; TYX
	jsr Emit

	lda #$9A	; TXS
	jsr Emit

	; Return
	lda #$6B    ; RTL
	jsr Emit

	rep #$30

	rts

*******************************************************************************

ClearLine mx %00

	lda #0
	sta [pTarget]	; seed 0

	ldx pTarget 	; source
	txy
	iny 		 	; dest
	lda #158		; 159 bytes length
	mvn $01,$01

	sty pTarget     ; let MVN do this math, to continue on next call

	phk
	plb

	; clear the SCB
	ldx lineCount
	lda #0
	sep #$20
	sta >$019C000,x 
	rep #$30

	rts

*******************************************************************************

CompileLine mx %10

	lda #$A2	; LDX #StackPointer
	jsr :Emit

	lda <StackPos
	jsr :Emit
	lda <StackPos+1
	jsr :Emit

	lda #$9A	; TXS
	jsr :Emit

	lda #$A9    ; lda #$00
	jsr :Emit

	lda [pInSCB]
	jsr :Emit

	lda #$85 	; sta $dp
	jsr :Emit
	lda SCBPos 	; the SCB
	jsr :Emit
	inc SCBPos


	ldy #64		; 128 pixels is 64 bytes, which is 32 pea
]lp
	phy
	lda #$F4	; PEA
	jsr :Emit
	ply

	dey
	lda [pInPixels],y
	tax
	dey
	lda [pInPixels],y
	phy
	jsr :Emit
	txa
	jsr :Emit

	ply
	bne ]lp

	rep #$31

	; Move the Stack Pos
	lda <StackPos
	adc #160
	sta <StackPos

	; Next Line of Pixels
	lda <pInPixels
	adc #160
	sta <pInPixels

	inc pInSCB

	sep #$20

	rts


; Increment Result Pointer by 1
:Emit
Emit mx %10
	sta [pDest]
	ldy <pDest
	iny
	sty <pDest
	rts



