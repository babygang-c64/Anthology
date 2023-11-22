;=========================================================
; [Babygang] Anthology 1988-2022, Part 2 - vignettes
;---------------------------------------------------------
; map : 
; 
; krill loader resident : $CE00
; screen : $0400 - 0800
; code : $6c00
; charset : $0800 - $1000 : pour texte vignettes
; hires 1 : $2000 - $3FFF : hires vignette décalé
; hires 2 : $4000 - $5FFF : hires vignette normal, FLD
; screen 2 : $6000 - $6400 : pour hires 2
; color 2 : $6400 - $6800 : pour hires 2
; pour test standalone install loader krill $7000
;---------------------------------------------------------
; Build :
; ./exomizer sfx 0x1000 ../../anthology_p2.prg -n -o antp2.prg
;=========================================================

KernalPrint = $AB1E

* = $4000
	.binary "I0.bin",2

charset2x2
* = $0800
	.binary "charled.bin"

loadraw = $ce00
loadcompd = $ce0b

* = $1000
	.binary "albator.prg",2

* = $6C00

start
	lda #1
	jsr $1000
	sei
	lda #0
	sta $d020
	sta $d021
	sta $d011
	
	jsr prep_led_space_total
	;-- Affiche texte intro
	lda #18
	sta $d018
	lda #$1b
	sta $d011
	lda #3
	sta $dd00
	jsr draw_intro_text

	.setup_raster_irq irqTxt, 255

boucle
	lda fin_txt
	beq boucle
short
	jsr prepare_text
	jsr prep_hires1
	jsr prep_led_space
	jsr prep_hires2
	jsr blackout_hires2
	.show_hires2
	.new_frame
	lda #$3b
	sta $d011

	.setup_raster_irq irqNoFld, 255
;	.setup_raster_irq irqIntro, 49
	jmp wait_fin_p2

;---------------------------------------------------------
; irqTxt : IRQ pour la gestion du texte d'intro
; affichage couleur, attente, musique
;---------------------------------------------------------

fin_txt
	.byte 0

state_txt
	.byte 250
state_txt_nb
	.byte 2

irqTxt
	;-- musique
	jsr $1003

	;-- nouvelle ligne couleur
	lda color_row
	cmp #24
	bne irqTxt2

	;-- délai d'attente avant la suite
	dec state_txt
	bne irqTxtOK
	dec state_txt_nb
	bne irqTxtOK

	lda #1
	sta fin_txt
	jmp irqTxtOK

irqTxt2
	ldx color_row
	lda color_line,x
	jsr colorize_text
	inc color_row

irqTxtOK
	.end_raster_irq

;---------------------------------------------------------
; wait_fin_p2 : chargement des images, attente fin part
;---------------------------------------------------------

wait_fin_p2
	lda change_image
	beq wait_fin_p2

	ldx #<filename
    ldy #>filename
    jsr loadcompd
    jsr prep_hires1
    jsr prep_hires2
    lda #2
    sta hires_version
    lda #0
    sta change_image
;    sta do_what

	jmp wait_fin_p2

color_line
	.byte 7,7,7,7
	.byte 0,0
	.byte 2,2,2,2
	.byte 0,0
	.byte 5,5,5,5
	.byte 5,5,5,5
	.byte 0,0
	.byte 2,2

change_image
	.byte 0

filename
	.text "I1"
	.byte 0

;---------------------------------------------------------
; prep_colors : copie les couleurs de l'image KLA aux bons
; emplacements
;---------------------------------------------------------

prep_colors
	rts

;---------------------------------------------------------
; prep_hires1 : calcule image décalée pour affichage texte
;
; copie l'image de $4000 à $5300 vers $2780
;---------------------------------------------------------

prep_hires1
	ldx #0
