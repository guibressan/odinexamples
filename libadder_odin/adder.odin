package adder

import "core:c"

@(export)
add :: proc "c" (a, b: c.int) -> c.int {
	return a + b
}
