!(import! &self fol-bc)
; !(bind! &kb (new-space))
!(import! &kb yaleshooting)
; !(import! &kb bec)
(= (query $goal)
    (backward-chain $goal &kb &kb)
)

; !(query (happens $f $t))
; !(query (time $t))
; !(query (holdsAt $f $t))
; !(backward-chain (time $t) &kb &kb)

(= (foo $goal)
   (case $goal (
    ((is $a $b) (trace! (got is $goal) (let $a $b (is $a $b)))) ;; prolog eval & assign
    ((bool $expr) (if $expr True (empty))) ;; if predicate is a boolean. This might be unnecessary
    ((naf $expr) (if (has-match $kb $goal) (empty) True)) ;; negation-as-failure
    ; ($_ (match $kb $goal $goal))
    ($_ (none))
   ))
)
!(foo (time $x))