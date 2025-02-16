         lst   off
*
*     DreamWorld Software Generic Shell
*
*     v .02    10/8/90
*
*  Updated for Merlin 32  07/11/2020
*
*  shimmer.s, halftone images 02/16/2025
*
*

*   OA-F  "damnmenu" to find menu definitions
*

         rel
         dsk   shell.l
         use   drm.macs
         use   common.i
         use   dp.i

         ext FadeToBorderLong
         ext LZ4_Unpack
         ext CompileShimmer


;
; Defines, for the list of allocated memory banks
;
banks_count equ $80
banks_data  equ $82

vidmode  =     $8080      ;Video mode for QD II (320) ($8000)
                          ;640 mode  ($8080)

*   startup tools, begin program

tool     equ   $e10000


startup  ent
         mx %00

         ; in theory here, our ProgID is already in A
         ; and our DP is already in D
         ;pha
         ;phd

         phk
         plb              ;make the program bank = data bank

SetRes   sep   $30        ; 8-bit mode
         lda   #$5C       ; jml
         stal  $3F8       ; ctrl-y vector
         rep   $30        ; 16-bit mode
         lda   #Resume
         stal  $3F9       ; $3f9,3fa
         lda   #^Resume   ; bank byte
         stal  $3FB       ; $3fb,3fc

         _TLStartUp       ;Gotta start this baby

         ~MMStartUp       ;start the Memory manager
                          ; CheckToolError

         pla              ;retrieve our program ID
         sta   ProgID

;-------------------------------------------------------------------------------
;
; Initialize List of memory Banks
;
         stz <banks_count

;-------------------------------------------------------------------------------
         PushLong  #0                   ; Compact Memory
         PushLong  #$8fffff
         PushWord  ProgID
         PushWord  #%11000000_00000000
         PushLong  #0
         ldx   #$0902
         jsl   tool       ; NewHandle
         ldx   #$1002
         jsl   tool       ; DisposeHandle
         ldx   #$1F02
         jsl   tool       ; CompactMem

;-------------------------------------------------------------------------------
         jsl FadeToBorderLong

	 jsr ZeroDisplayPixels

;-------------------------------------------------------------------------------
;
; Startup way too many tools
;

         PushLong #0      ;result space
         lda   ProgID     ;user ID
         pha
         pea   #$0        ;reference by handle
         PushLong #startref
         ldx   #$1801     ;startuptools
         jsl   $e10000
         PullLong stref

;-------------------------------------------------------------------------------
; I'm pretty sure one of the tools is allocating this out from under me
;
;         PushLong  #0                   ; Ask Shadowing Screen ($8000 bytes from $01/2000)
;         PushLong  #$8000
;         PushWord  ProgID
;         PushWord  #%11000000_00000011
;         PushLong  #$012000
;         ldx   #$0902
;         jsl   tool       ; NewHandle
;         pla
;         pla
;         bcc :NoError
;
;         lda #0
;         pha
;         pha
;         pha
;         pha
;         PushLong #:shadow_error
;         Tool $590e ; AlertWindow
;         pla
;         brl ShutDown
;
;;-------------------------------------------------------------------------------
;
;:shadow_error asc '40\Shimmer requires the Super Hires shadow'
;        asc ' memory to function properly.\^#5',00
;
;*-----------------------------

:NoError

;------------------------------------------------------------------------------
; Allocate all the memory we're going to use, up-front
;
		lda #0
		ldx #1
		jsr getmem
		bcs :oom
		jsr dereference
		sta <pImageBank
		stx <pImageBank+2

		lda #0
		ldx #1
		jsr getmem
		bcs :oom
		jsr dereference
		sta <pCodeBank0
		stx <pCodeBank0+2

		lda #0
		ldx #1
		jsr getmem
		bcs :oom
		jsr dereference
		sta <pCodeBank1
		stx <pCodeBank1+2

		lda #0
		ldx #1
		jsr getmem
		bcs :oom
		jsr dereference
		sta <pIndexBank
		stx <pIndexBank+2

;------------------------------------------------------------------------------

		; Setup the Default Image

		;pea ^yesbg
		;pea yesbg
		;pei pImageBank+2
		;pei pImageBank
		;jsl LZ4_Unpack

         jmp   DoMenu
:oom
         lda #0
         pha
         pha
         pha
         pha
         PushLong #:oom_error
         Tool $590e ; AlertWindow
         pla
         brl ShutDown

*------------------------------------------------------------------------------