mv_bitmap1
	lda $4000,x
	sta $2780,x
	lda $4100,x
	sta $2880,x
	lda $4200,x
	sta $2980,x
	lda $4300,x
	sta $2a80,x
	lda $4400,x
	sta $2b80,x
	lda $4500,x
	sta $2c80,x
	lda $4600,x
	sta $2d80,x
	lda $4700,x
	sta $2e80,x
	lda $4800,x
	sta $2f80,x
	lda $4900,x
	sta $3080,x
	lda $4a00,x
	sta $3180,x
	lda $4b00,x
	sta $3280,x
	lda $4c00,x
	sta $3380,x
	lda $4d00,x
	sta $3480,x
	lda $4e00,x
	sta $3580,x
	lda $4f00,x
	sta $3680,x
	lda $5000,x
	sta $3780,x
	lda $5100,x
	sta $3880,x
	lda $5200,x
	sta $3980,x
	lda $5300,x
	sta $3a80,x
	inx
	bne mv_bitmap1
	;-- move screen char
mv_scr1	
	lda $5400,x
	sta $3b80,x
	lda $5500,x
	sta $3c80,x
	lda $5600,x
	sta $3d80,x
	lda $5700,x
	sta $3e80,x
	lda $6000,x
	sta $04f0,x 
	lda $6100,x
	sta $05f0,x 
	lda $6200,x
	sta $06f0,x
	lda $6208,x
	sta $06f8,x
	inx
	bne mv_scr1
	rts

;---------------------------------------------------------
; prep_hires1_col : affichage couleurs image tronquée txt
;---------------------------------------------------------

prep_hires1_col
	jsr apply_led_color
	ldx #0
mv_col1
	lda $6400,x
	sta $d8f0,x
	lda $6500,x
	sta $d9f0,x
	lda $6600,x
	sta $daf0,x 
	lda $6608,x
	sta $daf8,x 
	inx
	bne mv_col1
	rts

;---------------------------------------------------------
; prep_led_space : raz espace pour l'affichage texte leds
;---------------------------------------------------------

prep_led_space
	ldx #0
	txa
do_6lignes
	sta $0400,x
	inx
	cpx #240
	bne do_6lignes
	rts

;---------------------------------------------------------
; prep_led_space_total : raz tout l'espace texte + couleur
;---------------------------------------------------------

prep_led_space_total
	ldx #0
	txa
-
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $06e8,x
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $dae8,x
	inx
	bne -
	rts

;---------------------------------------------------------
; show_hires1 : affiche l'image tronquée pour zone texte
;---------------------------------------------------------

show_hires1 .macro
	;-- vic bank $0000
	lda #%00000011
	sta $dd00
	lda #$18
	sta $d018
	.endm

;---------------------------------------------------------
; show_hires2 : affiche l'image complète hires2 pour FLD
;---------------------------------------------------------

show_hires2 .macro
	;-- hires multicolor mode
	lda #%11010000
	sta $d016
	;-- vic bank $4000
	lda #%00000010
	sta $dd00
	;-- gfx mem $4000, scr mem $6000
	lda #%10000000
	sta $d018
	.endm

;---------------------------------------------------------
; prep_hires2 : prépare les couleurs pour l'image complète
;---------------------------------------------------------

prep_hires2
	ldx #0
b_color_p1
	lda $6400,x
	sta $d800,x
	lda $6500,x
	sta $d900,x
	lda $6600,x
	sta $da00,x
	lda $6700,x
	sta $db00,x
	inx
	bne b_color_p1
	rts

;---------------------------------------------------------
; irqFldDo pour process vignettes
;---------------------------------------------------------

bloque_fld
	.byte 0

irqFldDo
	;-- effectue le FLD en fonction de pos_fld
	ldx pos_fld
	lda sinus_fld,x
	tax
	jsr do_fld

	lda bloque_fld
	beq non_bloque_fld
	cmp pos_fld
	bne non_bloque_fld
	lda #0
	sta doing_fld

non_bloque_fld
	;-- si séquence finie = fin IRQ
	lda doing_fld
	beq suite_do_fld

	;-- sinon incrémente / décrémente en fonction de la
	;-- séquence en cours
	lda sens_fld
	beq fld_plus
	dec pos_fld
	beq stop_do_fld
	bne suite_do_fld
fld_plus
	inc pos_fld
	bne suite_do_fld

	;-- si fini positionne l'indicateur doing_fld à 0
stop_do_fld
	lda #0
	sta doing_fld

suite_do_fld
	.next_raster_irq irqResetFldDo, 255

sens_fld
	.byte 0 ; 0 = positif, autre = negatif

doing_fld
	.byte 1 ; 1 = en cours, 0 = fini

