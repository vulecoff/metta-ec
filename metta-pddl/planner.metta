
;; TODO: how to levarage native MeTTa for typing?

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
        ($1 (let $all (collapse (match &kb (State $stateId $expr) True))
                (if (== $all ()) False True)))
    ))
)

;; check if an action is applicable in a state
(= (action-applicable $stateId $actionId $args)
    (match &kb (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    )  (unf $args $params 
            (formula-satisfaction $stateId $preds) 
            (Error $params FailedUnification)))
)

;; (:object x) TODO: object typing, how to only extract objects with potential updating? in a state?
;; all possible grounding for a variable ~ objects
(= (args-combination $params)
    (if (== $params ()) ()
        (let* (
            (($1 $rest) (decons-atom $params))
            ($h (match &kb (:object $o) $o))
            ($r (args-combination $rest))
        ) (cons-atom $h $r))
    )
)

;; for each action & combination of args, try if its precondition is satisfied in state
(= (actions-applicable $stateId)
    (match &kb (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    ) (let* (
        ($args (args-combination $params))
        ($1 (unf $args $params True (Error $params FailedUnification)))
        ) (if (formula-satisfaction $stateId $preds) ($actionId $params) (empty))
    ))
)

(= (action-applyEffect $actionId $args)
    (match &kb (:action $actionId
            :parameters $params 
            :precondition $preds 
            :effect $effs
    ) (unf $args $params $effs FailedUnification))
)


(= (signed-fluents $list)
    (if (== $list ())
        (() ())
        (let* (
            (($h $rest) (decons-atom $list))
            (($pos $neg) (signed-fluents $rest))
            (($isNeg $f) (unf $h (Not $v) (True $v) (False $h)))
        ) (if $isNeg 
            ($pos (cons-atom $f $neg))
            ((cons-atom $f $pos) $neg)
        ))
    )
)

