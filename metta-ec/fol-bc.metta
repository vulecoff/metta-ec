;; First-order logic backward chainer using match

;; Note: this only works within Mettalog.
;; Multi-directional variable binding is still buggy in Hyperon

;; Base case
(= (backward-chain $goal $kb $rb)
   (case $goal (
    ((is $a $b) (let $a $b (is $a $b)))
    ((bool $expr) (if $expr True (empty)))
    ($_ (match $kb $goal $goal))
   ))
)

;; Recursive Case
(= (backward-chain $goal $kb $rb)
    (match $rb ($goal :- $body)
        (match-body $body $kb $rb $goal)
    )
)

;; do matching for each atom in the body, then returns goal
(= (match-body $body $kb $rb $goal)
    (if (== $body ())
        $goal
        (let* (
            (($cur $rest) (decons-atom $body))
            ($ok (backward-chain $cur $kb $rb)) ;; buggy place in hyperon, lets lack multi-directional binding
            ; (() (println! (out $cur $goal)))
        ) (if (== $ok (empty))
            (empty)
            (match-body $rest $kb $rb $goal)
        ))
    )
)