;---------------------------------------------------------
; irqResetFldDo
;---------------------------------------------------------

irqResetFldDo
	lda #$3b
	sta $d011
	jsr process_do_what
	jsr $1003
	.next_raster_irq irqFldDo, 49

	;jmp fini_move_fld2

;	.show_hires1
;	jsr prep_hires1_col
;	.next_raster_irq irqResetFldDo, 250

;---------------------------------------------------------
; irqIntro
;---------------------------------------------------------

irqIntro
	ldx pos_fld
	lda sinus_fld,x
	tax
	jsr do_fld
	inc pos_fld
	beq fini_move_fld
	.next_raster_irq irqResetFld, 250

fini_move_fld
	; FLD fini : indique la fin, affiche l'image hires1
	;  			 décalée avec partie pour texte et prépare
	;			 la zone recevant du texte
	;			 prochain raster = split texte / hires
	lda #1
	sta pos_fld
wait_end_screen
	lda $d012
	cmp #250
	bne wait_end_screen

fini_move_fld2
	.show_hires1
	jsr prep_hires1_col
	.next_raster_irq irqDebutChar, 50

pos_fld
	.byte 0

;---------------------------------------------------------
; irqDebutChar : irq zone caractères
;---------------------------------------------------------

irqDebutChar
	lda #%11000000
	ora reste_scroll_x
	sta $d016
	;-- chars $0800, screen $0400
	lda #18
	sta $d018
	lda #$1b
	sta $d011
suite_char
	.next_raster_irq irqDebutHires, 49+8*6

pos_scroll_x
	.byte 0
reste_scroll_x
	.byte 0

;---------------------------------------------------------
; irqDebutHires : irq zone hires
;---------------------------------------------------------

irqDebutHires
	nop
	nop
	nop
	nop
	nop
	nop
	lda #$3b-8
	sta $d011
	lda #$18
	sta $d018
	lda #%11010000
	sta $d016
	.next_raster_irq do_what_zik, 250
do_what_zik
	jsr $1003
	jsr process_do_what
	.next_raster_irq irqDebutChar, 48

;---------------------------------------------------------
; irqNoFld
;---------------------------------------------------------

irqNoFld
	jsr $1003
	jsr process_do_what
	.next_raster_irq irqNoFld, 255


;---------------------------------------------------------
; scroll_text : affiche le texte pour le scroll
;---------------------------------------------------------

scroll_text
	ldx pos_scroll_x
	lda sin_texte+$0100,x
	sta reste_scroll_x
	clc
	lda sin_texte,x
	adc page_scroll
	tax

	ldy #0
do_scroll
	lda zone_plot,x
	sta $0400,y
	lda zone_plot+$0100,x
	sta $0400+40,y
	lda zone_plot+$0200,x
	sta $0400+80,y
	lda zone_plot+$0300,x
	sta $0400+120,y
	lda zone_plot+$0400,x
	sta $0400+160,y
	lda zone_plot+$0500,x
	sta $0400+200,y
	inx
	iny
	cpy #40
	bne do_scroll
	rts
page_scroll
	.byte 0

;---------------------------------------------------------
; irqResetFld
;---------------------------------------------------------

irqResetFld
	lda #$3b
	sta $d011
	jsr $1003
	.next_raster_irq irqIntro, 49

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
; do_fld
;	perform FLD effect at current position
;	X : length of FLD
;---------------------------------------------------------

do_fld
	ldy $d012
wait_fld
	cpy $d012
	beq wait_fld
	lda $d011
	clc
	adc #1
	and #7
	adc #$30
	sta $d011
	cpy #250
	beq stop_fld
	dex
	bne do_fld
stop_fld
	rts

;---------------------------------------------------------
; plot2x2 :
; 	A = caractère à écrire
;   X : pour position d'écriture
;   en sortie : X positionné au caractère suivant
;---------------------------------------------------------

plot2x2_l1
	asl
	asl
	sta zone_plot,x
	clc
	adc #1
	sta zone_plot+1,x
	adc #1
	sta zone_plot+$0100,x
	adc #1
	sta zone_plot+$0101,x 
	inx
	inx
	rts
