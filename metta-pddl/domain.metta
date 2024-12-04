
;; TODO: how to levarage native MeTTa for typing?

;; predicates: clear/1, on-table/1, arm-empty, holding/1, on/2

;; solved for 2 objects, 5 predicates; with 3 objects, take painstakingly long
(:object a) (:object b)
(:init (
    (on-table a)
    (on-table b)
    (clear a)
    (clear b)
    (arm-empty)
))
(:goal (And (
    (on a b)
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
        ($1 (let $all (collapse (match &self (State $stateId $expr) True))
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
            (($1 $rest) (decons-atom $params))
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
        ($1 (unify $args $params True (Error $params FailedUnification)))
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
(= (state-diff $allStates $diffs)
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


;; a list of atom to add for the next non-determinisitc state (out of all possible states)
(= (state-transition $stateId) 
    (let* (
        (($actionId $args) (actions-applicable $stateId))
        ($effsDiff (action-applyEffect $actionId $args))
        ($stsEffs (collapse (match &self (State $stateId $form) $form)))
    ) (state-diff $stsEffs $effsDiff))
)

(= (goal-satisfied $stateId)
    (match &self (:goal $expr) (formula-satisfaction $stateId $expr))
)

;; Performance note: use space for global state versus pass as arguments, 
;; depends on complexity of (match)

; !(import! &self list.metta)
(import! &self list)

(= (add-state-fluents! $stateId $fluents)
    (if (== $fluents ())
        ()
        (let* (
            (($h $rest) (decons-atom $fluents))
            (() (add-atom &self (State $stateId $h)))
        ) (add-state-fluents! $stateId $rest))
    )
)

;; for each next state, add its fluents and enqueue id
(= (enqueue-next-states! $curQ $states $nextUID)
    (if (== $states ())
        ($curQ $nextUID)
        (let* (
            (($stateFluents $rest) (decons-atom $states))
            (() (add-state-fluents! $nextUID $stateFluents))
            ($q (L-push-back $curQ $nextUID))
            ($id (+ $nextUID 1))
        ) (enqueue-next-states! $q $rest $id))
    )
)

(= (fw-state-search $queue $nextUID $statesLimit)
    (if (L-empty? $queue)   FailedToReachGoal
    (if (>= $nextUID $statesLimit)  (Error $statesLimit "Limit of states exploration reached.")   
        (let $curState (L-front $queue) 
            (let () (println! (Processing $curState (collapse (match &self (State $curState $f) $f))))
                (if (goal-satisfied $curState)
                GoalReached
                (let* (
                    ($q1 (L-pop-front $queue))
                    ($nextStates (collapse (state-transition $curState)))
                    (($q2 $uid) (enqueue-next-states! $q1 $nextStates $nextUID))
                ) (fw-state-search $q2 $uid $statesLimit))
            ) )
        ))
    )
)

(= (planner-main $statesLimit)
    (let* (
        ($initState (match &self (:init $f) $f))
        (($initQ $nextUID) (enqueue-next-states! () ($initState) 0))
    ) 
    ; ()
    (fw-state-search $initQ $nextUID $statesLimit)
    )
)


;; NEXT: modularize space

;; state fluents must all be grounded, TODO: semantics for non-ground state?
(State 1 (clear b)) (State 1 (on-table b)) (State 1 (arm-empty))

!(formula-satisfaction 1 (clear b))
!(formula-satisfaction 1 (Not (holding b)))
!(formula-satisfaction 1 (Or ((clear b) (holding b))))
!(formula-satisfaction 1 (And ((clear b) (Not (holding b)))))
!(formula-satisfaction 1 
    (Or ((arm-empty) (And ((holding b) (clear b)))))
)

!(action-applicable 1 pickup (b))
!(action-applicable 1 putdown (b))
!(actions-applicable 1)

; !(state-transition 1)

; !(planner-main 100)

;; check state
; !(SignPost "Checking States starting here")
; !(match &self (State $id $expr) (State $id $expr))

; !(let* (
;     ($next (collapse (state-transition 0)))
;     (() (println! (OUT $next)))
;     ($out (enqueue-next-states! () $next 1))
;     (() (println! $out))
; ) (empty))