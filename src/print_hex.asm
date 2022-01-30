; Prints the value of DX as hex.
print_hex:
  pusha             ; save the register values to the stack for later

  mov cx,4          ; Start the counter: we want to print 4 characters
                    ; 4 bits per char, so we're printing a total of 16 bits

char_loop:
  dec cx            ; Decrement the counter

  mov ax,dx         ; copy bx into ax so we can mask it for the last chars
  shr dx,4          ; shift bx 4 bits to the right
  and ax,0xf        ; mask ah to get the last 4 bits

  mov bx, HEX_OUT   ; set bx to the memory address of our string
  add bx, 2         ; skip the '0x'
  add bx, cx        ; add the current counter to the address

  cmp ax,0xa        ; Check to see if it's a letter or number
  jl set_letter     ; If it's a number, go straight to setting the value
  add al, 0x27      ; If it's a letter, add 0x27, and plus 0x30 down below
                    ; ASCII letters start 0x61 for "a" characters after 
                    ; decimal numbers. We need to cover that distance. 
  jl set_letter

set_letter:
  add al, 0x30      ; For and ASCII number, add 0x30
  mov byte [bx],al  ; Add the value of the byte to the char at bx

  cmp cx,0          ; check the counter, compare with 0
  je print_hex_done ; if the counter is 0, finish
  jmp char_loop     ; otherwise, loop again

print_hex_done:
  mov bx, HEX_OUT   ; print the string pointed to by bx
  call print

  popa              ; pop the initial register values back from the stack
  ret               ; return the function

HEX_OUT: db '0x0000', 0