plot2x2_l2
	asl
	asl
	sta zone_plot+$0200,x
	clc
	adc #1
	sta zone_plot+$0201,x
	adc #1
	sta zone_plot+$0300,x
	adc #1
	sta zone_plot+$0301,x 
	inx
	inx
	rts
plot2x2_l3
	asl
	asl
	sta zone_plot+$0400,x
	clc
	adc #1
	sta zone_plot+$0401,x
	adc #1
	sta zone_plot+$0500,x
	adc #1
	sta zone_plot+$0501,x 
	inx
	inx
	rts

;---------------------------------------------------------
; draw_intro_text : écriture page de texte d'intro
;
; screen $0400 dans zp_plot
;---------------------------------------------------------

zp_plot = $5e

draw_intro_text
	lda #0
	tay
	sta zp_plot
	lda #4
	sta zp_plot+1

draw_next
	lda text_intro
	beq fin_text_intro
	bpl txt_normal
	clc
	lda zp_plot
	adc #40
	sta zp_plot
	bcc noi2
	inc zp_plot+1
	jmp noi2

txt_normal

	beq fin_text_intro
	asl
	asl
	sta (zp_plot),y
	iny
	clc
	adc #1
	sta (zp_plot),y
	adc #1
	dey
	tax
	clc
	lda zp_plot
	adc #40
	sta zp_plot
	bcc noi1
	inc zp_plot+1
noi1
	txa
	sta (zp_plot),y
	clc
	adc #1
	iny
	sta (zp_plot),y
	dey
	sec
	lda zp_plot
	sbc #38
	sta zp_plot
	bcs noi2
	dec zp_plot+1
noi2
	inc draw_next+1
	jmp draw_next
fin_text_intro
	rts

;---------------------------------------------------------
; colorize_text : colorise une ligne de texte avec la
; couleur donnée dans A, passe à la ligne suivante
;---------------------------------------------------------

color_row
	.byte 0

colorize_text
	pha
	ldx color_row
	lda posYL_screen,x
	sta zp_plot
	clc
	lda posYH_screen,x
	adc #$d8-$60
	sta zp_plot+1
	ldy #39
	pla
do_colorize
	sta (zp_plot),y
	dey
	bpl do_colorize
	rts

;---------------------------------------------------------
; texte de la page d'intro
; 255 : fin de ligne
; 0 : fin de texte
;---------------------------------------------------------

	.align $0100
text_intro
	;     "01234567890123456789"
	.text "BABYGANG IS A FRENCH"
	.byte 255
	.text "C64 GROUP BORN IN 88"
	.byte 255
	.text "                    "
	.byte 255
	.text "WE BROUGHT YOU TOOLS"
	.byte 255
	.text "CRACKS AND DEMOS :  "
	.byte 255
	.text "                    "
	.byte 255
	.text "PRISE DE TETE       "
	.byte 255
	.text "HEXAGONE            "
	.byte 255
	.text "HEXAGONE 2          "
	.byte 255
	.text "HARE KRISHNA        "
	.byte 255
	.text "                    "
	.byte 255
	.text "AND MANY OTHERS...  "
	.byte 0


;---------------------------------------------------------
; prepare_text
;---------------------------------------------------------

prepare_text
	ldx #0
	txa
do_raz_text
	sta zone_plot,x
	sta zone_plot+$0100,x
	sta zone_plot+$0200,x
	sta zone_plot+$0300,x
	sta zone_plot+$0400,x
	sta zone_plot+$0500,x
	dex
	bpl do_raz_text
	tax
	tay
do_plot_l1
	lda text_data_l1,y
	beq fin_plot_l1
	jsr plot2x2_l1
	iny
	bpl do_plot_l1
fin_plot_l1
	ldx #0
	ldy #0
do_plot_l2
	lda text_data_l2,y
	beq fin_plot_l2
	jsr plot2x2_l2
	iny
	bpl do_plot_l2
fin_plot_l2
	ldx #0
	ldy #0
do_plot_l3
	lda text_data_l3,y
	beq fin_plot_l3
	jsr plot2x2_l3
	iny
	bpl do_plot_l3
fin_plot_l3
	rts

;---------------------------------------------------------
; new_frame : wait new frame
;---------------------------------------------------------

new_frame .macro
-
	bit $d011
    bpl -
