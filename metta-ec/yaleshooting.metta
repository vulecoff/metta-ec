(initiates Load Loaded $t)
((initiates Shoot Dead $t) :- (
    (holdsAt Loaded $t)
))

((terminates Shoot Alive $t) :- (
    (holdsAt Loaded $t)
))

(initiallyP Alive)
(happens Load 1)
(happens Sneeze 3)
(happens Shoot 4)

(time 0) (time 1) (time 2) (time 3) (time 4)
(time 5)

!(import! &self bec)