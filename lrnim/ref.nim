type
  T = ref object
    x: int

proc p(t : T) =
  echo t.x

var t : T
p(t)

