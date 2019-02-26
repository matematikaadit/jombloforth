: STAR
    42
    EMIT
;

: MAIN IMMEDIATE
    ' STAR ,
    ' BRANCH ,
    -16 ,
;

: foo
  MAIN
;

foo
