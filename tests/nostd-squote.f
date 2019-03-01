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

: THEN IMMEDIATE
    DUP
    HERE @ SWAP -
    SWAP !
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

: ALIGNED
    7 + 7 INVERT AND
;

: ALIGN HERE @ ALIGNED HERE ;

: C,
    HERE @ C!
    1 HERE +!
;

: S" IMMEDIATE
    STATE @ IF
        ' LITSTRING ,
        HERE @
        @ ,
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

S" HELLO WORLD"
