: LITERAL IMMEDIATE
    ' LIT ,
    ,
;

: '"' [ CHAR " ] LITERAL ;

: IF IMMEDIATE
    ' 0BRANCH ,
    HERE @
    0 ,
;

: ELSE IMMEDIATE
    ' BRANCH ,
    HERE @
    0 ,
    SWAP
    DUP
    HERE @ SWAP -
    SWAP !
;

: THEN IMMEDIATE
    DUP
    HERE @ SWAP -
    SWAP !
;

\ Loop Construct

: BEGIN IMMEDIATE
    HERE @
;

: WHILE IMMEDIATE
    ' 0BRANCH ,
    HERE @
    0 ,
;

: REPEAT IMMEDIATE
    ' BRANCH ,
    SWAP
    HERE @ - ,
    DUP
    HERE @ SWAP -
    SWAP !
;

: AGAIN IMMEDIATE
    ' BRANCH ,
    HERE @ -
    ,
;

: C,
    HERE @ C!
    1 HERE +!
;

: ALIGNED 7 + 7 INVERT AND ;

: ALIGN HERE @ ALIGNED HERE ! ;

: S" IMMEDIATE
    STATE @ IF
        ' LITSTRING ,
        HERE @
        0 ,
        BEGIN
            KEY
            DUP '"' <>
        WHILE
            C,
        REPEAT
        DROP
        DUP
        HERE @ SWAP -
        8-
        SWAP !
        ALIGN
    ELSE
        HERE @
        BEGIN
            KEY
            DUP '"' <>
        WHILE
            OVER C!
            1+
        REPEAT
        DROP
        HERE @ -
        HERE @
        SWAP
    THEN
;

: [COMPILE] IMMEDIATE
    WORD
    FIND
    >CFA
    ,
;

: ." IMMEDIATE
    STATE @ IF
        [COMPILE] S"
        ' TELL ,
    ELSE
        BEGIN
            KEY
            DUP '"' = IF
                DROP
                EXIT
            THEN
            EMIT
        AGAIN
    THEN
;

: FOO ." HELLO WORLD" ;

FOO
