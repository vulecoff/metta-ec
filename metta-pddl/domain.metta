
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


;; check if an action is applicable in a state
(= (action-applicable $stateId $actionId $args)
    (match &self (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    )  (unify $args $params 
            (formula-satisfaction $stateId $preds) 
            (Error $params FailedUnification)))
)

;; (:object x) TODO: object typing, how to only extract objects with potential updating? in a state?
;; all possible grounding for a variable ~ objects
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
        ($_ (unify $args $params True (Error $params FailedUnification)))
        ) (if (formula-satisfaction $stateId $preds) ($actionId $params) (empty))
    ))
)

(= (action-applyEffect $actionId $args)
    (match &self (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    ) (unify $args $params $effs FailedUnification))
)


(= (is-in $item $list) 
    (if (== $list ()) 
        False
        (let ($H $T) (decons-atom $list) 
            (if (== $H $item) True (is-in $item $T))
        )
    )
)
(= (signed-fluents $list)
    (if (== $list ())
        (() ())
        (let* (
            (($h $rest) (decons-atom $list))
            (($pos $neg) (signed-fluents $rest))
            (($isNeg $f) (unify $h (Not $v) (True $v) (False $h)))
        ) (if $isNeg 
            ($pos (cons-atom $f $neg))
            ((cons-atom $f $pos) $neg)
        ))
    )
)

;; diffing algorithm? 
(= (state-diff-update $allStates $diffs)
    (let* (
        ((And $d) $diffs)
        (($pos $neg) (signed-fluents $d))
        ($s1 (collapse (subtraction  ;; remove negative fluents
            (superpose $allStates)
            (superpose $neg)
        )))
        ($s2 (collapse (union  ;; add any positive fluents
            (superpose $s1)
            (superpose $pos)
        )))
    )  $s2)
)
(= (state-transition $stateId) ;; adding state directly, or return state?
    (let* (
        (($actionId $args) (actions-applicable $stateId))
        ($effsDiff (action-applyEffect $actionId $args))
        ($stsEffs (collapse (match &self (State $stateId $form) $form)))
    ) (state-diff-update $stsEffs $effsDiff))
)

(= (goal-satisfied $stateId)
    (match &self (:goal $expr) (formula-satisfaction $stateId $expr))
)

;; Performance note: use space for global state versus pass as arguments, 
;; depends on complexity of (match)

!(import! &self lib)

;; with max depth, 
; (= (fw-st ))


;; process current state, then add bunches to queue, return new queue
; (= (enqueue-next-states $curQ $nextStates $nextStateId)
;     (if (== $states ())
;         $curQ
;         (let* (
;             ($q (insert-queue $curQ $nextStateId))
;             ($id (+ $nextStateId 1))
;         ) )
;     )
; )

;; NEXT: modularize space

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

!(state-transition 1)