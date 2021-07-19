PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

E = %10000000
RW = %01000000
RS = %00100000

value = $0200 ; 2 bytes; value to convert
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a ; 2 bytes


  .org $8000

reset:
  ldx #$ff ; reset the stack pointer to ff
  txs
  cli

  lda #$82
  sta IER
  lda #$00
  sta PCR

  lda #%11111111 ; Set  all the points on port B to output
  sta DDRB
  lda #%11100000 ; Set the top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  lda #0
  sta counter
  sta counter + 1

loop:
  lda #%00000010 ; Return display to Home
  jsr lcd_instruction

  lda #0
  sta message

  ; Initialise value to be the number to convert
  sei
  lda counter
  sta value
  lda counter + 1
  sta value + 1
  cli

divide:
  ; Initialise the remainder to zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16
  ;clc
divloop:
  ; Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a,y = dividend - divisor
  sec           ; Set carry bit
  lda mod10
  sbc #10       ; subtract with carry
  tay           ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; branch if dividend < divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value ; shift in the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; if value != 0, then continue dividing 
  lda value
  ora value + 1
  bne divide ; branch if not 0

  ldx #0
print_message:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print_message


;number: .word 1729

; Add the character in the A register to the beginning of the null-terminated string 'message'
push_char:
  pha ; Push new first char onto stack
  ldy #0

char_loop:
  lda message,y ; Get char on string and put into X
  tax
  pla
  sta message,y ; Pull char off the stack and add it to the string
  iny
  txa
  pha    ; Push char from string onto the stack
  bne char_loop

  pla
  sta message,y ; Pull the null off the stack and add to the end of the string

  rts

lcd_wait:
  pha
  lda #%00000000 ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111 ; Port B to output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0
  sta PORTA
  lda #E
  sta PORTA
  lda #0
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E)
  sta PORTA
  lda #RS
  sta PORTA
  rts

nmi:
irq:
  inc counter
  bne exit_irq
  inc counter + 1

exit_irq:
  bit PORTA
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
