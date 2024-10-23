(last $x (Cons $x Nil))
((last $x (Cons $_ $rest)) :- ( (last $x $rest) ) )


(length Nil 0)
((length (Cons $x $rest) $out) :- (
    (length $rest $out2) 
    (is $out (+ $out2 1))
)
)

(sum 0 0)
((sum $n $s) :- (
    (bool (> $n 0))
    (is $n1 (- $n 1))
    (sum $n1 $s1)
    (is $s (+ $n $s1))
))