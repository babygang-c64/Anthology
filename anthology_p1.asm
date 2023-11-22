;=========================================================
; [Babygang] Anthology 1988-2022, Part 1 - intro
;---------------------------------------------------------
; map : 
; 
; screen : $0400 - 0800
; code : $0810 - 1000 : petscii et player decompte
; zik : $1000 - $16A4 -> relocated to $ab00 $b1a4
; sin_lut : $1700-$1b32
; sin_wave : $1c00
; charset : $2000 - $2800 : pour player decompte
; data : $2800 - $A629 : data animation decompte
; $a700 : bootstrap part 2
; (taille data : $07e29)
; font : $c000
; screen : $c000
; couleurs : $c800 et ensuite utilisation pour sprites
; logo hires : $E000-$FF40
;---------------------------------------------------------
; Build :
; ./exomizer sfx 0x0810 ../../anthology_p1.prg -n -o antp1.prg
; Krill loader : init taille 1AE8 -> 2800 à 4300
;                loader taille 01F1 -> CE00 à CFF1
;=========================================================

* = $0810

screen = $0400
screencolor = $D800
data = $2800
install = $2800
loadraw = $ce00
loadcompd = $ce0b
COLOR = $c800
bootstrap_part2 = $a700
;dest_bootstrap_part2 = $7F00
dest_bootstrap_part2 = $8400

init_zik = $ab00
play_zik = $ab03
ctrl_zik = $ab06

zp_data = $50
zp_scr = $52

zp = $50

multiplicand = $b0
multiplier = $b1

;---------------------------------------------------------
; Intro petscii : disparition verticale de l'ecran
;---------------------------------------------------------

start:
    ;jsr relocate_zik
    jsr install
    bcc start_ok
    jmp $fce2
start_ok
    sei
    lda #%0001110
    sta $01

    ;-- init musique
    lda #1
    jsr init_zik
    ;inc $d020

	;-- init IRQ
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda #$1b
    sta $d011
    lda #$01
    sta $d01a
	lda #0
	sta $d012
    lda $dc0d
    lda $dd0d

	lda #<irqIntro
	sta $0314
	lda #>irqIntro
	sta $0315
	cli
    ldx #<filename
    ldy #>filename
    jsr loadraw

wait_intro_finie:	
	lda intro_finie
	cmp #$02
	bne wait_intro_finie
	jsr player_decompte
	jmp explosion

filename
    .text "P1"
    .byte 0

;---------------------------------------------------------
; IRQ intro petscii
;---------------------------------------------------------

irqIntro:
	
	;-- reset IRQ et appel musique
	asl $d019
	jsr play_zik
	
	;-- test fin effet
	lda screen_pas_fini
	beq screen_fini
	jsr plotSeqX
	jmp fin_irq
screen_fini:
	ldx nb_colors 
	beq fin_colors_ok
	lda bck_colors,x
	dec nb_colors
	sta $d020
	sta $d021
	jmp fin_irq
fin_colors_ok:
	lda #2
	sta intro_finie
fin_irq:
	jmp $ea81 

plotSeqX:
	lda #0
	sta screen_pas_fini
	ldy #39
plotSeqSuite:
	
plotSeqY:
	lda posY,y
	cmp #25
	beq finSeq
	inc screen_pas_fini
	tax 

	lda $dc03
	eor $dc04
	cmp #167
	bpl finSeq

	lda posYL_screen,x
	sta zp
	lda posYH_screen,x
	sta zp+1
	
	tya
	tax
	inc posYr,x
	lda posYr,y
	and #7
	sta posYr,y
	cmp #7
	bne pasIncY
	inc posY,x

pasIncY:
	tax
	lda petscii_anim,x
	sta (zp),y
	lda zp+1
	clc
	adc #$d4
	sta zp+1
	lda #14
	sta (zp),y
finSeq:
	dey
	bpl plotSeqSuite
	lda screen_pas_fini
	bne pas_encore
	lda #14
	sta $d021
	lda #32
	ldy #0
clear:
	sta $0400,y 
	sta $0500,y 
	sta $0600,y 
	sta $0700,y 
	iny
	bne clear
pas_encore:
	rts

petscii_anim:

.byte $63,$77,$78,$e2,$f9,$ef,$e4,$a0

posY:

.byte 0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0,0,0

posYr:

.byte 0,0,0,0,0,1,1,1,2,2
.byte 3,4,5,4,3,2,2,1,1,1
.byte 0,0,0,0,0,1,1,1,2,2
.byte 3,2,2,1,1,1,0,0,0,0

screen_pas_fini:

.byte 1

intro_finie:
.byte 1

nb_colors:
.byte fin_colors-bck_colors

bck_colors:
.byte 0,0,11,11,11,11,12,12,12,15,15,7,1,15,15,14,14,14
fin_colors:

nb_tempo:
    .byte 0
i_tempo:
    .byte 0

;---------------------------------------------------------
; Player_decompte
;---------------------------------------------------------

player_decompte:
    ;-- setup des tempos : attente entre chaque image
    ldx #$00
    stx i_tempo
    lda tempos,x
    sta nb_tempo

    ;--  setup zik irq
    sei
    lda #220
    sta $d012
    lda #<irqzik
    sta $0314
    lda #>irqzik
    sta $0315
    lda #30
    sta $01
    cli

    ;--  charset $2800
    lda #$18
    sta $d018
    ;--  clear screen
    lda #$01
    ldx #$00
    ldy #$00
    ;--  screen colors = black
    stx $d020
    stx $d021
cls:
    lda #$00
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    lda #$01
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne cls

    jmp loop_draw

irqzik:
	
    asl $d019
    jsr play_zik
    lda nb_tempo
    beq irqzik_suite
    dec nb_tempo
irqzik_suite:
	jmp $ea81

    ;-- draw : trace 1 ecran a partir des donnees compressees
    ;-- assume y = 0
    
draw:
    lda (zp_data),y

    ;-- si A >= $80 : copie des A-$80 octets suivants
    bmi copie

    ;-- si 0 : fin de l'ecran
    bne mult
    jmp stop

    ;-- sinon, copie X=A fois l'octet suivant
    ;-- note : ici on aurait pu faire un lax (zp_data),y et eviter tax
mult:
    tax
    inc zp_data
    bne mult0
    inc zp_data+1
mult0:
    lda (zp_data),y

mult1:
    sta (zp_scr),y
    inc zp_scr
    bne mult2
    inc zp_scr+1
mult2:
    dex
    bne mult1

avance:
    ;-- avance sur la prochaine valeur, boucle sur le decodage
    inc zp_data
    bne draw
    inc zp_data+1
    jmp draw

    ; -- copie : recopie les N= A-$80 caracteres suivants
copie:
    and #$7f
    tax
copie0:
    inc zp_data
    bne copie1
    inc zp_data+1
copie1:
    lda (zp_data),y
    sta (zp_scr),y
    inc zp_scr
    bne copie2
    inc zp_scr+1
copie2:
    dex
    bne copie0
    beq avance

    ;-- stop : fin frame
stop:
    inc zp_data
    bne stop2
    inc zp_data+1
stop2:
    rts

    ;-- demarrage affichage, pour x frames, etat 1ere image = couleur
loop_draw:
    lda #<data
    sta zp_data
    lda #>data
    sta zp_data+1
    ldy #$00
    lda #>screencolor
    sta zp_scr+1
    sty zp_scr

loopd1:
    ;-- si 1er octet = 0 : fin de l'animation, explosion
    lda (zp_data),y
    bne pas_fini_decompte
	rts
pas_fini_decompte:

    ; si > $80, destination = couleur
    ; sinon, destination = ecran

    bmi loop_couleur
    lda #>screen
    sta zp_scr+1
    sty zp_scr
    bne loopd2

loop_couleur: 
    lda #>screencolor
    sta zp_scr+1
    sty zp_scr

loopd2:
    inc zp_data
    bne loopd3
    inc zp_data+1

loopd3:
    jsr draw

wait_tempo:
    lda nb_tempo
    bne wait_tempo
    inc i_tempo
    ldx i_tempo
rep_tempo:
    lda tempos,x
    cmp #$ff
    bne ok_tempo
    tax
    inx
    stx i_tempo
    jmp rep_tempo