:oom_error asc '40\Shimmer requires 256K of free'
        asc ' memory to function properly.\^#5',00

*------------------------------------------------------------------------------


:trouble
         pha
         PushLong #0
         ldx   #$1503
         jsl   $e10000
         rtl

backhandle dw  0,0

*
*  Draw the desktop
*

DoMenu
;         ldx   #$0001
;         lda   #$0000
;         jsr   getmem
;         bcc   :ov3
;         brl   ShutDown
;:ov3                      ;handle in a and x
;         jsr   dereference
;
;         sta   p:rbuf     ; set up Disk I/O buffer
;         txa
;         sta   p:rbuf+2
;
;         ; A contains bank address to add
;         jsr   AddBank

* PushLong #0
* PushPtr ExampleM
* _NewMenu
* PushWord #0
* _InsertMenu

         PushLong #0
         PushPtr EditM
         _NewMenu
         PushWord #0
         _InsertMenu

         PushLong #0
         PushPtr FileM
         _NewMenu
         PushWord #0
         _InsertMenu

         PushLong #0
         PushPtr AppleM
         _NewMenu
         PushWord #0
         _InsertMenu

         PushLong #1
         _FixAppleMenu

         PHA
         _FixMenuBar
         PLA

         _DrawMenuBar

         _InitCursor

         JSR    DoOpen   

*  Command Processor
*
*  Use TaskMaster to handle any and all events.
*  We only check for events within the menus
*  currently. The 'wInSpecial' ensures that we
*  get events 250-255.
*

GetEvent
         pha
         PushWord #$FFFF   ; all the things
         PushPtr TaskRecord
         _TaskMaster
         pla

         cmp   #25        ;wInSpecial
         beq   :DoEvent
         cmp   #17        ;wInMenuBar
         bne   GetEvent

:DoEvent
         sec
         lda   TaskData
         sbc   #250       ;Reduce to 0 and
         asl              ;  double to find
         tax              ;  index into table.

         jsr   (Cmds,X)

         PushWord #0
         PushWord TaskData+2
         _HiliteMenu

         bra   GetEvent

*  damnmenu
*
*  Menu definitions
*

*
*NOTE Currently setup for Merlin32
*for Merlin 16, adjust the ]mnum, and ]inum definitions down by 1
*due to how merlin 16 will scope / evaluate them inside the macro
*

]mnum    =     1          ; "1" - 1 = 0
AppleM   Menu  '@';'X'
]inum    =     256
         Item  'About Shimmer...';Divide;'';Kybd;'?/'

FileM    Menu  ' File '
                          ; Item 'New';Kybd;'Nn'
         Item  'Open...';Divide;'';Kybd;'Oo'
]OpenItem =     ]inum
]inum    =     255
         Item  'Close';Divide;'' ; (#255)
]inum    =     ]OpenItem
         Item  'Quit';Kybd;'Qq'
]QuitItem =     ]inum