-
    bit $d011
    bmi -
    .endm

;---------------------------------------------------------
; sinus_fld : sinusoide pour le FLD, de 200 à 48
;---------------------------------------------------------

.align $0100
sinus_fld
	.binary "sinwave_p3.bin"

;---------------------------------------------------------
; sin_texte : sinusoide pour le texte, en 2 morceaux
;---------------------------------------------------------

.align $0100
sin_texte
	.binary "sinwave_txt_1.bin"

;---------------------------------------------------------
; zone_plot : zone de traçage pour texte
; 6x128c
;---------------------------------------------------------

.align $0100
zone_plot
	.fill 256*6, $00
.warn repr(zone_plot)

text_data_l1
;	       01234567890123456789
	.text "                    " ; 0
	.text " WE'RE BACK WITH A  " ; 40
	.text " IN THIS ANTHOLOGY  " ; 80
	.text " WE HOPE THAT THIS  " ; 120
	.text "REMEMBER WHEN WE    " ; 160
	.text "                    " ; 200
	.byte 0
text_data_l2
	.text "                    "
	.text " CHOICE OF SCREENS  "
	.text "    1988-2022       "
	.text " SMALL DEMO BRINGS  "
	.text "HAD MOSES HIMSELF   "
	.text "                    " ; 200
	.byte 0
text_data_l3
	.text "                    "
	.text " FROM OUR OLD DEMOS "
	.text "  FOR YOU TO VIEW   "
	.text " YOU SOME NOSTALGIA "
	.text "HANDLING DISKS ??   "
	.text "                    " ; 200
	.byte 0

;---------------------------------------------------------
; commandes :
; 0 : start mode
; 1,<page> : scroll en démarrant de la page <page>
; 2,<qte> : wait <qte> frames
; 3 : disparition texte
; 4,<page> : affichage texte
; 5,<sens> : FLD, active IRQ FLD
; 			 1 : décrémente
; 			 0 : incrémente
; 			 si différent : lis position départ FLD puis
;			 lis le sens
; 6 : passe sur l'image complète hires 2, bloque FLD à 160
; 7 : passe sur l'image tronquée, active IRQ multi
; 8,<num> : charge une nouvelle image en background
; 9 : disparition texte via couleurs
; 10 : half reveal hires 2
; 11 : clean zone texte
; $ff : fini
;---------------------------------------------------------

do_what
	.byte 0
pos_cmd_do_what
	.byte 0
cmd_do_what
	;-- image de départ, effet d'apparition et FLD pos txt
	.byte 10,5,160,0,7
	;-- attente 150, 1er txt, attente 100, 2nd txt et effacement
	.byte 2,200,2,70,1,0,2,150,2,200,9,11
	;-- FLD disparition, chargement new, FLD app, split
	.byte 5,1,8,1,5,0,7
	.byte 5,1,8,3,5,0,7
	.byte 5,1,8,2,5,0,7
	;-- texte 4, attente 150, effacement
	.byte 4,160,2,200,2,100,9
	.byte 5,1,8,4,6,5,0,2,200
	.byte $ff


pos_supp_txt
pos_aff_txt
nb_wait
	.byte 0
page_aff_txt
	.byte 0

hires_version
	.byte 1

.warn repr(do_what)

;---------------------------------------------------------
; process_do_what : traite la commande en cours, si fini
; 					(valeur 0) passe à la commande suivante
;---------------------------------------------------------

process_do_what
	lda do_what
	beq do_what_next
	jmp do_what_encours

do_what_next
	ldx pos_cmd_do_what
	lda cmd_do_what,x
	cmp #1
	bne not_1

	;-- init scroll
do_what_init_scroll
	sta do_what
	inx
	lda cmd_do_what,x
	sta page_scroll
	lda #0
	sta pos_scroll_x
	inc pos_cmd_do_what
	inc pos_cmd_do_what
	rts
not_1
	cmp #2
	bne not_2

	;-- init wait
do_what_init_wait
	sta do_what
	inx
	lda cmd_do_what,x
	sta nb_wait
	inc pos_cmd_do_what
	inc pos_cmd_do_what
	rts
not_2
	cmp #3
	bne not_3

	;-- init supp_txt
	sta do_what
	lda #39
	sta pos_supp_txt
	inc pos_cmd_do_what
	rts
