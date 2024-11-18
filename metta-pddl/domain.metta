
(:action pickup 
    :parameters ($x)
    :precondition (And (clear $x) (on-table $x) (arm-empty))
    :effect (And (holding $x) (Not (clear $x)) 
        (Not (on-table $x)) (Not (arm-empty))
    )
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
; !(substitute ($x $y $z) (1 2 3))
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

!(ground-action pickup (ball))

; (= (applicable $stateId $actionId)
    
; )