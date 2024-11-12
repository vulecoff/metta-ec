;; Extremely simplified event calculus with deductive temporal projection task
;; No constraints or preconditions

(: InitiallyP (-> Atom Atom))
(: InitiallyN (-> Atom Atom))
(: Holds (-> Atom Number Atom))
(: Happens (-> Atom Number Atom))
(: Initiates (-> Atom Atom Atom))
(: Terminates (-> Atom Atom Atom))

;; TODO: use with limit, we only need check at least 1
(= (has-match $space $pattern)
    (let $all (collapse (match $space $pattern True))
        (if (== $all ())
            False True
        )
    )
)

(: add-holds! (-> Grounded Atom Atom Number (->)))
(= (add-holds! $kb $fluent $TrueOrFalse $time)
    (if (or 
            (== $fluent NIL) 
            (has-match $kb (Holds ($fluent := $TrueOrFalse) $time))) 
        ()
        (add-atom $kb (Holds ($fluent := $TrueOrFalse) $time)))
)

(: add-holds-list! (-> Grounded Expression Atom Number (->)))
(= (add-holds-list! $kb $fluents $TrueOrFalse $time)
    (if (== $fluents ())
        ()
        (let* (
            (($head $rest) (decons-atom $fluents))
            (() (add-holds! $kb $head $TrueOrFalse $time))
        ) (add-holds-list! $kb $rest $TrueOrFalse $time))
    )
)

(: temporal-project-helper! (-> Grounded Number Number (->)))
(= (temporal-project-helper! $kb 0 $maxTime)
    (let* (
        ($posFluents (collapse (match $kb (InitiallyP $x) $x)))
        ($negFluents (collapse (match $kb (InitiallyN $y) $y)))
        (() (add-holds-list! $kb $posFluents true 0))
        (() (add-holds-list! $kb $negFluents false 0)) 
    ) (temporal-project-helper! $kb 1 $maxTime))
)
(= (temporal-project-helper! $kb $t $maxTime)
    (if (or (== $t 0) (> $t $maxTime))  ()
        (let* (
            ($tp (- $t 1))
            ;; if initiated
            ($posFluents (collapse (match $kb
                (, (Happens $ep $tp)
                    (Initiates $ep $fp)
                ) $fp
            )))
            (() (add-holds-list! $kb $posFluents true $t))

            ;; iertia for pos fluents
            ($prevPosFluents (collapse (match $kb (Holds ($fp1 := true) $tp) $fp1)))
            ($1_ (map-atom $prevPosFluents $posF1 (let ()
                (if (has-match $kb (, (Happens $ep1 $tp) (Terminates $ep1 $posF1)))
                    ()
                    (add-holds! $kb $posF1 true $t)
                )
                ()
            )))
            
            ;; if terminated
            ($negFluents (collapse (match $kb
                (, (Happens $en $tp)
                    (Terminates $en $fn)
                ) $fn
            )))
            (() (add-holds-list! $kb $negFluents false $t))

            ($prevNegFluents (collapse (match $kb (Holds ($fn1 := false) $tp) $fn1)))
            ($2_ (map-atom $prevNegFluents $negF1 (let ()
                (if (has-match $kb (, (Happens $en1 $tp) (Terminates $en1 $negF1)))
                    ()
                    (add-holds! $kb $negF1 true $t)
                )
                ()
            )))
            ;; TODO: investingate scope and name conflicts? 


        ) (temporal-project-helper! $kb (+ 1 $t) $maxTime))
    )
)

(= (temporal-project! $kb $maxTime)
    (temporal-project-helper! $kb 0 $maxTime)
)

;; Problem Encoding
(InitiallyP Unloaded) (InitiallyP Alive)
(Initiates Load Loaded) (Terminates Load Unloaded)
(Initiates Shoot Dead) (Terminates Shoot Alive)
(Initiates Shoot Unloaded) (Terminates Shoot Loaded)
(Happens Load 1) (Happens Wait 2) (Happens Shoot 3)

!(temporal-project! &self 4)

!(match &self 
    (, (Holds ($f := true) $t)
        (Holds ($f := false) $t)
    )
    (Error $f ContradictingFluent)
)

!(match &self (Holds ($f := true) $t) (Holds ($f := true) $t))
!(match &self (Holds ($f := false) $t) (Holds ($f := false) $t))