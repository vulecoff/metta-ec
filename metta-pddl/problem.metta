
;; predicates: clear/1, on-table/1, arm-empty, holding/1, on/2

;; solved for 2 objects, 5 predicates; with 3 objects, take painstakingly long
(:object a) (:object b)
(:object c) ;;
(:init (
    (on-table a)
    (on-table b)
    (clear a)
    (clear b)
    (arm-empty)
    (on-table c) (clear c) ;;
))
(:goal (And (
    (on a b)
    (on b c) ;;
)))

(:action pickup 
    :parameters ($x)
    :precondition (And ((clear $x) (on-table $x) (arm-empty)))
    :effect (And ((holding $x) (Not (clear $x)) 
        (Not (on-table $x)) (Not (arm-empty)))
    )
)
(:action putdown
    :parameters ($x)
    :precondition (And ((holding $x)))
    :effect (And ((clear $x) (arm-empty) (on-table $x)
        (Not (holding $x))))
)

(:action stack
    :parameters ($x $y)
    :precondition (And (
        (clear $y) (holding $x)
    ))
    :effect (And (
        (arm-empty) (clear $x) (on $x $y) 
        (Not (clear $y)) (Not (holding $x))
    ))
)

(:action unstack
    :parameters ($x $y)
    :precondition (And ((on $x $y) (clear $x) (arm-empty)))
    :effect (And (
        (holding $x) (clear $y) (Not (on $x $y))
        (Not (clear $x)) (Not (arm-empty))
    ))
)

; (= (stress-stack $x)
;     (if (> $x 600) ()
;         (let* (
;             ($y (+ 1 $x))
;             ($m (% $x 100))
;             (() (if (== $m 0) (println! $x) ()))
;             ($rest (stress-stack $y))
;         ) (cons-atom $x $rest))
;     )
; )
; !(stress-stack 0)