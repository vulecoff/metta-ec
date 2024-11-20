
;; TODO: how to levarage native MeTTa for typing?

;; predicates: clear/1, on-table/1, arm-empty, holding/1, on/2

(:object ball) (:object table)
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

;; unify a list of args with list of parameters variable
(= (substitute () $params) 
    (if (not (== $params ()))  
        (Error $params IncompatibleLength)
        (empty)
    )
)
(= (substitute $args ())
    (if (not (== $args ()))
        (Error $args IncompatibleLength)
        (empty)
    )
)
(= (substitute $args $params)
    (if (xor (== $args ()) (== $params ()))
        (empty)
        (if (and (== $args ()) (== $params ())) 
            ()
            (let* (
                (($argsH $argsT) (decons-atom $args))
                (($paramsH $paramsT) (decons-atom $params))
                ($subst (substitute $argsT $paramsT))
                )
            (unify $argsH $paramsH (cons-atom $argsH $subst) (Error $args FailedUnification)))
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

(= (action-applicable $stateId $actionId $args)
    (match &self (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    )  (let $params (substitute $args $params) 
                (formula-satisfaction $stateId $preds)))
)

;; (:object x) TODO: object typing, how to only extract objects with potential updating? in a state?
(= (args-combination $params)
    (if (== $params ()) ()
        (let* (
            (($_ $rest) (decons-atom $params))
            ($h (match &self (:object $o) $o))
            ($r (args-combination $rest))
        ) (cons-atom $h $r))
    )
)

;; for each action & combination of args, try if its precondition is satisfied in state
(= (actions-applicable $stateId)
    (match &self (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    ) (let* (
        ($args (args-combination $params))
        ($params (substitute $args $params))
        ) (if (formula-satisfaction $stateId $preds) ($actionId $params) (empty))
    ))
)

;; state fluents must all be grounded, TODO: semantics for non-ground state?
(State 1 (clear ball)) (State 1 (on-table ball)) (State 1 (arm-empty))

!(formula-satisfaction 1 (clear ball))
!(formula-satisfaction 1 (Not (holding ball)))
!(formula-satisfaction 1 (Or ((clear ball) (holding ball))))
!(formula-satisfaction 1 (And ((clear ball) (Not (holding ball)))))
!(formula-satisfaction 1 
    (Or ((arm-empty) (And ((holding ball) (clear ball)))))
)

!(action-applicable 1 pickup (ball))
!(action-applicable 1 putdown (ball))
!(actions-applicable 1)