EditM    Menu  ' Edit '
]inum    =     250
         Item  'Undo';Divide;'';Kybd;'Zz' ; (#250)
         Item  'Cut';Kybd;'Xx' ; (#251)
         Item  'Copy';Kybd;'Cc' ; (#252)
         Item  'Paste';Divide;'';Kybd;'Vv' ; (#253)
         Item  'Clear'    ; (#254)

*ExampleM Menu ' Example '
*]inum = QuitItem
* Item 'Bold';Disable;''
* Item 'Disable';Disable;''
* Item 'Italic';Disable;''
* Item 'Underline';Disable;''
* Item 'Divide';Disable;''
* Item 'Check';Disable;''
* Item 'Blank';Disable;''

         asc   '.'        ;End of menu.


TaskRecord
tType    ds    2          ;Event code
tMessage ds    4          ;Type of Event
tWhen    ds    4          ;Time since startup
tWhere   ds    4          ;Mouse Location
tMod     ds    2          ;Event modifier
TaskData ds    4          ;Taskmaster Data
TaskMask adrl  $00001FFF  ;Taskmaster Handle All

Fileinfo                  ;place for file info
Fopen    dw    0          ;good info?
Ftype    dw    0          ;file type
Atype    adrl  0          ;aux type
Nref     dw    0          ;Name reference type
Name     adrl  name       ;Where is the name? (pointer)
Pref     dw    0          ;Path reference type
Path     adrl  path       ;Where is the path? (pointer)

name     ds    256        ;space for filename
path     ds    512        ;space for pathname
fullp    ds    768

ProgID   dw    0


*  ShutDown Routine

ShutDown ent              ;a global label so other modules can die here.:)
         pea   #$0        ;ref is pointer
         PushLong stref   ;Reference to startstop record
         ldx   #$1901
         jsl   $e10000    ;Shut Down Tools

MMout    ~MMShutDown ProgID

TLout    _TLShutDown

:1       _QUIT QuitParms
         bra   :1         ;keep quitting if GS/OS is busy

QuitParms adrl $0
         ds    2

*******************************************************************************
* getmem
*
* A = size Low
* X = size High
*
* Destroys Y
*
* Return AX as handle
* c = 0   success
* c = 1   failed
*
getmem	 mx %00
         ldy #0
         phy			  ; Space for Results
         phy              ; Space for Results
         phx              ; size in bytes high byte
         pha              ; size in bytes low byte
         lda   ProgID
         pha
gm_atr   pea   #%1100000000011100 ; Attributes, page aligned, not allowed to wrap banks
         phy
         phy              ; Ptr to where Block is to begin
         ldx   #$0902
         jsl   tool       ; NewHandle
         pla
         plx
         rts

*******************************************************************************
* dereference memory handle
*
* Input:
*    AX = pHandle
*
* Wrecks Y
* C unaffected
*
* Output:
*    AX = pMemory
*
dereference mx %00
         pei   0
         pei   2
         sta   0
         stx   2
         lda   [0]
         pha
         ldy   #2
         lda   [0],y
         tax
         ply
         pla
         sta   2
         pla
         sta   0
         tya
         rts

*   Resume routine for Control-Y vector...

Resume   phk
         plb
         clc
         xce              ; set native mode
         rep   $30        ; 16-bit mode
         jmp   ShutDown   ; Let's get outta here!!

startref                  ;tool startup record
         dw    $0000      ;flags
         dw    vidmode    ;videoMode
         ds    6          ;resFileID & dPageHandle are set by the StartUpTools call
         dw    19         ;# of tools
                          ;tool number, version number
         dw    1,$0300    ;Tool Locator
         dw    2,$0300    ;Memory Manager
         dw    3,$0300    ;Miscellaneous Tools
         dw    4,$0301    ;QuickDraw II
         dw    5,$0302    ;Desk Manager
         dw    6,$0300    ;Event Manager
         dw    11,$0200   ;Integer Math
         dw    14,$0301   ;Window Manager
         dw    15,$0301   ;Menu Manager
         dw    16,$0301   ;Control Manager
         dw    18,$0301   ;QuickDraw II Aux.
         dw    19,$0300   ;Print Manager
         dw    20,$0301   ;LineEdit Tools
         dw    21,$0301   ;Dialog Manager
         dw    22,$0300   ;Scrap Manager
         dw    23,$0301   ;Standard File Tools
         dw    27,$0301   ;Font Manager
         dw    28,$0301   ;List Manager
         dw    34,$0101   ;TextEdit Manager

stref    adrl  0          ;reference to the startstop record

*
*  Look up table for event processor
*

Cmds
         da    DoUndo     ; These menu items are set as
         da    DoCut      ;  required by Apple for
         da    DoCopy     ;  NDA compatibility.
         da    DoPaste
         da    DoClear
         da    DoClose

         da    DoAbout    ;This starts OUR items. (#256)

         da    DoOpenFromMenu
         da    ShutDown

*
*  Main code goes here...
*

DoInvalidFile
         ~NoteAlert #InvalidTemplate;#0
         pla
         rts

InvalidTemplate
         dw    62,128,151,512 ;position
         dw    1
         dfb   128,128,128,128
         adrl  :Item1
         adrl  :Item2
         adrl  :Item3
         adrl  0

:Item3   da    3
         dw    33,76,43,291 ;rect
         da    StatTextItem+ItemDisable
         adrl  :Item3Txt
         da    0
         da    0
         adrl  0
:Item3Txt
         str   'This file seems invalid.'

:Item2   dw    2
         dw    13,122,22,251 ;rect
         da    StatTextItem+ItemDisable
         adrl  :Item2Txt
         da    0
         da    0
         adrl  0
:Item2Txt str  'Cannot play!!'

:Item1   da    1
         dw    66,272,78,350 ;rect
         da    ButtonItem
         adrl  :Item1Txt
         da    0
         da    1
         adrl  0
:Item1Txt str  ' Ok '



DoAbout
         ~NoteAlert #AboutTemplate;#0
         pla
         rts

AboutTemplate
         dw    62,128,151,512 ;position
         dw    1
         dfb   128,128,128,128
         adrl  :Item1
         adrl  :Item2
         adrl  :Item3
         adrl  0

:Item3   da    3
         dw    33,76,43,291 ;rect
         da    StatTextItem+ItemDisable
         adrl  :Item3Txt
         da    0
         da    0
         adrl  0
:Item3Txt
         str   '(C) 2025 DreamWorld Software'

:Item2   dw    2
         dw    13,122,22,270 ;rect
         da    StatTextItem+ItemDisable
         adrl  :Item2Txt
         da    0
         da    0
         adrl  0
:Item2Txt str  'Shimmer Viewer v1.0'

:Item1   da    1
         dw    66,272,78,350 ;rect
         da    ButtonItem
         adrl  :Item1Txt
         da    0
         da    1
         adrl  0
:Item1Txt str  ' Ok '

DoOpenFromMenu
DoOpen
         pea   #30        ;x of upper left corner
         pea   #40        ;y of upper left corner
         pea   #0         ;type of reference
         PushLong #:message ;location of pascal string
         PushLong #0      ;Filter... none for now
         PushLong #:filter ;Pointer to type list record
         PushLong #Fileinfo ;Pointer to reply record

         ldx   #$0e17     ;SF Get File 2
         jsl   $e10000
         bcc   :cont
         brl   :trouble
:cont
         lda   Fopen      ;good?
         bne   :keepitup

:bye     rts

:keepitup
         lda   path+2     ;length of pathname
         sta   fullp

         ldx   #0
:lup
         lda   path+4,x   ;make this class 1 string a prodos string
         sta   fullp+1,x
         inx
         inx
         cpx   path+2
         bcc   :lup

         _Open p:open
         bcc   :read_filesize
         brl   :trouble
:read_filesize
         lda   p:open
         sta   p:read
         sta   p:get_eof

         _GET_EOF p:get_eof
         bcc   :eof_seems_good
:err_close
;        jsr FreeBanks
         _Close p:close
         bra    :trouble

:eof_seems_good

	; Check to see if the file is the right size to be a C1
	; if it is, we already have the memory at pImageBank	 
        lda p:eof+2
		bne :err_close
                    
		lda #$8000
		cmp p:eof
		beq :looks_like_c1	

        ; Pop up an Alert

        bra :err_close

:looks_like_c1
              
         ; Read in the File
	; Read 32K
         lda #$8000
         sta p:rsize
         stz p:rsize+2

		; pointer where to read
         lda <pImageBank
         sta p:rbuf+0
         lda <pImageBank+2
         sta p:rbuf+2

        _Read p:read
       
        bcs   :err_close

:close_exit
         _Close p:close
         bcs   :trouble
         brl   ViewImage

:required_banks
:temp
         dw    0

:trouble
         pha
         PushLong #0
         ldx   #$1503
         jsl   $e10000
         rtl

:message str   'Open 135 Color C1:'

:filter  dw    0          ; (count 0/no filter), set to 1 for only show s16 files

;         dw    1          ; (count 1) Show only s16 files
;         dw    0,$b3,0,0  ;flags, filetype, auxtype

p:close
p:open   dw    1          ;ref number
         adrl  fullp      ;pathname
         adrl  0          ;io buffer, doesn't reallymatter

p:write
p:read   dw    0
p:rbuf   adrl  0
p:rsize  adrl  $10000     ;number requested  64k
         adrl  0          ;number transfered

p:get_eof dw 0     ; reference number
p:eof     adrl 0   ; end of file


*
* Hold a backup of the system palette
*
scbs_and_palette
        ds 768

*******************************************************************************
ZeroDisplayPixels mx %00

		_shadowON

		lda #0
		sta >$012000
		lda #{160*200}-3	; length
		ldx #$2000			; source
		ldy #$2002			; dest
		mvn $01,$01

		phk
		plb

		rts

*******************************************************************************
*******************************************************************************
*
* Copy the palettes from the current image onto the screen
*
CopyPalettes mx %00

        lda <pImageBank+2
        ora #$0100
        xba
        sta |:mvn+1

        ldx #$7D00 ; Temp buffer
        ldy #$9D00 ; $E19D00, the SBCS
        lda #$2FF
:mvn    mvn 0,0
        phk
        plb

		rts

*******************************************************************************

pData = $FC

ViewImage mx %00

        ; The mouse cursor doesn't play nice with what we're doing
        jsr HideCursorEtc

;========================> TEMP
         do 1
         lda <pImageBank+1
         and #$FF00
         ora #$0001
         sta :mvn+1

         lda #$7FFF ; length
         ldx <pImageBank
         ldy #$2000   ; poking to 01/2000
:mvn     mvn $01,$01
	
         phk
         plb
         fin
;========================> TEMP

         jsl CompileShimmer

         phk
         plb

         ; Self Modify the dispatches
         lda pCodeBank0
         sta :p0+1
         lda pCodeBank0+1
         sta :p0+2
         lda pCodeBank1
         sta :p1+1
         lda pCodeBank1+1
         sta :p1+2
      
; Display Loop
         php
         phd      ; save direct page

         sei

         tsc
         sta :stack

         _auxON

         ldx #$1FF ; This is sketchy, we need to place the stack
         txs

         lda #$9D00
         tcd      ; shove the direct page on top of the SCB table

         pea #$0101 ; B = 1, so the stack is drawing onto SHR
         plb
         plb


         sep #$30
         mx %11
         lda $C010      ; clear strobe

]viewer
         ;_border 0
         rep #$30
         jsr vsync150      ; wait for scanline 150
         ;_border 2

         sep #$20
:p0      jsl :rtl          ; Blit Image 0

         ;_border 0
         rep #$30
         jsr vsync150      ; wait for scanlien 150
         ;_border 2

         sep #$20
:p1      jsl :rtl          ; Blit Image 1

         sep #$30
         lda $C000
         bpl ]viewer       ; branch no key
         lda $C010         ; clear strobe / eat the key
         
         rep #$30
         phk
         plb

         ldx :stack
         txs

         _auxOFF
                  
         pld
         plp

         phk
         plb
;------------------------------
; restore

         jmp ShowCursorEtc
         rts
:rtl     rtl

:stack   ds 2     ; Need to save the stack

;
; We don't want to corrupt the original TaskRecord
;
:TaskRecord
:tType    ds    2          ;Event code
:tMessage ds    4          ;Type of Event
:tWhen    ds    4          ;Time since startup
:tWhere   ds    4          ;Mouse Location
:tMod     ds    2          ;Event modifier
:TaskData ds    4          ;Taskmaster Data
:TaskMask adrl  $00001FFF  ;Taskmaster Handle All

DoUndo
DoCut
DoCopy
DoPaste
DoClear
DoClose
         RTS

text
         str   "Written By:  Jason Andersen and Steven Chiang"

********************************************************************************
*
* Append a Bank to the list
*
AddBank mx %00
        ldx <banks_count
        sta <banks_data,x
        inx
        stx <banks_count
        rts

********************************************************************************
*
* Free Memory, and Clear Bank List
*
FreeBanks mx %00

]loop
        ldx <banks_count
        dex
        bmi :done
        stx <banks_count

        ldy #0
        phy     ; space for result
        phy

        lda <banks_data,x
        and #$00FF
        phy     ; memory address high
        phy     ; memory address low

        ldx #$1A02 ; FindHandle
        jsl tool

        ldx #$1002 ; DisposeHandle
        jsl tool

        bra ]loop

