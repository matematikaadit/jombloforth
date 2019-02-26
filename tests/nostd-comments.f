\ Ingredients Needed:
\ - IF ELSE THEN
\ - BEGIN UNTIL
\ - '(' ')'

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

: UNTIL IMMEDIATE
    ' 0BRANCH ,
    HERE @ -
    ,
;

: LITERAL IMMEDIATE
    ' LIT ,
    ,
;

: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;

: ( IMMEDIATE
    1
    BEGIN
        KEY
        DUP '(' = IF
	    DROP
	    1+
	ELSE
	    ')' = IF
	        1-
            THEN
	THEN
    DUP 0= UNTIL
    DROP
;

( foo )
( this should compile fine )
( and nested ( ... ) should works too )