ok_tempo:
    sta nb_tempo
    jmp loopd1

;-- tempos pour 200 frames d'animation

tempos:
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
	.byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5

;---------------------------------------------------------
; Explosion
;---------------------------------------------------------

* = $b200
explosion:

    ;--  charset $2800
    lda #$18
    sta $d018

big_loop:
    ;-- was 63
    ldx #47
    lda #1
    sta all_done
loop_plot:
    lda pos_pixels,x 
    cmp #128
    beq suite
    lda #0
    sta all_done
    jsr plot_one
    inc pos_pixels,x

suite:
    dex
    bne loop_plot

    lda all_done
    beq big_loop

;---------------------------------------------------------
; fin_expl : apparition logo Babygang
;---------------------------------------------------------

fin_expl:
	;-- wait new frame
	bit $d011
    bpl *-3
    bit $d011
    bmi *-3

	;-- blank screen before irq to prevent garbage
	lda #0
	sta $d011

	;-- vic bank $c000
	;lda $dd00
	;and #%11111100
    lda #0
	sta $dd00

	;-- hires multicolor mode
	lda #%11011000
	sta $d016

	; E000-FF3F : hires (+ $2000)
	; D000-E000 : charmem (+ $1000) : unused
	; C000-C400 : screenmem (+ $0)
	; C400-C800 : colors

	;-- screen mem $c000, char mem $d000
	lda #%00001000
	sta $d018

	lda #0
	sta $d020
	lda #$0b
	sta $d021

	ldx #0
transfert_col:
	lda COLOR,x
	sta $D800,x
	lda COLOR+$100,x
	sta $D900,x
	lda COLOR+$200,x
	sta $DA00,x
	lda COLOR+$300,x
	sta $DB00,x
	inx
	bne transfert_col

	lda #0
	sta pos_fld

	sei
	lda #0
	sta $d012
	lda #<irqZikFld
	sta $0314
	lda #>irqZikFld
	sta $0315
    cli

    ;-- sprites

    lda #255
    sta $d015
    sta $d01c
    lda #1
    sta $d025
    lda #5
    sta $d026

    ldx #7
aff_sprites_ptr
    lda #16
    sta $c3f8,x
    lda #13
    sta $d027,x
    dex
    bpl aff_sprites_ptr

    ldx #15
    lda #0
aff_sprites
    sta $d000,x
    dex
    bpl aff_sprites

    ;-- Start load part 2

    ldx #0
mv_bootstrap
    lda bootstrap_part2,x
    sta dest_bootstrap_part2,x
    inx
    bne mv_bootstrap    
    jmp dest_bootstrap_part2

pos_sprites
    .byte  0,0,8,8,16,16,24,24,32,32,40,40,48,48,56,56

irqFld:
	ldx pos_fld
	lda sinwave,x
    beq finito_fld
;	beq suite_fld
	tax
debut_fld:
	lda $d012
wait_fld:
	cmp $d012
	beq wait_fld
	cmp #250
	beq stop_fld
	lda $d011
	clc
	adc #1
	and #7
	adc #$38
	sta $d011
	dex
	bne debut_fld

    lda #$0b
    sta $d021

	lda pos_fld
	bmi finito_fld
	inc pos_fld
suite_fld:
	clc
	lda $d012
	adc #66
	bcs stop_fld
wait_bitmap2:
	cmp $d012
	bne wait_bitmap2
stop_fld:
	ldx #$0
	stx $d021
	lda #0
	sta $d012
	lda #<irqZikFld
	sta $0314
	lda #>irqZikFld
	sta $0315
    asl $d019
	jmp $ea81
finito_fld
    .next_raster_irq irqZikNoFld, 245

irqZikFld
	asl $d019
	jsr play_zik
	lda #$0b
	sta $d021
	
	lda #$30
	sta $d012
	lda #<irqFld
	sta $0314
	lda #>irqFld
	sta $0315
	lda #$3b
	sta $d011
	jmp $ea81

irqZikNoFld
    lda $d012
    cmp #249
    bne irqZikNoFld

    lda $d011
    and #$f7
    sta $d011
    lda #255
