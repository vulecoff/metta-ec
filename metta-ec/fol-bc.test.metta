
!(import! &self fol-bc)
; !(bind! &baseall (new-space))
!(import! &baseall fol-bc-kb)
(= (query $goal)
    (backward-chain $goal &baseall &baseall)
)


; !(query (last $x (Cons 1 (Cons 2 (Cons 3 Nil)))))

; !(query (length (Cons 1 (Cons 2 (Cons 3 Nil))) $out))

; !(query (sum 3 $x))

!(query (append (Cons 1 (Cons 2 Nil)) (Cons 3 (Cons 4 Nil)) $x))
!(query  (append (Cons 1 (Cons 2 Nil)) $Out (Cons 1 (Cons 2 (Cons 3 (Cons 4 Nil))))))
!(query (append $What $Out (Cons 1 (Cons 2 (Cons 3 (Cons 4 Nil))))))