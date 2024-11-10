



;; Goal is the stopping condition

(= (forward-chain $kb $rb 0) (empty))
(= (forward-chain $kb $rb $d)

)

(= (match-body $body $kb $head)
    (if (== $body ())
        $head 
        (let* (
            (($cur $rest) (decons-atom $body))
            (match $kb $cur $cur)
        ))
    )
)