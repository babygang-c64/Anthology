;=========================================================
; [Babygang] Anthology 1988-2022, Part 4 - end part
;---------------------------------------------------------
; map : 
; 
; $1000-$22B6 : musique
; $4000-$6000 : bitmap
; $6000-$6800 : charset
; $6800-$6c00 : screen avec 1 version du logo
; $6c00-$7000 : color
;
; écran : 
; 8 lignes logo (raster 50 à 114)
; 17 lignes image / scroll (raster 115 à 250)
;=========================================================

zik_init = $1000
zik_play = $1006

* = $1000
	.binary 'zikend.prg',2

* = $2300

	sei
	lda #55
	sta $01
	lda #1
	jsr zik_init
	jsr scr_init
	.setup_raster_irq irq_ziq,y=250

endloop
	jmp endloop

;---------------------------------------------------------
; scr_init : initialise les valeurs pour l'affichage
;---------------------------------------------------------

scr_init
	ldx #0
	stx $d011
	stx $d020
	stx $d021
scr_init_color
	lda scr_color,x
	sta $d800,x
	lda scr_color+$0100,x
	sta $d900,x
	lda scr_color+$0200,x
	sta $da00,x
	lda scr_color+$0300,x
	sta $db00,x
	inx
	bne scr_init_color

	lda $d012
	cmp #250
	bmi scr_init

	;-- vic bank #1 = $4000
	lda #%10
	sta $dd00

	;-- hires, multicolor
	lda #$3b
	sta $d011
	lda #%11011000
	sta $d016

	;-- screen $6800, charset $6000, bitmap $4000
	lda #%10100000
	sta $d018
	rts

;---------------------------------------------------------
; IRQ musique et gestion de l'avancement dans la part
;---------------------------------------------------------

irq_ziq
	lda #1
	sta $d020
	lda #0
	sta $d021
	lda #%11011000
	sta $d016

	jsr zik_play

	;-- hires multicolor pour le logo en haut de page
	lda #$3b
	sta $d011
	lda #%11011000
	sta $d016
	lda #%10100000
	sta $d018

	;-- enchainement des actions
	jsr next_action_irq
	.next_raster_irq irq_split_up, 49

couleur_fond
	.byte 0

irq_split_up
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda #11
	sta $d020
	.next_raster_irq irq_split, 114

irq_split
	ldx #1
	stx $d021
	lda #115
-
	cmp $d012
	bne - 
	stx $d020

update_d011
	lda #$3b
	sta $d011
update_d016
	lda #%11011000
	sta $d016
update_d018
	lda #%10100000
	sta $d018
	.next_raster_irq irq_text1, 122

irq_text1
update_scroll1
	lda #%11010000
	sta $d016
	.next_raster_irq irq_text2, 122+32

irq_text2
update_scroll2
	lda #%11010000
	sta $d016
	.next_raster_irq irq_text3, 122+32*2

irq_text3
update_scroll3
	lda #%11010000
	sta $d016
	.next_raster_irq irq_text4, 122+32*3

irq_text4
update_scroll4
	lda #%11010000
	sta $d016
	.next_raster_irq irq_ziq, 251

;---------------------------------------------------------
; Données pour avancement dans la part
; 
; fin : fin de la part, stoppe les actions
; wait <n> : attends <n> frames
; logo_flash : flash de couleur du logo, effet neon
;---------------------------------------------------------

	.align $100

action = {.end:0, .logo_flash:1, .wait:3, .nop:2, .logo_morph:4, .logo_nb:5, .textmode:6, .fadeout:7, .clearhirescolors:8, .initwrite:9, .write1:10, .write2:11, .write3:12, .write4:13, .scroll:14, .scrollParams:15, .flashText:16, .scrollAll:17, .scrollAllBis:18, .clear:19, .freeze:20}

nb_params
	.byte 0,0,0,1,0
	.byte 0,0,0,0,0
	.byte 1,1,1,1,1
	.byte 2,2,0,0,2
	.byte 0

; scroll params :
; bits 0,1 : ligne de scroll
; bits 2,3 : lut sinus
; bit 4 : vitesse 1 ou 2
; 2nd paramètre = position de départ scroll
; sinusR1 : 0 = gauche à droite saccadé
; sinusR2 : 1 = droite à gauche saccadé
; sinusR3 : 2 = gauche à droite fluide
; sinusR4 : 3 = droite à gauche fluide

params = {.ligne1:0, .ligne2:1, .ligne3:2, .ligne4:3, .sinusR1:0, .vitesse1:0, .vitesse2:16, .sinusR2:4, .sinusR3:8, .sinusR4:12}