wait_border
    cmp $d012
    bne wait_border
    lda $d011
    ora #8
    sta $d011
    jsr play_zik
    lda #$0b
    sta $d021
    .next_raster_irq irqTopNoFld, 66+50

irqTopNoFld
    lda #0
    sta $d021

    ;-- affiche les sprites

    ldy #0
irq_sprites
    ldx pos_sprites,y
    lda lut_sprites,x
    sta $d000,y
    lda lut_sprites+$100,x
    sta $d001,y
    iny
    iny
    cpy #$10
    bne irq_sprites

    ldy #7
maj_ptr_spr
    ldx pos_sprites,y
    lda spritemem,x
    sta $c3f8,y
    dey
    bpl maj_ptr_spr

    ldx #15
majx
    inc pos_sprites,x
    dex
    bpl majx

    lda fin_intro
    cmp #1
    bne suiteLoadEnCours
    dec deczik2
    bne suiteLoadEnCours
    lda #15
    sta deczik2
    ldx deczik
    lda volzik,x
    cmp #$ff
    beq fin2intro
    jsr ctrl_zik
    inc deczik
    jmp suiteLoadEnCours
fin2intro
    lda #2
    sta fin_intro
    lda #0
    sta $d015
suiteLoadEnCours
    .next_raster_irq irqZikNoFld, 245

deczik
    .byte 0
deczik2
    .byte 15
volzik
    .byte 15,15,15,15,15,14,14,14,14,13,13,13,12,12,12,11,11
    .byte 10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0,0,255
pos_fld:
	.byte 0

all_done:
    .byte 1

; plot one

plot_one:
    ; recupere la position pour le pixel en cours dans Y
    ; et le rayon associe a la position dans A
    stx zp+2
    ldy pos_pixels,x
    lda lut_rayon,y
    sty zp+4
    ; sauve le rayon dans multiplier et rayon/2 dans zp+3
    sta multiplier
    lsr a
    sta zp+3
    ; calcule rayon * cos(x)
    lda pos_rot,x 
    tay
    sta zp
    lda cos_lut,y 
    sta multiplicand
    jsr multiply
    ; ajoute 20 - rayon/2
    clc
    adc #20
    sbc zp+3
    cmp #40
    bcs no_plot
    ; stocke le resultat pour X dans zp
    ldy zp
    sta zp
    lda sin_lut,y
    sta multiplicand
    jsr multiply
    clc
    adc #13
    sbc zp+3
    cmp #25
    bcs no_plot
    tax
    ldy zp
    lda posYL_screen,x 
    sta zp
    lda posYH_screen,x 
    sta zp+1

    lda $d012
    eor $dc04
    sbc $dc05

    sta (zp),y
    clc
    lda #$d4
    adc zp+1
    sta zp+1
    ldx zp+4
    lda lut_color,x
    sta (zp),y

no_plot:
    ldx zp+2
    rts

; fast multiply 



multiply:

    lda #>square_hi
    sta mod2+2
    
    clc
    lda multiplicand
    adc multiplier
    bcc skip_inc
    
    inc mod2+2
    
skip_inc:
    tax

    sec
    lda multiplicand
    sbc multiplier    
    bcs no_diff_fix
    
    sec
    lda multiplier
    sbc multiplicand
    
no_diff_fix:
    tay

    sec
mod2:
    lda square_hi, x
    sbc square_hi, y
    rts

* = $0e00
square_hi:

;squares 0...510 high bytes
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 0 , 0 , 0
.byte  0 , 0 , 1 , 1 , 1
.byte  1 , 1 , 1 , 1 , 1
.byte  1 , 1 , 1 , 1 , 1
.byte  1 , 2 , 2 , 2 , 2
.byte  2 , 2 , 2 , 2 , 2
.byte  2 , 3 , 3 , 3 , 3
.byte  3 , 3 , 3 , 3 , 4
.byte  4 , 4 , 4 , 4 , 4
.byte  4 , 4 , 5 , 5 , 5
.byte  5 , 5 , 5 , 5 , 6
.byte  6 , 6 , 6 , 6 , 6
.byte  7 , 7 , 7 , 7 , 7
.byte  7 , 8 , 8 , 8 , 8
.byte  8 , 9 , 9 , 9 , 9
;***************************

