\ Part 2 of the JonesForth tutorial.
\ This one is added word-by-word as they are succesfully executed

\ Define / and MOD in terms of /MOD
: / /MOD SWAP DROP ;
: MOD /MOD DROP ;

\ Some char constant
: '\n' 10 ;
: BL 32 ; \ BL (blank) is standard FORTH word for space.

: CR '\n' EMIT ;
: SPACE BL EMIT ;

: NEGATE 0 SWAP - ;

: TRUE 1 ;
: FALSE 0 ;
: NOT 0= ;

\ LITERAL takes whatever on the stack and compiles LIT <foo>
: LITERAL IMMEDIATE
    ' LIT ,
    ,
;

: ':'
    [
    CHAR :
    ]
    LITERAL
;

: ';' [ CHAR ; ] LITERAL ;
: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;
: '"' [ CHAR " ] LITERAL ;
: 'A' [ CHAR A ] LITERAL ;
: '0' [ CHAR 0 ] LITERAL ;
: '-' [ CHAR - ] LITERAL ;
: '.' [ CHAR . ] LITERAL ;

: [COMPILE] IMMEDIATE
    WORD
    FIND
    >CFA
    ,
;

: RECURSE IMMEDIATE
    LATEST @
    >CFA
    ,
;

\ Conditionals Statements

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

\ Loop Construct


: BEGIN IMMEDIATE
    HERE @
;

: UNTIL IMMEDIATE
    ' 0BRANCH ,
    HERE @ -
    ,
;

: AGAIN IMMEDIATE
    ' BRANCH ,
    HERE @
    ,
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
