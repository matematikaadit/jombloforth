set confirm off
set disassembly-flavor intel
file jombloforth
break _WORD.word
run < jombloforth.f
layout asm
layout regs
display/x $rsp
display/x $rsi
display/x $rdi
display/c $rax
display/s {char[32]}0x601559
display/i $pc
define nextstack
   next
   x/8xg $rsp
end
continue 1502