action_jmp
	jmp do_action_end
	jmp do_action_logo_flash
	jmp do_action_nop
	jmp do_action_wait
	jmp do_action_logo_morph
	jmp do_logo_nb
	jmp do_textmode
	jmp do_action_fadeout
	jmp do_clear_hires_colors
	jmp init_write
	jmp write_texte1
	jmp write_texte2
	jmp write_texte3
	jmp write_texte4
	jmp do_scroll_right
	jmp do_scroll_params
	jmp do_flash_text
	jmp do_scroll_all
	jmp do_scroll_all_bis
	jmp do_clear_text
-
	jmp -

drive_part
	.byte action.nop

	.byte action.fadeout, action.clearhirescolors
	.byte action.textmode, action.initwrite

	.byte action.write1, 40
	.byte action.write2, 40, action.write2, 80
	.byte action.write2, 120, action.write2, 160
	.byte action.scrollParams, params.ligne1+params.sinusR3+params.vitesse1, 0
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 0
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 120
	.byte action.scroll, 1
	.byte action.write3, 40, action.write3, 80
	.byte action.write3, 120, action.write3, 160
	.byte action.write2, 200

	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 0
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 160
	.byte action.scroll, 1
	.byte action.write2, 120
	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne2+params.sinusR4+params.vitesse2, 160
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 2

	.byte action.end

	;.byte action.end

	;-- scrolls credits OK

	.byte action.write1, 40, action.write1, 80
	.byte action.write2, 40
	.byte action.write3, 40
	.byte action.write4, 40

	;-- affichage ligne intro en 2 fois, gauche / droite
	.byte action.scrollParams, params.ligne1+params.sinusR1+params.vitesse1, 0
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne1+params.sinusR3+params.vitesse1, 40
	;-- droite / gauche, suite du texte
	.byte action.scrollParams, params.ligne2+params.sinusR2+params.vitesse1, 80
	.byte action.scrollAll

	;-- gauche droite, fin du texte
	.byte action.scrollParams, params.ligne3+params.sinusR1+params.vitesse1, 0
	;-- here we go ligne 4, vitesse x2 et disparition
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 0
	.byte action.scroll, 3
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 3
	;.byte action.scrollParams, params.ligne1+params.sinusR2+params.vitesse2, 40
	;.byte action.scrollParams, params.ligne1+params.sinusR4+params.vitesse2, 0
	;.byte action.scrollAll
	;.byte action.freeze

	;-- page 2, credits intro

	.byte action.write1, 120
	.byte action.write2, 80
	.byte action.write3, 80
	.byte action.write4, 120
	.byte action.scrollParams, params.ligne1+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 3

	;-- loader by krill

	.byte action.write1, 80
	.byte action.write2, 40
	.byte action.write3, 40
	.byte action.write4, 80
	.byte action.scrollParams, params.ligne1+params.sinusR2+params.vitesse2, 120
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR2+params.vitesse2, 80
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR2+params.vitesse2, 80
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR2+params.vitesse2, 120
	.byte action.scroll, 3

	;-- page 3, credits part 2 vignettes

	.byte action.write1, 120
	.byte action.write2, 80
	.byte action.write3, 80
	.byte action.write4, 120
	.byte action.scrollParams, params.ligne1+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 3

	;-- credits part 3 plotter

	.byte action.write1, 80
	.byte action.write2, 40
	.byte action.write3, 40
	.byte action.write4, 80
	.byte action.scrollParams, params.ligne1+params.sinusR4+params.vitesse2, 120
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR4+params.vitesse2, 120
	.byte action.scroll, 3

	;-- page 4, credits endpart

	.byte action.write1, 120
	.byte action.write2, 80
	.byte action.write3, 80
	.byte action.write4, 120
	.byte action.scrollParams, params.ligne1+params.sinusR1+params.vitesse1, 80
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 80
	.byte action.scroll, 3

	;-- the artists

	.byte action.write1, 80
	.byte action.write2, 40
	.byte action.write3, 40
	.byte action.write4, 80
	.byte action.scrollParams, params.ligne1+params.sinusR4+params.vitesse2, 120
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 2
	.byte action.scrollParams, params.ligne4+params.sinusR4+params.vitesse2, 120
	.byte action.scroll, 3

	.byte action.end
	;.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 40
	;.byte action.scroll, 3

	.byte action.logo_flash, action.logo_flash, action.logo_flash
	.byte action.end

	.byte action.nop, action.wait, 200, action.logo_flash
	.byte action.wait, 50, action.logo_flash
	.byte action.wait, 50, action.logo_nb
	.byte action.logo_morph
	.byte action.logo_flash, action.logo_flash
	.byte action.wait, 200, action.fadeout, action.logo_flash
	.byte action.clearhirescolors, action.textmode
	.byte action.initwrite
	.byte action.write1, 40, action.write1, 80
	.byte action.write2, 40
	.byte action.write3, 40
	.byte action.write4, 40
	;-- affichage ligne intro en 2 fois, gauche / droite
	.byte action.scrollParams, params.ligne1+params.sinusR1+params.vitesse1, 0
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne1+params.sinusR3+params.vitesse1, 40
	.byte action.scroll, 0
	;-- droite / gauche, suite du texte
	.byte action.scrollParams, params.ligne2+params.sinusR2+params.vitesse1, 80
	.byte action.scroll, 1
	;-- gauche droite, fin du texte
	.byte action.scrollParams, params.ligne3+params.sinusR1+params.vitesse1, 0
	.byte action.scroll, 2
	;-- here we go ligne 4, vitesse x2 et disparition
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 0
	.byte action.scroll, 3
	.byte action.scrollParams, params.ligne4+params.sinusR3+params.vitesse2, 40
	.byte action.scroll, 3
	;-- credits part 1
	.byte action.write4, 40
	.byte action.write1, 40
	.byte action.write2, 0
	.byte action.write3, 0
	.byte action.scrollParams, params.ligne4+params.sinusR4+params.vitesse2, 80
	;.byte action.scroll, 3
	.byte action.scrollParams, params.ligne3+params.sinusR4+params.vitesse1, 40
	;.byte action.scroll, 2
	;.byte action.flashText, 16, 18
	.byte action.scrollParams, params.ligne2+params.sinusR4+params.vitesse1, 40
	;.byte action.scroll, 1
	;.byte action.flashText, 18, 12
	.byte action.scrollParams, params.ligne1+params.sinusR4+params.vitesse1, 80
	.byte action.scroll, 0
	;.byte action.freeze
	.byte action.scrollAll
	.byte action.scrollAllBis
	;.byte action.flashText, 28, 10
	.byte action.end
	;-- disparition ligne credits
	.byte action.scrollParams, params.ligne4+params.sinusR4+params.vitesse2, 40
	.byte action.scroll, 3
	.byte action.write1, 40
	.byte action.write2, 0
	.byte action.write3, 0
	.byte action.scrollParams, params.ligne1+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 0
	.byte action.scrollParams, params.ligne2+params.sinusR4+params.vitesse2, 80
	.byte action.scroll, 1
	.byte action.scrollParams, params.ligne3+params.sinusR2+params.vitesse2, 80
	.byte action.scroll, 2

	.byte action.end