;; diffing algorithm? 
(= (state-diff-1 $allStates $diffs)
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

(= (diff-2-update-pos $allStates $pos)
    (if (== $pos ())
        $allStates
        (let* (
            (($h $rest) (decons-atom $pos))
            ($diffed (diff-2-update-pos $allStates $rest))
        ) 
            (if (L-contains? $allStates $h)
                (Error $h "Attempting to add an existing state fluent")
                (cons-atom $h $diffed)
            )
        )
    )
)
(= (diff-2-update-neg $allStates $neg)
    (if (== $allStates ())
        ()
        (let* (
            (($h $t) (decons-atom $allStates))
            ($diffed (diff-2-update-neg $t $neg))
        ) (if (L-contains? $neg $h)
            $diffed
            (cons-atom $h $diffed)
        ))
    )
)

(= (state-diff-2 $allStates $diffs)
     (let* (
        ((And $d) $diffs)
        (($pos $neg) (signed-fluents $d))
        ($s1 (diff-2-update-pos $allStates $pos))
        ($s2 (diff-2-update-neg $s1 $neg))
    )  $s2)
)

;; dummy
(= (state-diff $allStates $diff)
    (let* (
        ($s1 (state-diff-1 $allStates $diff))
        ; ($s2 (state-diff-2 $allStates $diff))
    ) $s1
    ; (if (L-seteq? $s1 $s2)
    ;     $s1
    ;     (Error ($s1 $s2) "Diffing algorithm mismatched"))
    )
)

;; a list of atom to add for the next non-determinisitc state (out of all possible states)
(= (state-transition $stateId) 
    (let* (
        (($actionId $args) (actions-applicable $stateId))
        ($effsDiff (action-applyEffect $actionId $args))
        ($stsEffs (collapse (match &kb (State $stateId $form) $form)))
        ($newState (state-diff $stsEffs $effsDiff))
    ) 
        ; $newState
        (if (== $newState ()) 
            (Error ($stateId $effsDiff $stsEffs) "Empty State") 
            (($actionId $args)  $newState)
        )
    )
)

(= (state-visited? $stateFluents)
    (if (== $stateFluents ()) ()
        (let* (
            (($h $rest) (decons-atom $stateFluents))
            ($included (collapse (match &kb (State $id $h) $id)))
        ) (if (== $rest ()) 
            $included 
            (let $other (state-visited? $rest) (L-intersection $included $other))
        ))
    )
)
(= (state-visited $stateId)
    (let $fs (collapse (match &kb (State $stateId $form) $form))
        (state-visited? $fs)
    )
)

(= (goal-satisfied $stateId)
    (match &kb (:goal $expr) (formula-satisfaction $stateId $expr))
)

(= (retrace-steps $toStateId)
    (if (== $toStateId 0)
        ()
        (let* (
            (($fromId $action $args) (match &kb 
                    (Succ $fromId ($action $args) $toStateId)
                    ($fromId $action $args)))
            ($prevSteps (retrace-steps $fromId))
        ) (L-push-back $prevSteps ($action $args)))
    )
)

;; Performance note: use space for global state versus pass as arguments, 
;; depends on complexity of (match)

!(import! &self alist)

(= (add-state-fluents! $stateId $fluents)
    (if (== $fluents ())
        ()
        (let* (
            (($h $rest) (decons-atom $fluents))
            (() (add-atom &kb (State $stateId $h)))
        ) (add-state-fluents! $stateId $rest))
    )
)

;; states = [(fluents) (fluents2)]
;; for each next state, add its fluents and enqueue id
(= (enqueue-next-states! $fromID $curQ $states $nextUID)
    (if (== $states ())
        ($curQ $nextUID)
        (let* (
            (($state $rest) (decons-atom $states))
            ((($action $args) $stateFluents) $state)
            ($visited (state-visited? $stateFluents))
            ; (() (println! (ENQUEING $nextUID $stateFluents $visited)))
        ) (if (== $visited ())  
            (let* (
                (() (add-state-fluents! $nextUID $stateFluents))
                (() (add-atom &kb (Succ $fromID ($action $args) $nextUID)))
                ($q (L-push-back $curQ $nextUID))
                ($id (+ $nextUID 1))
            ) (enqueue-next-states! $fromID $q $rest $id))

            (enqueue-next-states! $fromID $curQ $rest $nextUID)) ;; skipped
        ))
)

(= (fw-state-search $queue $nextUID $statesLimit) ;; CHECK VISITED STATE?
    (if (L-empty? $queue)   FailedToReachGoal
        (let $curState (L-front $queue) 
            (let () 
                    ()
                    ; (println! 
                    ;     (Processing $curState 
                    ;         (collapse (match &kb (State $curState $f) $f))
                    ;         (collapse (match &kb (Succ $from ($action $args) $curState) ($from ($action $args))))
                    ;         ; $queue
                    ;         (state-visited $curState)
                    ;     ))
                (if (goal-satisfied $curState) (retrace-steps $curState)
                (if (> $curState $statesLimit)  (Error $statesLimit "Limit of states exploration reached.")   
                (let* (
                    ($q1 (L-pop-front $queue))
                    ($nextStates (collapse (state-transition $curState)))
                    (($q2 $uid) (enqueue-next-states! $curState $q1 $nextStates $nextUID))
                ) (fw-state-search $q2 $uid $statesLimit))
            )))
        )
    )
)

(= (planner-main $statesLimit)
    (let* (
        ($initState ((None None) (match &kb (:init $f) $f)))
        (($initQ $nextUID) (enqueue-next-states! -1 () ($initState) 0))
    ) 
    ; ()
    (fw-state-search $initQ $nextUID $statesLimit)
    )
)


;; NEXT: modularize space

(= (unf $x $y $s $f)
    (let $unf (collapse 
        (let $x $y True)
    ) (if (== $unf ()) $f (let $x $y $s)))
)

;; state fluents must all be grounded, TODO: semantics for non-ground state?
; !(add-atom &kb (State 1 (clear b))) 
; !(add-atom &kb (State 1 (on-table b)))
; !(add-atom &kb (State 1 (arm-empty)))
; !(state-visited? ((clear b) (on-table b) (arm-empty)))

; !(formula-satisfaction 1 (clear b))
; !(formula-satisfaction 1 (Not (holding b)))
; !(formula-satisfaction 1 (Or ((clear b) (holding b))))
; !(formula-satisfaction 1 (And ((clear b) (Not (holding b)))))
; !(formula-satisfaction 1 
;     (Or ((arm-empty) (And ((holding b) (clear b)))))
; )

; !(action-applicable 1 pickup (b))
; !(action-applicable 1 putdown (b))
; !(actions-applicable 1)

; !(state-transition 1)
!(import! &kb domain)
!(import! &kb task1)
!(planner-main 100)



