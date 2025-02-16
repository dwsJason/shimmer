;
; Shimmer Viewer Merlin32 linker file
;
	dsk shimmer.sys16
	typ $b3				; filetype
	aux $db07			; auxtype
	;xpl					; Add ExpressLoad
	
*----------------------------------------------	
	asm init.s
	ds 0
	knd #$1010		; static+code+initialization
	ali None
	lna fun2gs		; init segment
	sna init
*----------------------------------------------	
	asm shell.s
	ds 0	   	; padding
	knd #$1000  ; kind
	ali None	; alignment
	lna shimmer	; load name
	sna start	; segment name
*----------------------------------------------	
	asm shimmer.s
	ds 0		; padding
	knd #$1100  ; kind
	ali None    ; alignment
	lna shimmer ; load name
	sna view    ; segment name
*----------------------------------------------	