action_item
	.byte action.nop

;-- paramètres des actions

.warn repr(action_nb_params)
action_nb_params
	.byte 0

action_param
	.byte 0
action_param2
	.byte 0
	.byte 0,0,0,0,0,0

action_all_done
	.byte 0

pc_part
	lda drive_part
	rts

;---------------------------------------------------------
; next_action_irq : réalise l'action définie (IRQ part)
;---------------------------------------------------------

next_action_irq
	lda #>action_jmp
	sta jmp_action+2
	clc
	lda #<action_jmp
	adc action_item
	adc action_item
	adc action_item	
	sta jmp_action+1
	bcc jmp_action
	inc jmp_action+2
jmp_action
	jsr action_jmp
	bcs retrieve_next_action_irq
	rts

retrieve_next_action_irq
	inc pc_part+1
	bne +
	inc pc_part+2
+
	jsr pc_part
	sta action_item

	;-- nb parametres
	tay
	ldx nb_params,y
	stx action_nb_params
	cpx #0
	beq fin_params
	ldy #0

action_avec_param
	inc pc_part+1
	bne +
	inc pc_part+2
+
	jsr pc_part
	sta action_param,y
	iny
	dex
	bne action_avec_param
fin_params
	rts

;---------------------------------------------------------
; clear : efface zone texte, params ligne + debut
;---------------------------------------------------------

do_clear_text
	ldx action_param

	lda pos_src1L,x
	sta majclrsrc1+1
	lda pos_src1H,x
	sta majclrsrc1+2

	lda pos_src2L,x
	sta majclrsrc2+1
	lda pos_src2H,x
	sta majclrsrc2+2

	ldy action_param2
	ldx #40
	lda #128	
