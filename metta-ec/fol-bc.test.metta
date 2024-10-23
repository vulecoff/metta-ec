
!(import! &self fol-bc)
!(bind! &baseall (new-space))
!(import! &baseall kb)
(= (query $goal)
    (backward-chain $goal &baseall &baseall)
)

; !(query (last $x (Cons 1 Nil)))
; !(query (last $x (Cons 1 (Cons 2 (Cons 3 Nil)))))

; !(query (is $x (+ 1 2)))
!(query (length Nil $out))
!(query (length (Cons 1 (Cons 2 (Cons 3 Nil))) $out))

!(query (sum 3 $x))