not_3
	cmp #4
	bne not_4

	;-- init aff_txt
	sta do_what
	inx
	lda cmd_do_what,x
	sta calc_y
	lda #39
	sta pos_aff_txt
	lda #7
	sta reste_scroll_x
	inc pos_cmd_do_what
	inc pos_cmd_do_what
	rts
not_4
	cmp #5
	bne not_5

	;-- init FLD
	;-- avec sens : 0 = positif, 1 = negatif
	;-- ou position fld puis sens

	sta do_what
	inx
	lda #1
	sta doing_fld
	inc pos_cmd_do_what
	inc pos_cmd_do_what

	lda cmd_do_what,x
	ldy #255
	cmp #1
	beq fin_init_5
	iny
	cmp #0
	beq fin_init_5
	tay
	inc pos_cmd_do_what
	inx
	lda cmd_do_what,x
fin_init_5
	sty pos_fld
	sta sens_fld

do_5_suite
	;-- depile adresse retour JSR, change le raster
	;-- et retour de l'IRQ
	lda hires_version
	cmp #2
	beq do_5_ok
do_5_pos
	lda $d012
	cmp #150
	bne do_5_pos
	.show_hires1
	jsr prep_hires2
	.show_hires2
	lda #2
	sta hires_version
do_5_ok
	pla
	pla
	.next_raster_irq irqFldDo, 49

not_5
	cmp #6
	bne not_6

	;-- Init affiche écran hires complet
	sta do_what
	inc pos_cmd_do_what
	lda #1
	sta hires_version
	lda #160
	sta bloque_fld
	
	rts
not_6
	cmp #7
	bne not_7

	;-- Init affiche l'écran hires tronqué, change l'IRQ
	sta do_what
	inc pos_cmd_do_what
	pla
	pla
	.show_hires1
	jsr prep_hires1_col
	lda #1
	sta hires_version

	;.next_raster_irq irqDebutHires, 49+8*6
	.next_raster_irq irqDebutChar, 48
	

not_7
	cmp #8
	bne not_8

	;-- charge une image en tache de fond
	sta do_what
	inx
	lda cmd_do_what,x
	clc
	adc #$30
	sta filename+1
	lda #1
	sta change_image
	inc pos_cmd_do_what
	inc pos_cmd_do_what
	rts

not_8
	cmp #9
	bne not_9
	;-- init supp_txt suppression via couleur
	sta do_what
	lda #0
	sta pos_supp_txt
	inc pos_cmd_do_what
	rts

not_9
	cmp #10
	bne not_10
	;-- init half reveal hires 2
	sta do_what
	inc pos_cmd_do_what
	lda #0
	sta pos_supp_txt
	rts

not_10	
	cmp #11
	bne not_11
	sta do_what
	inc pos_cmd_do_what
	rts
not_11
	cmp #255
	bne not_found
	sta do_what
not_found
	jmp loaderP3


;---------------------------------------------------------
; do_what_encours : traite la commande en cours, passe
;				    à la commande suivante si fini
;---------------------------------------------------------


jmp_do_what_encours
	jmp do_nothing
	jmp do_what_scroll
	jmp do_what_wait
	jmp do_what_supp_txt
	jmp do_what_aff_txt
	jmp do_what_fld 
	jmp do_what_hires_complet
	jmp do_what_hires_multi 
	jmp do_what_wait_image
	jmp do_what_supp_txt2
	jmp do_what_half_reveal
	jmp do_clean_text

do_what_encours
;do_jump
	clc
	lda do_what
	bmi no_jump
	adc do_what
	adc do_what
	tax
	lda jmp_do_what_encours+1,x
	sta go_jump+1
	lda jmp_do_what_encours+2,x
	sta go_jump+2
go_jump jmp $fce2
do_nothing
no_jump
	rts


do_what_hires_complet
	lda hires_version
	cmp #2
	bne update_hires2
	jmp do_what_next
update_hires2	
	.show_hires2
	jsr prep_hires2
	lda #2
	sta hires_version
	jmp do_what_next

do_what_hires_multi
	lda hires_version
	cmp #1
	bne update_hires1
	jmp do_what_next
