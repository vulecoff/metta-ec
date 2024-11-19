
;; TODO: how to levarage native MeTTa for typing?
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

;; experimenting with interpreting action
(= (substitute () $params) 
    (if (not (== $params ()))  
        (Error $params IncompatibleLength)
        (empty)
    )
)
(= (substitute $args ())
    (if (not (== $args ()))
        (Error $params IncompatibleLength)
    )
)
(= (substitute $args $params)
    (if (and (== $args ()) (== $params ()))
        ()
        (let* (
            (($argsH $argsT) (decons-atom $args))
            (($paramsH $paramsT) (decons-atom $params))
            ($subst (substitute $argsT $paramsT))
            )
        (if-error $subst $subst 
            (unify $argsH $paramsH (cons-atom $argsH $subst) (Error $args FailedUnification)))
        )
    )
)

(= (ground-action $actionId $args)
    (match &self
        (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
        )
        (let $params (substitute $args $params)
            (OUT (preds $preds) (effs $effs))
        )
    )
)

;; (State id fluent) ;; only true fluent

;; check satisfaction of a ground formula
(= (formula-satisfaction $stateId (Not $expr))
    (not (formula-satisfaction $stateId $expr))
)
(= (formula-satisfaction $stateId (Or $exprList))
    (if (== $exprList ())
        False
        (let* (
            (($head $rest) (decons-atom $exprList))
            ($v (formula-satisfaction $stateId $head))
            ) (if $v True (or $v (formula-satisfaction $stateId (Or $rest)))))
    )
)
(= (formula-satisfaction $stateId (And $exprList))
    (if (== $exprList ())
        True
        (let* (
            (($head $rest) (decons-atom $exprList))
            ($v (formula-satisfaction $stateId $head))
            ) (if (not $v) False (and $v (formula-satisfaction $stateId (And $rest)))))
    )
)

(= (formula-satisfaction $stateId $expr) ;; base case, match positive fluent
    (case $expr (
        ((And $x) (empty))
        ((Or $x) (empty))
        ((Not $x) (empty))
        ($_ (let $all (collapse (match &self (State $stateId $expr) True))
                (if (== $all ()) False True)))
    ))
)



; (= (applicable $stateId $actionId)
    
; )

;; satisfaction: try all possible object suitable for the action, 
; !(ground-action pickup (ball))


;; state fluents must all be grounded, semantics for non-ground state?
(State 1 (clear ball)) (State 1 (on-table ball)) (State 1 (arm-empty))

!(formula-satisfaction 1 (clear ball))
!(formula-satisfaction 1 (Not (holding ball)))
!(formula-satisfaction 1 (Or ((clear ball) (holding ball))))
!(formula-satisfaction 1 (And ((clear ball) (Not (holding ball)))))
!(formula-satisfaction 1 
    (Or ((arm-empty) (And ((holding ball) (clear ball)))))
)