.byte  9 , 9 , 10 , 10 , 10
.byte  10 , 10 , 11 , 11 , 11
.byte  11 , 12 , 12 , 12 , 12
.byte  12 , 13 , 13 , 13 , 13
.byte  14 , 14 , 14 , 14 , 15
.byte  15 , 15 , 15 , 16 , 16
.byte  16 , 16 , 17 , 17 , 17
.byte  17 , 18 , 18 , 18 , 18
.byte  19 , 19 , 19 , 19 , 20
.byte  20 , 20 , 21 , 21 , 21
.byte  21 , 22 , 22 , 22 , 23
.byte  23 , 23 , 24 , 24 , 24
.byte  25 , 25 , 25 , 25 , 26
.byte  26 , 26 , 27 , 27 , 27
.byte  28 , 28 , 28 , 29 , 29
.byte  29 , 30 , 30 , 30 , 31
.byte  31 , 31 , 32 , 32 , 33
.byte  33 , 33 , 34 , 34 , 34
.byte  35 , 35 , 36 , 36 , 36
.byte  37 , 37 , 37 , 38 , 38
;***************************

.byte  39 , 39 , 39 , 40 , 40
.byte  41 , 41 , 41 , 42 , 42
.byte  43 , 43 , 43 , 44 , 44
.byte  45 , 45 , 45 , 46 , 46
.byte  47 , 47 , 48 , 48 , 49
.byte  49 , 49 , 50 , 50 , 51
.byte  51 , 52 , 52 , 53 , 53
.byte  53 , 54 , 54 , 55 , 55
.byte  56 , 56 , 57 , 57 , 58
.byte  58 , 59 , 59 , 60 , 60
.byte  61 , 61 , 62 , 62 , 63
.byte  63 , 64 , 64 , 65 , 65
.byte  66 , 66 , 67 , 67 , 68
.byte  68 , 69 , 69 , 70 , 70
.byte  71 , 71 , 72 , 72 , 73
.byte  73 , 74 , 74 , 75 , 76
.byte  76 , 77 , 77 , 78 , 78
.byte  79 , 79 , 80 , 81 , 81
.byte  82 , 82 , 83 , 83 , 84
.byte  84 , 85 , 86 , 86 , 87
;***************************

.byte  87 , 88 , 89 , 89 , 90
.byte  90 , 91 , 92 , 92 , 93
.byte  93 , 94 , 95 , 95 , 96
.byte  96 , 97 , 98 , 98 , 99
.byte  100 , 100 , 101 , 101 , 102
.byte  103 , 103 , 104 , 105 , 105
.byte  106 , 106 , 107 , 108 , 108
.byte  109 , 110 , 110 , 111 , 112
.byte  112 , 113 , 114 , 114 , 115
.byte  116 , 116 , 117 , 118 , 118
.byte  119 , 120 , 121 , 121 , 122
.byte  123 , 123 , 124 , 125 , 125
.byte  126 , 127 , 127 , 128 , 129
.byte  130 , 130 , 131 , 132 , 132
.byte  133 , 134 , 135 , 135 , 136
.byte  137 , 138 , 138 , 139 , 140
.byte  141 , 141 , 142 , 143 , 144
.byte  144 , 145 , 146 , 147 , 147
.byte  148 , 149 , 150 , 150 , 151
.byte  152 , 153 , 153 , 154 , 155
;***************************

.byte  156 , 157 , 157 , 158 , 159
.byte  160 , 160 , 161 , 162 , 163
.byte  164 , 164 , 165 , 166 , 167
.byte  168 , 169 , 169 , 170 , 171
.byte  172 , 173 , 173 , 174 , 175
.byte  176 , 177 , 178 , 178 , 179
.byte  180 , 181 , 182 , 183 , 183
.byte  184 , 185 , 186 , 187 , 188
.byte  189 , 189 , 190 , 191 , 192
.byte  193 , 194 , 195 , 196 , 196
.byte  197 , 198 , 199 , 200 , 201
.byte  202 , 203 , 203 , 204 , 205
.byte  206 , 207 , 208 , 209 , 210
.byte  211 , 212 , 212 , 213 , 214
.byte  215 , 216 , 217 , 218 , 219
.byte  220 , 221 , 222 , 223 , 224
.byte  225 , 225 , 226 , 227 , 228
.byte  229 , 230 , 231 , 232 , 233
.byte  234 , 235 , 236 , 237 , 238
.byte  239 , 240 , 241 , 242 , 243
;***************************

