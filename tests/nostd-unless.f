: NOT 0= ;

: [COMPILE] IMMEDIATE
    WORD
    FIND
    >CFA
    ,
;

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

: UNLESS IMMEDIATE
    ' NOT ,
    [COMPILE] IF
;
