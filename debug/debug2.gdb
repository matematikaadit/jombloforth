set confirm off
set disassembly-flavor intel
file jombloforth
break _WORD.word
run < tests/nostd-character-at.f
layout asm
display/c $al
define nextstack
   next
   x/8xg $rsp
end