.byte  244 , 245 , 246 , 247 , 248
.byte  249 , 250 , 251 , 252 , 253
.byte  254 

* = $2000
.binary "charc.prg",2

* = $2800
.binary "install2800.prg",2

* = $4300
.binary "animp2.bin"

* = $a800
lut_sprites
.binary "sinsprites.prg",2

* = $ab00
.binary "counter2.prg",2

* = $c000
.binary "bygp1b_scr.bin"
* = $c400
.binary "sprites.prg",2
* = $C800
.binary "bygp1b_col.bin"

* = $cc00
spritemem
.binary "spritemem.bin"
sinwave:
.binary "sinwave.prg",2

* = $ce00
.binary "loaderCE00.prg",2

* = $E000
.binary "bygp1b_gfx.bin"

* = $1700
sin_lut:

.byte 127,130,133,136,139,143,146,149,152
.byte 155,158,161,164,167,170,173,176
.byte 179,182,184,187,190,193,195,198
.byte 200,203,205,208,210,213,215,217
.byte 219,221,224,226,228,229,231,233
.byte 235,236,238,239,241,242,244,245
.byte 246,247,248,249,250,251,251,252
.byte 253,253,254,254,254,254,254,255
.byte 254,254,254,254,254,253,253,252
.byte 251,251,250,249,248,247,246,245
.byte 244,242,241,239,238,236,235,233
.byte 231,229,228,226,224,221,219,217
.byte 215,213,210,208,205,203,200,198
.byte 195,193,190,187,184,182,179,176
.byte 173,170,167,164,161,158,155,152
.byte 149,146,143,139,136,133,130,127
.byte 124,121,118,115,111,108,105,102
.byte 99,96,93,90,87,84,81,78
.byte 75,72,70,67,64,61,59,56
.byte 54,51,49,46,44,41,39,37
.byte 35,33,30,28,26,25,23,21
.byte 19,18,16,15,13,12,10,9
.byte 8,7,6,5,4,3,3,2
.byte 1,1,0,0,0,0,0,0
.byte 0,0,0,0,0,1,1,2
.byte 3,3,4,5,6,7,8,9
.byte 10,12,13,15,16,18,19,21
.byte 23,25,26,28,30,33,35,37
.byte 39,41,44,46,49,51,54,56
.byte 59,61,64,67,70,72,75,78
.byte 81,84,87,90,93,96,99,102
.byte 105,108,111,115,118,121,121
cos_lut:

.byte 255,254,254,254,254,254,253,253,252
.byte 251,251,250,249,248,247,246,245
.byte 244,242,241,239,238,236,235,233
.byte 231,229,228,226,224,221,219,217
.byte 215,213,210,208,205,203,200,198
.byte 195,193,190,187,184,182,179,176
.byte 173,170,167,164,161,158,155,152
.byte 149,146,143,139,136,133,130,127
.byte 124,121,118,115,111,108,105,102
.byte 99,96,93,90,87,84,81,78
.byte 75,72,70,67,64,61,59,56
.byte 54,51,49,46,44,41,39,37
.byte 35,33,30,28,26,25,23,21
.byte 19,18,16,15,13,12,10,9
.byte 8,7,6,5,4,3,3,2
.byte 1,1,0,0,0,0,0,0
.byte 0,0,0,0,0,1,1,2
.byte 3,3,4,5,6,7,8,9
.byte 10,12,13,15,16,18,19,21
.byte 23,25,26,28,30,33,35,37
.byte 39,41,44,46,49,51,54,56
.byte 59,61,64,67,70,72,75,78
.byte 81,84,87,90,93,96,99,102
.byte 105,108,111,115,118,121,124,127
.byte 130,133,136,139,143,146,149,152
.byte 155,158,161,164,167,170,173,176
.byte 179,182,184,187,190,193,195,198
.byte 200,203,205,208,210,213,215,217
.byte 219,221,224,226,228,229,231,233
.byte 235,236,238,239,241,242,244,245
.byte 246,247,248,249,250,251,251,252
.byte 253,253,254,254,254,254,254

