: BEGIN IMMEDIATE
    HERE @
;

: UNTIL IMMEDIATE
    ' 0BRANCH ,
    HERE @ -
    ,
;

\ print number
: PUTS 48 + EMIT 10 EMIT ;

\ print 9 down to 1
: MAIN
    10
    1-
    DUP
    0BRANCH
    -16
    DROP
;

MAIN