update_hires1
	.show_hires1
	jsr prep_hires1_col
	lda #1
	sta hires_version
	jmp do_what_next

b_do_what_next
	jmp do_what_next
do_what_scroll
	jsr scroll_text
	inc pos_scroll_x
	beq b_do_what_next
	rts

do_what_wait
	dec nb_wait
	beq b_do_what_next
	rts

do_what_fld
	lda doing_fld
	beq b_do_what_next
	rts

do_what_supp_txt
	jsr supp_txt
	dec pos_supp_txt
	bmi b_do_what_next
	rts

do_what_supp_txt2
	jsr supp_txt2
	inc pos_supp_txt
	lda pos_supp_txt
	cmp #40
	beq b_do_what_next
	rts

do_clean_text
	jsr prep_led_space
	jmp b_do_what_next

do_what_aff_txt
	jsr aff_txt
	dec pos_aff_txt
	bmi b_do_what_next
	rts

do_what_wait_image
	lda change_image
	beq b_do_what_next
	rts

do_what_half_reveal
	ldx pos_supp_txt
	jsr reveal_hires2
	inc pos_supp_txt
	lda pos_supp_txt
	cmp #25
	beq b_do_what_next
	rts

;---------------------------------------------------------
; supp_txt : supprime le texte avec un effet
;---------------------------------------------------------

supp_txt
	ldx pos_supp_txt
	lda #0
	sta $0400,x
	sta $0400+80,x
	sta $0400+80+80,x
	lda #39
	sec
	sbc pos_supp_txt
	tax
	lda #0 
	sta $0400+40,x
	sta $0400+80+40,x
	sta $0400+160+40,x
	rts

;---------------------------------------------------------
; supp_txt2 : supprime le texte avec un effet de couleur
;			  en X, position dans la ligne
;---------------------------------------------------------

supp_txt2
	ldy #0
	ldx pos_supp_txt
do_supp2
	lda col_supp_txt2,y
	bmi fin_supp_txt2
	sta $d800,x
	sta $d800+40,x
	sta $d800+40*2,x
	sta $d800+40*3,x
	sta $d800+40*4,x
	sta $d800+40*5,x	
	iny
	dex
	bpl do_supp2
fin_supp_txt2
	rts

col_supp_txt2
	.byte 2,1,7,15,11,12,0,0,0,0,128

;---------------------------------------------------------
; aff_txt : affiche le texte avec un effet
; Y : position du texte à recopier (source)
;---------------------------------------------------------

aff_txt
	ldx pos_supp_txt
	txa
	clc
	adc calc_y
	tay

	lda zone_plot,y
	sta $0400,x
	lda zone_plot+$0200,y
	sta $0400+80,x
	lda zone_plot+$0400,y
	sta $0400+80+80,x

	lda #39
	sec
	sbc pos_supp_txt
	tax
	clc
	adc calc_y
	tay 

	lda zone_plot+$0100,y
	sta $0400+40,x
	lda zone_plot+$0300,y
	sta $0400+80+40,x
	lda zone_plot+$0500,y
	sta $0400+160+40,x
	rts
calc_y
	.byte 0

;---------------------------------------------------------
; led_color
;---------------------------------------------------------

apply_led_color
	ldx #39
	lda #7
apply_loop
	sta $d800,x
	sta $d800+40,x
	sta $d800+80,x
	sta $d800+120,x
	sta $d800+160,x
	sta $d800+200,x
	dex
	bpl apply_loop
	rts

;---------------------------------------------------------
; blackout_hires2 : couleurs à 0 pour hires 2 et backup
; 					scr en 6800
;---------------------------------------------------------

blackout_hires2
	ldx #0
black0
	lda $6000,x
	sta $6800,x
	lda $6100,x
	sta $6900,x
	lda $6200,x
	sta $6a00,x
	lda $6300,x
	sta $6b00,x
	lda #0
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $db00,x
	sta $6000,x
	sta $6100,x
	sta $6200,x
	sta $6300,x
	inx
	bne black0
	rts

;---------------------------------------------------------
; reveal_hires2 : affichage progressif X 0-24
; sources couleur : $6800 scr $6400 col
; dest couleur.   : $0400 scr $d800 col
;---------------------------------------------------------