majclrsrc1
	sta ztexte1a,y
majclrsrc2
	sta ztexte1b,y
	iny
	dex
	bne majclrsrc1

	sec
	rts

;---------------------------------------------------------
; scroll all
;---------------------------------------------------------

scroll_all_tout_fini
	.byte 0
scroll_all_ligne
	.byte 0

do_scroll_all
	ldx #0
	stx scroll_all_tout_fini
do_scrolls
	stx scroll_all_ligne
	stx action_param
	lda param_sinwave,x
	jsr params_scroll_sinwave

	ldx scroll_all_ligne
	jsr params_scroll_screen

	jsr do_scroll_right
	bcs +
	inc scroll_all_tout_fini
+
	ldx scroll_all_ligne
	inx
	cpx #2
	bne do_scrolls
	lda scroll_all_tout_fini
	cmp #0
	beq +
	clc
	rts
+
	sec
	rts

do_scroll_all_bis
	ldx #0
	stx scroll_all_tout_fini
	ldx #2
do_scrolls_bis
	stx scroll_all_ligne
	stx action_param
	lda param_sinwave,x
	jsr params_scroll_sinwave

	ldx scroll_all_ligne
	jsr params_scroll_screen

	jsr do_scroll_right
	bcs +
	inc scroll_all_tout_fini
+
	ldx scroll_all_ligne
	inx
	cpx #4
	bne do_scrolls_bis
	lda scroll_all_tout_fini
	cmp #0
	beq +
	clc
	rts
+
	sec
	rts

;---------------------------------------------------------
; action flash text
;---------------------------------------------------------

flash_colors
	.byte 11, 0, 11, 12, 12, 13, 13, 5, 5, 1
	.byte 5, 5, 13, 13, 12, 12, 11, 255

pos_flash_colors
	.byte 0 

do_flash_text
	ldx ligne_scroll

	lda pos_dest1L,x
	sta maj_flash1+1
	lda pos_dest1H,x
	clc
	adc #$d8-$68
	sta maj_flash1+2

	lda pos_dest2L,x
	sta maj_flash2+1
	lda pos_dest2H,x
	clc
	adc #$d8-$68
	sta maj_flash2+2

	ldx pos_flash_colors
	lda flash_colors,x
	cmp #$ff
	beq fin_flash_colors
	sta maj_colors+1

	ldy action_param
	ldx action_param2
	
maj_colors
	lda #0
maj_flash1
	sta $6800,y
maj_flash2
	sta $6800+40,y
	iny
	dex
	bne maj_flash1

	inc pos_flash_colors
	clc
	rts

fin_flash_colors
	lda #0
	sta pos_flash_colors
	sec
	rts

;---------------------------------------------------------
; action text mode
;---------------------------------------------------------

do_textmode
	lda #%00010100
	sta update_d011+1
	lda #%11001000
	sta update_d016+1
	lda #%10101000
	sta update_d018+1
	lda #%11000000
	sta update_scroll1+1
	sta update_scroll2+1
	sta update_scroll3+1
	sta update_scroll4+1
	sec
	rts

;---------------------------------------------------------
; action scroll right : param = ligne scroll 0 à 3
;---------------------------------------------------------

.warn repr(pos_scroll_right)

pos_scroll_right
	.byte 0,0,0,0
pos_scroll_speed
	.byte 1,1,1,1
pos_depart_scroll
	.byte 0,0,0,0
param_sinwave
	.byte 0,0,0,0

do_scroll_right

	;;-- tmp
	;ldx action_param
	;stx $8000
	;jsr params_scroll_sinwave
	;jsr params_scroll_screen
	;;-- tmp

	jsr update_scroll
	tax
	ldy action_param
	lda pos_scroll_speed,y
	cmp #2
	bne suite_scroll
	clc
	lda pos_scroll_right,y
	adc #1
	sta pos_scroll_right,y
	jsr update_scroll
	tax

suite_scroll
	ldy #0
-
majsrc1
	lda ztexte1a,x
majdest1
	sta $6800+40*10,y
majsrc2
	lda ztexte1b,x
majdest2
	sta $6800+40*11,y
	inx
	iny
	cpy #40
	bne -

	clc
	ldy action_param
	lda pos_scroll_right,y
	adc #1
	sta pos_scroll_right,y
	cmp #0
	beq scroll_fini
	clc
	rts

scroll_fini
	sec
	rts

update_scroll
	ldy action_param
	ldx pos_scroll_right,y