pos_pixels:
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0

pos_rot:
.byte 30,8,16,32,64,96,128,200
.byte 220,3,231,47,253,190,48,32
.byte 67,89,116,23,175,142,98,29
.byte 201,132,74,54,99,167,184,12
.byte 23,18,36,132,46,69,212,20
.byte 182,37,131,74,235,129,84,202
.byte 79,98,161,37,157,124,95,90
.byte 120,213,198,45,9,176,144,152
.byte 30,8,16,32,64,96,128,200
.byte 220,3,231,47,253,190,48,32
.byte 67,89,116,23,175,142,98,29
.byte 201,132,74,54,99,167,184,12
.byte 23,18,36,132,46,69,212,20
.byte 182,37,131,74,235,129,84,202
.byte 79,98,161,37,157,124,95,90
.byte 120,213,198,45,9,176,144,152

lut_rayon:
.byte 0,0,0,1,1,1,2,2
.byte 3,3,4,5,6,7,8,9
.byte 6,7,9,10,12,14,15,16
.byte 17,19,21,23,24,25,27,29
.byte 30,31,32,34,35,37,38,39
.byte 40,42,43,44,45,46,47,50
.byte 30,31,32,34,35,37,38,39
.byte 40,42,43,44,45,46,47,50
.byte 0,0,0,1,1,1,2,2
.byte 3,3,4,5,6,7,8,9
.byte 6,7,9,10,12,14,15,16
.byte 17,19,21,23,24,25,27,29
.byte 30,31,32,34,35,37,38,39
.byte 40,42,43,44,45,46,47,50
.byte 30,31,32,34,35,37,38,39
.byte 40,42,43,44,45,46,47,50

lut_color:
.byte 1,1,2,7,1,7,1,15
.byte 2,2,2,7,2,7,2,15
.byte 15,1,15,2,7,15,12,12
.byte 11,12,12,11,11,11,11,0
.byte 1,1,2,7,1,15,1,15
.byte 2,7,15,11,12,11,15,11
.byte 15,1,15,12,12,15,12,12
.byte 11,12,12,11,11,11,11,0

.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0
.byte 0,0,0,0,0,0,0,0

posYL_screen:

.byte 0,40,80,120,160,200,240
.byte 24,64,104,144,184,224
.byte 8,48,88,128,168,208,248
.byte 32,72,112,152,192

posYH_screen:

.byte 4,4,4,4,4,4,4
.byte 5,5,5,5,5,5
.byte 6,6,6,6,6,6,6
.byte 7,7,7,7,7
fin_luts
.warn repr(fin_luts)

;---------------------------------------------------------
; next_raster_irq
;   setup nouvel IRQ raster et retour IRQ
;   Address, rasterline
;---------------------------------------------------------

next_raster_irq .macro adr, y=49
    lda #\y
    sta $d012
    lda #<\adr
    sta $0314
    lda #>\adr
    sta $0315
    .end_raster_irq
    .endm

;---------------------------------------------------------
; end_raster_irq
;   retour IRQ raster
;---------------------------------------------------------

end_raster_irq .macro
    asl $d019
    jmp $ea81
    .endm

* = bootstrap_part2
    ;-- Fin de l'intro, chargement de la part 2 en $2801+
    ;-- déplacement mémoire et démarrage exomizer 2061
    ;-- déplacement de 2800 à 6800 vers 0800
    lda #0
    sta $d020
    inc filename+1
    ldx #<filename
    ldy #>filename
    jsr loadcompd
    bcc load_ok
    jmp $fce2
load_ok
    lda #1
    sta fin_intro
wait_fin_intro
    lda fin_intro
    cmp #2
    bne wait_fin_intro
    sei
launch_p2
    lda #0
    sta $d020
    ; was 55
    lda #%0001110
    sta $01
    lda #0
    sta $d01a    
    lda #$81
    sta $0314
    lda #$ea
    sta $0315
    cli
    jmp $6c00

fin_intro
    .byte 0