:done
        rts

********************************************************************************
*******************************************************************************
*
* Hide Cursor, ands Save palettes
*
HideCursorEtc mx %00

        ; The mouse cursor doesn't play nice with what we're doing
        _HideCursor

        lda #$2FF
        ldx #$9D00 ; $E19D00, the SBCS
        ldy #<scbs_and_palette ; Temp buffer
        mvn $E1,^scbs_and_palette
        ; this happens to end with the bank happy

        phk
        plb
        rts

*******************************************************************************
*
* Show Cursor, and Restore Palettes + Desktop
*
ShowCursorEtc mx %00

        lda #$2FF
        ldx #<scbs_and_palette ; Temp buffer
        ldy #$9D00 ; $E19D00, the SBCS
        mvn ^scbs_and_palette,$01
        phk
        plb


        ;
        ; Redraw the Screen
        ;
        Tool $2a0f ; DrawMenuBar

        PushLong #0
        Tool $390E ; RefreshDesktop

        ;
        ; Show the Mouse
        ;
        _ShowCursor

        rts


*******************************************************************************
*
* Wait for Scanline 150
*
vsync150	mx %00
	sei
	php
]lp
	ldal $e0c02e
	asl
	and #$00FF
	cmp #150
	bcc ]lp
	cmp #152
	bcs ]lp
	plp
	rts	

*******************************************************************************