majupdate1
	lda update_scroll1+1
	and #%11111000
majsinL
	ora sinwaveL,x
majupdate2
	sta update_scroll1+1

	clc
majsinH
	lda sinwaveH,x
	ldy action_param
	adc pos_depart_scroll,y
	sta pos_depart_scroll,y
	rts

;---------------------------------------------------------
; action param scroll
;---------------------------------------------------------

ligne_scroll
	.byte 0

do_scroll_params
	lda action_param
	tay
	and #3
	sta ligne_scroll
	tax

	lda action_param2
	sta pos_depart_scroll,x

	;-- update parametres source / dest dans le code
	jsr params_scroll_screen

	;-- vitesse du scroll
	tya
	clc
	and #$10
	ror a
	ror a
	ror a
	ror a
	adc #1
	ldx ligne_scroll
	sta pos_scroll_speed,x

	;-- sinwave
	tya
	clc
	and #%00001100
	ror a
	ror a
	sta param_sinwave,x
	tax

	;-- update parametres lut sinus dans le code
	jsr params_scroll_sinwave

	sec
	rts

params_scroll_sinwave
	lda pos_sinwavesHL,x
	sta majsinH+1
	lda pos_sinwavesHH,x
	sta majsinH+2
	lda pos_sinwavesLL,x
	sta majsinL+1
	lda pos_sinwavesLH,x
	sta majsinL+2
	rts

params_scroll_screen
	lda pos_updatesL,x
	sta majupdate1+1
	sta majupdate2+1

	lda pos_updatesH,x
	sta majupdate1+2
	sta majupdate2+2

	lda pos_src1L,x
	sta majsrc1+1
	lda pos_src1H,x
	sta majsrc1+2

	lda pos_src2L,x
	sta majsrc2+1
	lda pos_src2H,x
	sta majsrc2+2

	lda pos_dest1L,x
	sta majdest1+1
	lda pos_dest1H,x
	sta majdest1+2

	lda pos_dest2L,x
	sta majdest2+1
	lda pos_dest2H,x
	sta majdest2+2
	rts

pos_updatesL
	.byte <update_scroll1+1,<update_scroll2+1
	.byte <update_scroll3+1,<update_scroll4+1
pos_updatesH
	.byte >update_scroll1+1,>update_scroll2+1
	.byte >update_scroll3+1,>update_scroll4+1

pos_src1L
	.byte <ztexte1a,<ztexte2a,<ztexte3a,<ztexte4a
pos_src1H
	.byte >ztexte1a,>ztexte2a,>ztexte3a,>ztexte4a

pos_src2L
	.byte <ztexte1b,<ztexte2b,<ztexte3b,<ztexte4b
pos_src2H
	.byte >ztexte1b,>ztexte2b,>ztexte3b,>ztexte4b

pos_dest1L
	.byte <$6800+40*10,<$6800+40*14,<$6800+40*18,<$6800+40*22
pos_dest1H
	.byte >$6800+40*10,>$6800+40*14,>$6800+40*18,>$6800+40*22

pos_dest2L
	.byte <$6800+40*11,<$6800+40*15,<$6800+40*19,<$6800+40*23
pos_dest2H
	.byte >$6800+40*11,>$6800+40*15,>$6800+40*19,>$6800+40*23

pos_sinwavesHL
	.byte <sinwaveH,<sinwaveHr,<sinwaveHn,<sinwaveHrn
pos_sinwavesHH
	.byte >sinwaveH,>sinwaveHr,>sinwaveHn,>sinwaveHrn

pos_sinwavesLL
	.byte <sinwaveL,<sinwaveLr,<sinwaveLn,<sinwaveLrn
pos_sinwavesLH
	.byte >sinwaveL,>sinwaveLr,>sinwaveLn,>sinwaveLrn

;---------------------------------------------------------
; action clear hires colors
;---------------------------------------------------------

do_clear_hires_colors
	ldx posclearcolors
	cpx #255
	beq +
	ldy xclearcolors,x
	lda hicolors,x
	sta storecolor+2
	lda newcolors,x
storecolor
	sta $d940,y
	dey
	cpy #255
	bne storecolor
	dec posclearcolors
	clc
	rts
+
	sec
	rts

posclearcolors
	.byte 8
xclearcolors
	.byte 255,255,168,255,255,168,255,255,168
newcolors
	.byte 11,11,11,128,128,128,128,128,128
hicolors
	.byte $d9,$da,$db,$69,$6a,$6b,$6d,$6e,$6f

