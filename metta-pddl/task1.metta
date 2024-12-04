
;; predicates: clear/1, on-table/1, arm-empty, holding/1, on/2

(:object a) (:object b)
(:object c) ;;
(:init (
    (on-table a)
    (on-table b)
    (clear a)
    (clear b)
    (arm-empty)
    (on-table c) (clear c) ;;
))
(:goal (And (
    (on a b)
    (on b c) ;;
)))

