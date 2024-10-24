;; Basic event calculus axioms without constraints


((stoppedIn $t1 $f $t2) :- (
    (time $t1) (time $t2)
    (bool (< $t1 $t))
    (bool (< $t $t2))
    (terminates $e $f $t)
    (happens $e $t)
))

((stoppedIn $t1 $f $t2) :- (
    (time $t1) (time $t2)
    (bool (< $t1 $t))
    (bool (< $t $t2))
    (releases $e $f $t)
    (happens $e $t)
))

((holdsAt $f2 $t2) :- (
    (time $t2) (time $t1)
    (initiates $e $f1 $t1)
    (happens $e $t1)
    (naf (stoppedIn $t1 $f1 $t2))
))

((holdsAt $f $t) :- (
    (time $t)
    (bool (< 0 $t))
    (initiallyP $f)
    (naf (stoppedIn 0 $f $t))
))

((-holdsAt $f $t) :- (
    (time $t)
    (bool (< 0 t))
    (initiallyN $f)
    (naf (startedIn 0 $f $t))
))

((holdsAt $f $t2) :- (
    (time $t2) (time $t1)
    (bool (< $t1 $t2))
    (initiates $e $f $t1)
    (happens $e $t1)
    (naf (stoppedIn $t1 $f $t2))
))

((-holdsAt $f $t2) :- (
    (time $t1) (time $t2)
    (bool (< $t1 $t2))
    (terminates $e $f $t1)
    (happens $e $t1)
    (naf (startedIn $t1 $f $t2))
))