;---------------------------------------------------------
; action nop
;---------------------------------------------------------

do_action_nop
	sec
	rts

;---------------------------------------------------------
; action end
;---------------------------------------------------------

do_action_end
	clc
	lda #1
	sta action_all_done
	rts

;---------------------------------------------------------
; action wait
;---------------------------------------------------------

do_action_wait
	dec action_param
	beq +
	clc
	rts
+	
	sec
	rts

;---------------------------------------------------------
; action logo flash
;---------------------------------------------------------

do_action_logo_flash
	ldx pos_flash_data
	lda flash_data,x
	bmi fin_flash_data
	sta $d021
	inc pos_flash_data
	clc
	rts
fin_flash_data
	lda #0
	sta pos_flash_data
	sec
	rts

flash_data
	.byte 0,0,11,11,12,12,14,6,1,7,7,1,6,14,12,12,11,11,0,0,0,255
pos_flash_data
	.byte 0

;---------------------------------------------------------
; action fadeout
;---------------------------------------------------------

mask_fadeout
	.byte 0,%00000011,%00001111,%00111111

pos_mask_fadeout
	.byte 3

fini_fadeout
	.byte 0

posx_fadeout
	.byte 0

zp_fadeout = $50

do_action_fadeout
	ldx posx_fadeout
	lda hires_low,x
	sta zp_fadeout
	lda hires_high,x
	sta zp_fadeout+1

	ldx pos_mask_fadeout
	lda mask_fadeout,x
	sta do_mask+1

	ldx #17
ligne_fadeout
	ldy #7
-
	lda (zp_fadeout),y
do_mask
	and #$ff
	sta (zp_fadeout),y
	dey
	bpl -
	clc
	lda zp_fadeout
	adc #$40
	sta zp_fadeout
	bcc +
	inc zp_fadeout+1
+
	inc zp_fadeout+1
	dex
	bne ligne_fadeout

	dec pos_mask_fadeout
	lda pos_mask_fadeout
	cmp #255
	bne +

	lda #3
	sta pos_mask_fadeout
	inc posx_fadeout
	lda posx_fadeout
	cmp #40
	beq fin_fadeout
+
	clc
	rts

fin_fadeout
	sec
	rts

hires_low
	.byte $00,$08,$10,$18
	.byte $20,$28,$30,$38
	.byte $40,$48,$50,$58
	.byte $60,$68,$70,$78
	.byte $80,$88,$90,$98

	.byte $A0,$A8,$B0,$B8
	.byte $c0,$c8,$d0,$d8
	.byte $e0,$e8,$f0,$f8
	.byte $00,$08,$10,$18
	.byte $20,$28,$30,$38

hires_high
	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a

	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a
	.byte $4a,$4a,$4a,$4a
	.byte $4b,$4b,$4b,$4b
	.byte $4b,$4b,$4b,$4b

;---------------------------------------------------------
; action logo morph
;---------------------------------------------------------

get_byte_logo_morph
	lda morph_data
	inc get_byte_logo_morph+1
	bne +
	inc get_byte_logo_morph+2
+
	rts

do_action_logo_morph
	ldx #4
boucle_morph
	jsr get_byte_logo_morph
	sta store_morph+1
	jsr get_byte_logo_morph
	cmp #0
	beq morph_fini
	sta store_morph+2
	jsr get_byte_logo_morph
store_morph
	sta $4000
	dex
	bne boucle_morph
	clc
	rts
morph_fini
	sec
	rts

;---------------------------------------------------------
; action logo nb
;---------------------------------------------------------

do_logo_nb
	ldx pos_nb
	lda nb_scr,x
	sta scr_logo,x
	lda nb_col,x
	sta $d800,x

	lda nb_scr+40,x
	sta scr_logo+40,x
	lda nb_col+40,x
	sta $d800+40,x

	lda nb_scr+40*2,x
	sta scr_logo+40*2,x
	lda nb_col+40*2,x
	sta $d800+40*2,x

	lda nb_scr+40*3,x
	sta scr_logo+40*3,x
	lda nb_col+40*3,x
	sta $d800+40*3,x

	lda nb_scr+40*4,x
	sta scr_logo+40*4,x
	lda nb_col+40*4,x
	sta $d800+40*4,x

	lda nb_scr+40*5,x
	sta scr_logo+40*5,x
	lda nb_col+40*5,x
	sta $d800+40*5,x

	lda nb_scr+40*6,x
	sta scr_logo+40*6,x
	lda nb_col+40*6,x
	sta $d800+40*6,x

	lda nb_scr+40*7,x
	sta scr_logo+40*7,x
	lda nb_col+40*7,x
	sta $d800+40*7,x

	inc pos_nb
	lda pos_nb
	cmp #40
	beq +
	clc
	rts
