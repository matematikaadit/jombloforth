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
    HERE @ -
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

\ Comments
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

( Now we can nest ( ... ) as much as we want )

\ Stack Manipulation
: NIP ( x y -- y ) SWAP DROP ;
: TUCK ( x y -- y x y ) SWAP OVER ;
: PICK ( x_u ... x_1 x_0 u -- x_u ... x_1 x_0 x_u )
    1+
    8 * ( multiply by the word size )
    DSP@ +
    @
;

\ Writes N spaces to stdout
: SPACES ( n -- )
    BEGIN
        DUP 0>
    WHILE
        SPACE
        1-
    REPEAT
    DROP
;

\ EXTRA: Writes N zeroes to stdout
: ZEROES ( n -- )
    BEGIN
        DUP 0>
    WHILE
        '0' EMIT
        1-
    REPEAT
    DROP
;

\ Standard word for manipulating BASE.
: DECIMAL ( -- ) 10 BASE ! ;
: HEX ( -- ) 16 BASE ! ;

( Printing Numbers )

: U. ( u -- )
    BASE @ /MOD
    ?DUP IF       ( if quotient <> 0 then )
        RECURSE   ( print the quotient )
    THEN

    ( print the remainder )
    DUP 10 < IF
        '0'
    ELSE
        10 -
        'A'
    THEN
    +
    EMIT
;

( Printing the content of the stack )
: .S ( -- )
    DSP@
    BEGIN
        DUP S0 @ <
    WHILE
        DUP @ U.
        SPACE
        8+
    REPEAT
    DROP
;

( Returns the width of an unsigned number (in characters) in the current base )
: UWIDTH
    BASE @ /
    ?DUP IF
        RECURSE 1+
    ELSE
        1
    THEN
;

: U.R ( u width -- )
    SWAP
    DUP
    UWIDTH
    ROT
    SWAP -
    SPACES
    U.
;

\ EXTRA, print zeroes padded unsigned number
: ZU.R ( u width -- )
    SWAP
    DUP
    UWIDTH
    ROT
    SWAP -
    ZEROES
    U.
;

: .R ( n width -- )
    SWAP ( width n )
    DUP 0< IF
        NEGATE ( width u )
        1      ( save flag to remember that it was negative | width u 1 )
        SWAP   ( width 1 u )
        ROT    ( 1 u width )
        1-     ( 1 u width-1 )
    ELSE
        0      ( width u 0 )
        SWAP   ( width 0 u )
        ROT    ( 0 u width )
    THEN
    SWAP   ( flag width u )
    DUP    ( flag width u u )
    UWIDTH ( flag width u uwidth )
    ROT    ( flag u uwidth width )
    SWAP - ( flag u width-uwidth )

    SPACES ( flag u )
    SWAP   ( u flag )

    IF
        '-' EMIT
    THEN
    U.
;

( Finally )
: . 0 .R SPACE ;

( The real U. )
: U. U. SPACE ;

: ? ( addr -- ) @ . ;

: WITHIN ( c a b - f )
    -ROT ( b c a )
    OVER ( b c a c )
    <= IF
        > IF ( b c )
            TRUE
        ELSE
            FALSE
        THEN
    ELSE
        2DROP
        FALSE
    THEN
;

: DEPTH ( -- n )
    S0 @ DSP@ -
    8-
;

: ALIGNED ( addr -- addr )
    7 + 7 INVERT AND
;

: ALIGN HERE @ ALIGNED HERE ! ;

: C,
    HERE @ C!
    1 HERE +!
;

: S" IMMEDIATE ( -- addr len )
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

( Constant and Variables )

: CONSTANT
    WORD
    CREATE
    DOCOL ,
    ' LIT ,
    ,
    ' EXIT ,
;

: ALLOT ( n -- addr )
    HERE @ SWAP
    HERE +!
;

: CELLS ( n -- n ) 8 * ;

: VARIABLE
    1 CELLS ALLOT
    WORD CREATE
    DOCOL ,
    ' LIT ,
    ,
    ' EXIT ,
;

: VALUE ( n -- )
    WORD CREATE
    DOCOL ,
    ' LIT ,
    ,
    ' EXIT ,
;

: TO IMMEDIATE ( n -- )
    WORD
    FIND
    >DFA
    8+
    STATE @ IF
        ' LIT ,
        ,
        ' ! ,
    ELSE
        !
    THEN
;

: +TO IMMEDIATE
    WORD
    FIND
    >DFA
    8+
    STATE @ IF
        ' LIT ,
        ,
        ' +! ,
    ELSE
        +!
    THEN
;

