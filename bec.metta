;; Basic event calculus axioms


;; how to deal with constraints?
((stoppedIn $t1 $f $t2) :- (
    (bool (< $t1 $t))
    (bool (< $t $t2))
    (terminates $e $f $t)
    (happens $e $t)
))

((stoppedIn $t1 $f $t2) :- (
    (bool (< $t1 $t))
    (bool (< $t $t2))
    (releases $e $f $t)
    (happens $e $t)
))