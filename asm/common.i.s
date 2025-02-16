;
; common.i.s 
;

_border mac
	sep #$20
	lda #]1
	stal $E0C034
	rep #$31
	<<<

_shadowON mac
	lda >$00C035
	and #$FFF7
	sta >$00C035
	<<<
	
_shadowOFF mac
	lda >$00C035
	ora #$0008
	sta >$00C035
	<<<

_auxON mac
	lda >$00C068
	ora #$0030
	sta >$00C068
	<<<

_auxOFF mac
	lda >$00C068
	and #$FFCF
	sta >$00C068
	<<<

dc.t mac
	adr ]1
	<<<
	
dc.b mac
	db ]1
	<<<
	
dc.w mac
	dw ]1
	<<<

dc.l mac
	adrl ]1
	<<<
	
ds.b mac
	ds ]1
	<<<

cstr mac
	asc ]1
	db 0
	<<<

;-------------------------------------------------------------------------------
;
; C/C++ equates
;
nullptr equ 0
null equ 0
NULL equ 0

; Long Conditional Branches

beql mac
    bne skip@
    jmp ]1
skip@
    <<<

bnel mac
    beq skip@
    jmp ]1
skip@
    <<<

bccl mac
    bcs skip@
    jmp ]1
skip@
    <<<

bcsl mac
    bcc skip@
    jmp ]1
skip@
    <<<

bpll mac
	bmi skip@
	jmp ]1
skip@
    <<<

bmil mac
	bpl skip@
	jmp ]1
skip@
    <<<


