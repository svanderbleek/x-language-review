proc forward[T](x: var T): var T =
  result = x # ok, derived from the first parameter.

proc p(param: var int): var int =
  var x: int
  # we know 'forward' provides a view into the location derived from
  # its first argument 'x'.
  result = forward(x) # Error: location is derived from `x`
                      # which is not p's first parameter and lives
                      # on the stack.