+
	sec
	rts

pos_nb
	.byte 0


;---------------------------------------------------------
; write text
;---------------------------------------------------------

zp_text = $50
zp_dest = $52

init_write
	lda #<scrolltext
	sta zp_text
	lda #>scrolltext
	sta zp_text+1
	sec
	rts

write_texte1
	clc
	lda #<ztexte1a
	adc action_param
	sta zp_dest
	lda #>ztexte1a
	adc #0
	sta zp_dest+1
	jmp write_text

write_texte2
	clc
	lda #<ztexte2a
	adc action_param
	sta zp_dest
	lda #>ztexte2a
	adc #0
	sta zp_dest+1
	jmp write_text

write_texte3
	clc
	lda #<ztexte3a
	adc action_param
	sta zp_dest
	lda #>ztexte3a
	adc #0
	sta zp_dest+1
	jmp write_text

write_texte4
	clc
	lda #<ztexte4a
	adc action_param
	sta zp_dest
	lda #>ztexte4a
	adc #0
	sta zp_dest+1
	jmp write_text

write_text
	ldy #0
	lda (zp_text),y
	beq fin_write
	clc
	rol a
	rol a
	sta (zp_dest),y
	adc #1
	iny
	sta (zp_dest),y
	inc zp_dest+1
	adc #1
	dey
	sta (zp_dest),y
	adc #1
	iny
	sta (zp_dest),y
	dec zp_dest+1
	inc zp_text
	bne +
	inc zp_text+1
+
	inc zp_dest
	bne +
	inc zp_dest+1
+
	inc zp_dest
	bne +
	inc zp_dest+1
+
	jmp write_text
fin_write
	inc zp_text
	bne +
	inc zp_text+1
+
	sec
	rts

;---------------------------------------------------------
; setup_raster_irq
;	A,X : < and > irq address
; 	Y : raster line for irq
;---------------------------------------------------------

setup_raster_irq .macro adr, y=49

	sei
	lda #<\adr
	sta $0314
	lda #>\adr
	sta $0315
	lda #\y
	sta $d012

	;-- init IRQ
    lda #$7f
    sta $dc0d
    sta $dd0d
;    lda #$1b
;    sta $d011
    lda #$01
    sta $d01a
    lda $dc0d
    lda $dd0d
	cli
	.endm

;---------------------------------------------------------
; next_raster_irq
;	setup nouvel IRQ raster et retour IRQ
;	Address, rasterline
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
; setup_next_raster_irq
;	setup nouvel IRQ raster et retour normal
;	Address, rasterline
;---------------------------------------------------------

setup_next_raster_irq .macro adr, y=49
	lda #\y
	sta $d012
	lda #<\adr
	sta $0314
	lda #>\adr
	sta $0315
	rts
	.endm

;---------------------------------------------------------
; end_raster_irq
;	retour IRQ raster
;---------------------------------------------------------

end_raster_irq .macro
	asl $d019
	jmp $ea81
	.endm

;---------------------------------------------------------
; morph_data
;---------------------------------------------------------

;* = $8000
morph_data
	.binary "gen_morph.bin"

	.align $100
nb_scr
	.binary "nb_scr.bin"
	.align $100
nb_col
	.binary "nb_col.bin"

;---------------------------------------------------------
; zones pour scrolls texte
;---------------------------------------------------------
	
	.align $100

.warn repr(ztexte1a)
ztexte1a
	.fill 256,128
ztexte1b
	.fill 256,128

ztexte2a
	.fill 256,128
ztexte2b
	.fill 256,128

ztexte3a
	.fill 256,128
ztexte3b
	.fill 256,128

ztexte4a
	.fill 256,128
ztexte4b
	.fill 256,128

;---------------------------------------------------------
; GFX data
;
; $4000 : GFX logo + papys
; $6800 : screen
; $6c00 : color
;---------------------------------------------------------

* = $4000
	.binary "part4_gfx.bin"

* = $6000
	.binary "fontp4.prg",2

* = $6800
scr_logo
screen0
	.binary "part4_scr.bin"

* = $6c00
scr_color
screen1
	.binary "part4_col.bin"

* = $7000
sinwaveH
	.binary "sinwave4.bin"
sinwaveL = sinwaveH+$100

