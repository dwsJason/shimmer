*
* Common Direct Page Equates
*

;  DUM Equate Generation doesn't
;  Allow for Direct Page Access, boo

;	DUM $0
source   equ $0 ;ds 4
dest	 equ $4 ;ds 4

temp0 equ $8  ;ds 4
temp1 equ $C  ;ds 4
temp2 equ $10 ;ds 4
temp3 equ $14 ;ds 4
temp4 equ $18 ;ds 4
temp5 equ $1C ;ds 4
temp6 equ $20 ;ds 4
temp7 equ $24 ;ds 4
temp8 equ $28 ;ds 4
temp9 equ $2C ;ds 4
temp10 equ $30 ; ds 4

vscroll equ $40
hscroll equ $42

num_image_lines = $50    ; number of lines of data in the image
top_of_image    = $52    ; first entry in jump table represents this line
num_image_columns = $54
left_of_image   = $56

pIndexEnd equ $E0
pImageBank   equ $F0
pCodeBank0   equ $F4
pCodeBank1   equ $F8
pIndexBank   equ $FC


;------------------------------------------------------------------------------
;
; delta_compile
; Line Compiler, for vertical scrolling, shim all these addresses
; so they overlap temp variables
;
pSource equ $0
pDest   equ $4
pTarget equ $8
pResult equ $C

CacheY  equ $10
CacheA  equ $12

token   equ $14  ; token/key/pixel data we need to store
index   equ $16

pList	equ $18  ; short pointer to the current "list"

;
; map_find_or_add_key
;
key   = $1A     ;30
pMap  = $1C     ;32
value = $1E     ;34
key_count = $20 ;36


;
; List Allocator, which is an index to the next available list address
;
pNextFreeList equ $22 ;$1A ; short pointer for list allocator

data	equ $24 ;$1C
opcode  equ $26 ;$1E
; extra's for the DeltaC compiler
stride  equ $28 ; used by the deltaC column compiler (arbitrary stride)
temp_y  equ $28 ; used by normal delta compiler, to track current scanline
lineCount equ $2A
listSize equ $2C
;	DEND	

