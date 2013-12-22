; Soci/Singular

	*=$0801
	.binary "skyfox-raw4",2
	
	*=$cf00
	ldx #$19
-	lda $31a,x
	sta $e9a,x	;vector table update
	dex
	bne -
	lda $ba
	sta $50a9	;drive number update
	eor #8
	asl
	asl
	sta $50ab	;checksum...
	jmp $080d