: ID. ( addr -- )
    8+
    DUP C@
    F_LENMASK AND
    BEGIN
        DUP 0>
    WHILE
        SWAP 1+
        DUP C@
        EMIT
        SWAP 1-
    REPEAT
    2DROP ( len addr -- )
;

: ?HIDDEN
    8+
    C@
    F_HIDDEN AND
;

: ?IMMEDIATE
    8+
    C@
    F_IMMED AND
;

: WORDS
    LATEST @
    BEGIN
        ?DUP
    WHILE
        DUP ?HIDDEN NOT IF
            DUP ID.
            SPACE
        THEN
        @
    REPEAT
    CR
;

: FORGET
    WORD FIND
    DUP @ LATEST !
    HERE !
;

: DUMP ( addr len -- )
    BASE @ -ROT
    HEX

    BEGIN
        ?DUP           ( while len > 0 )
    WHILE
        OVER 8 ZU.R    ( print the address )
        SPACE
        ( print up to 16 words on this line )
        2DUP           ( addr len addr len )
        1- 15 AND 1+   ( addr len addr linelen )
        BEGIN
            ?DUP       ( while linelen > 0 )
        WHILE
            SWAP       ( addr len linelen addr )
            DUP C@     ( addr len linelen addr byte )
            2 ZU.R SPACE ( print the byte )
            1+ SWAP 1- ( addr len linelen addr -- addr len addr+1 linelen-1 )
        REPEAT
        DROP           ( addr len )

        ( print the ASCII equivalents )
        2DUP 1- 15 AND 1+ ( addr len addr linelen )
        BEGIN
            ?DUP
        WHILE
            SWAP       ( addr len linelen addr )
            DUP C@     ( addr len linelen addr byte )
            DUP 32 128 WITHIN IF ( 32 <= c < 128? )
                EMIT
            ELSE
                DROP '.' EMIT
            THEN
            1+ SWAP 1-
        REPEAT
        DROP
        CR
        DUP 1- 15 AND 1+
        TUCK
        -
        >R + R>
    REPEAT
    DROP
    BASE !
;

: CASE IMMEDIATE
    0
;

: OF IMMEDIATE
    ' OVER ,
    ' = ,
    [COMPILE] IF
    ' DROP ,
;

: ENDOF IMMEDIATE
    [COMPILE] ELSE
;

: ENDCASE IMMEDIATE
    ' DROP ,
    BEGIN
        ?DUP
    WHILE
        [COMPILE] THEN
    REPEAT
;

: CFA>
    LATEST @
    BEGIN
        ?DUP
    WHILE
        2DUP SWAP
        < IF
            NIP
            EXIT
        THEN
        @
    REPEAT
    DROP
    0
;

: SEE
    WORD FIND
    HERE @
    LATEST @

    BEGIN
        2 PICK
        OVER
        <>
    WHILE
        NIP
        DUP @
    REPEAT

    DROP
    SWAP

    ':' EMIT SPACE DUP ID. SPACE
    DUP ?IMMEDIATE IF ." IMMEDIATE " THEN

    >DFA

    BEGIN             ( end start )
        2DUP >
    WHILE
        DUP @         ( end start codeword )
        CASE
        ' LIT OF      ( is it LIT ? )
            8 + DUP @ ( get next word )
            .         ( and print it )
        ENDOF
        ' LITSTRING OF
            [ CHAR S ] LITERAL EMIT '"' EMIT SPACE ( print S"<space> )
            8 + DUP @                              ( get the length )
            SWAP 8 + SWAP                          ( end start+8 length )
            2DUP TELL                              ( print the string )
            '"' EMIT SPACE
            + ALIGNED                              ( end start+8+len, aligned )
            8 -                                    ( because we're about to add 8 below )
        ENDOF
        ' 0BRANCH OF
            ." 0BRANCH ( "
            8 + DUP @
            .
            ." ) "
        ENDOF
        ' BRANCH OF
            ." BRANCH ( "
            8 + DUP @
            .
            ." ) "
        ENDOF
        ' ' OF
            [ CHAR ' ] LITERAL EMIT SPACE
            8 + DUP @
            CFA>
            ID. SPACE
        ENDOF
        ' EXIT OF
            2DUP
            8 +
            <> IF
                ." EXIT "
            THEN
        ENDOF
            DUP
            CFA>
            ID. SPACE
        ENDCASE
        8 +
    REPEAT
    ';' EMIT CR
    2DROP
;

: :NONAME
    0 0 CREATE
    HERE @
    DOCOL ,
    ]
;

: ['] IMMEDIATE
    ' LIT ,
;