from_scr = $50
from_col = $52
to_scr = $54
to_col = $56

reveal_hires2
	ldy #0
	jsr calc_half_reveal
	jsr do_half_reveal

	sec
	stx do_sub+1
	lda #24
do_sub
	sbc #0
	tax
	jsr calc_half_reveal
	ldy #1
	jmp do_half_reveal

calc_half_reveal	
	lda posYL_screen,x
	sta to_scr
	sta to_col
	sta from_scr
	sta from_col
	lda posYH_screen,x
	sta to_scr+1
	clc
	adc #4
	sta from_col+1
	adc #4
	sta from_scr+1
	adc #$70
	sta to_col+1
	rts

do_half_reveal
	lda (from_scr),y
	sta (to_scr),y
	lda (from_col),y
	sta (to_col),y
	iny
	iny
	cpy #40
	beq stop_half_reveal
	cpy #41
	beq stop_half_reveal
	bne do_half_reveal
stop_half_reveal
	rts

posYL_screen:

.byte 0,40,80,120,160,200,240
.byte 24,64,104,144,184,224
.byte 8,48,88,128,168,208,248
.byte 32,72,112,152,192

posYH_screen:

.byte $60,$60,$60,$60,$60,$60,$60
.byte $61,$61,$61,$61,$61,$61
.byte $62,$62,$62,$62,$62,$62,$62
.byte $63,$63,$63,$63,$63

loaderP3
	sei
	lda #3
	sta $dd00
	lda #55
	sta $01
	lda #200
	sta $d016
	lda #21
	sta $d018
	lda #$1b
	sta $d011
	lda #6
	sta $d021
	lda #14
	sta $d020
	sta $0286
	jsr $e544
	ldx #0
	stx 204
-
	lda txtLoaderP3,x
	bmi fin_intro_text
	jsr $ffd2
	inx
	bne -
fin_intro_text
	ldx #0
-
	lda #6
	sta $da00,x
	sta $db00,x
	lda bootloader,x
	sta $0600,x
	lda bootloader+$100,x
	sta $0700,x
	inx
	bne -	
	ldx #0
	stx posTxt
	stx curseur_status
	stx fin_text 
-
	lda filenameP3in,x
	sta filenameP3,x
	inx
	cpx #8
	bne -

	lda #8
	sta speedTxt
	lda #20
	sta curseur_nb
	lda #250
	sta wait_first


	.setup_raster_irq $0608+4,250
	ldx #<filenameP3
    ldy #>filenameP3
	jmp $0600

txtLoaderP3
	;      0123456789012345678901234567890123456789	
	.byte 13
	.text "    **** COMMODORE 64 BASIC V2 ****"
	.byte 13,13
	.text " 64K RAM SYSTEM  38911 BASIC BYTES FREE"
	.byte 13,13
	.text "READY."
	.byte 13,160
filenameP3in
	.text "P3.PRG"
	.byte 0


bootloader
	jsr loadraw
-
	lda fin_text
	beq -
	sei
	jmp $08a3
	;jmp 2061
irqTxtLoader
	lda wait_first
	beq ok_wait_first
	dec wait_first
	bne fin_irq
	lda #1
	sta 646
ok_wait_first
	dec curseur_nb
	bne +
	lda #20
	sta curseur_nb
	lda curseur_status
	eor #$ff
	sta 204
	sta curseur_status
+
	dec speedTxt
	bne fin_irq
	lda $d012 
	eor $dc04 
	sbc $dc05	
	and #7
	rol a
	adc #4
	sta speedTxt
	ldx posTxt
	lda $0700,x
	beq fin_texte_trouve
	jsr $ffd2
	inc posTxt
fin_irq
	asl $d019
	jmp $ea31
fin_texte_trouve
	lda #1
	sta fin_text
	asl $d019
	jmp $ea31

	* = $100+bootloader
	.byte 5
	.text "I'D LIKE TO DEDICATE NEXT PART CODED BY "
	.text "JOY TO LUDWIG WHO PASSED AWAY TOO SOON."
	.byte 0
posTxt = $0700-1
speedTxt = $0700-2
curseur_status = $0700-3
curseur_nb = $0700-4
wait_first = $0700-5
fin_text = $0700-6
filenameP3 = $700-16