sinwaveHr
	.binary "sinwave4r.bin"
sinwaveLr = sinwaveHr+$100

sinwaveHn
	.binary "sinwave4n.bin"
sinwaveLn = sinwaveHn+$100

sinwaveHrn
	.binary "sinwave4rn.bin"
sinwaveLrn = sinwaveHrn+$100

; -- caractères spéciaux :
; 
; ronds gauche : 27
; bonhomme : 28
; ronds droite : 29
; rond : 30
; disquette : 31
; étoile : * ?
; coeur : 59 ;
; ... : &

scrolltext
	.enc "screen"

	.text "** GREETINGS TO ** "
	.byte 0
	.text "BUSYSOFT, F4CG, TFL"
	.byte 0
	.text ", CENSOR DESIGN,   "
	.byte 0
	.text "GENESIS PROJECT,   "
	.byte 0
	.text "TRIAD, OXYRON,     "
	.byte 0
	.text "XENON, PADUA,      "

	.text "HOKUTO FORCE, TRSI,"
	.byte 0
	.text "LAXITY, REALITY,   "
	.byte 0
	.text "ATLANTIS, ARSENIC, "
	.byte 0
	.text "XENTAX,ONSLAUGHT,  "
	.byte 0
	.text "DESIRE, ROLE,      "

	.text "FAIRLIGHT, EXCESS, "
	.byte 0
	.text "COSINE, SONIC,     "
	.byte 0
	.text "SOLUTION, BLAZON   "
	.byte 0
	.text "HOAXERS, TRANSCOM& "
	.byte 0
	.text "&NO WE'RE KIDDING  "
	.byte 0
	.text "NOT TRANSCOM       "
	.byte 0
	.byte 255


         ;-0123456789012345678
	.text " HERE WE ARE AGAIN,"
	.byte 0
	.text "AT THE END PART OF "
	.byte 0
	.text "THE DEMO "
	.byte 031
	.text " TIME FOR"
	.byte 0
	.text "CREDITS & GREETINGS"
	.byte 0
	.text " * HERE WE GO !! * "
	.byte 0
	.text " CREDITS FOR INTRO "
	.byte 0
	.text "FONT, LOGO BY CUPID"
	.byte 0
	.text "MUSIC BY MAGNAR    "
	.byte 0
	.text "CODE BY PAPAPOWER  "
	.byte 0
	.text "BETWEEN ALL PARTS  "
	.byte 0
	.text "AWESOME LOADER BY  "
	.byte 0
	.text "    ; KRILL ;      "
	.byte 0
	.text "                   "
	.byte 0
	.text " NOSTALGIA PART    "
	.byte 0
	.text " FONT, GFX BY CUPID"
	.byte 0
	.text " MUSIC BY XINY6581 "
	.byte 0
	.text " CODE BY PAPAPOWER "
	.byte 0
	.text " OLDSKOOL 3D PLOT  "
	.byte 0
	.text " GFX BY NYKE       "
	.byte 0
	.text " MUSIC BY TLF      "
	.byte 0
	.text " CODE BY JOY       "
	.byte 0
	.text "GRANDPAS "
	.byte 28,28,28
	.text " PART  "
	.byte 0
	.text " FONT,GFX BY CUPID "
	.byte 0
	.text " MUSIC BY TLF      "
	.byte 0
	.text " CODE BY PAPAPOWER "
	.byte 0
	.text "THANKS AGAIN TO ALL"
	.byte 0
	.text " THE ARTISTS THAT  "
	.byte 0
	.text "  MADE THIS DEMO   "
	.byte 0
	.text " POSSIBLE   ; ; ;  "
	.byte 0

	.text "HI TO BUSYSOFT,F4CG"
	.byte 0
	.text "CENSOR DESIGN,ROLE "
	.byte 0
	.text "GENESIS PROJECT,TLF"
	.byte 0
	.text "TRIAD,OXYRON,XENON "
	.byte 0

	.text "HOKUTO FORCE,DESIRE"
	.byte 0
	.text "LAXITY,REALITY,TRSI"
	.byte 0
	.text "ATLANTIS,ARSENIC   "
	.byte 0
	.text "XENTAX,EXCESS,PADUA"
	.byte 0

	.text "FAIRLIGHT,ONSLAUGHT"
	.byte 0
	.text "COSINE,EXCESS,SONIC"
	.byte 0
	.text "SOLUTION,BLAZON    "
	.byte 0
	.text "HOAXERS,TRANSCOM  "
	.byte 0
	.byte 255
