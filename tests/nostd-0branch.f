: STAR 42 EMIT ;

: [0REPEAT] IMMEDIATE
	    ' STAR ,
	    ' DUP ,
	    ' 0BRANCH ,
	    -24 ,
;

: MAIN
  1
  [0REPEAT]
;

: ALTERNATIVE \ this will repeat
  0
  [0REPEAT]
;

MAIN
