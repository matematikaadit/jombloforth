: START IMMEDIATE
    HERE @
;

: FINISH IMMEDIATE
    ' LIT ,
    HERE @ -
    ,
;

: NOP ;

: MAIN
    START
    NOP
    NOP
    FINISH
;

MAIN
0 SWAP -
CHAR 0 +
EMIT
10
EMIT
