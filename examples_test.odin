#+feature dynamic-literals
package odinexamples

import "core:testing"
import "core:log"
import "core:os/os2"
import "base:runtime"


// ^T means pointer to T
// T^ means value T points to (dereference)
//
// @(test) enables the test
//
// to run, execute odin test .
@(test)
test_add :: proc(t: ^testing.T) {
	testing.expect(t, add(1,2) == 3, msg="unexpected: 1 + 2 != 3")
}

@(test)
test_thread :: proc(t: ^testing.T) {
	{
		n_threads :: 8
		target := 100
		v := add_in_thread(n_threads, target)
		testing.expect(t, v == target)
	}
	{
		n_threads :: 1
		target := 100
		v := add_in_thread(n_threads, target)
		testing.expect(t, v == target)
	}
}

@(test)
test_context :: proc(t: ^testing.T) {
	// The context is a struct that is implicitly passed to all procedures
	oldctx := context
	testing.expect(t, oldctx.user_index == 0)
	// note the assignment without declaration, because context is already
	// in the scope
	context = runtime.Context{user_index=1}
	proc(t: ^testing.T) {
		// only globals are captured in "closures"
		// uncomment the following line and compilation will fail
		//oldctx == 1
		testing.expect(t, context.user_index == 1)
	}(t)
}

@(test)
test_memory_allocation :: proc(t: ^testing.T) {
	Example_Struct :: struct {
		count: int,
	}
	{ // allocation with the default allocator
		sptr : ^Example_Struct
		testing.expect(t, sptr == nil)
		// the context allocator is already used by default
		// we don't need to pass it, this is just an example
		sptr = new(Example_Struct, allocator=context.allocator)
		// comment this defer and you will get a warning when running the test
		defer free(sptr)
		sptr.count += 1
		testing.expect(t, sptr.count == 1)
	}
	{ // allocation with the temp_allocator, which by default is a arena 
		// allocator
		sptr : ^Example_Struct
		testing.expect(t, sptr == nil)
		for i in 0..<10 {
			// this is highly performant, because the free_all in arenas just resets
			// the counter
			defer free_all(allocator=context.temp_allocator)
			sptr = new(Example_Struct, allocator=context.temp_allocator)
			sptr.count += 1
			testing.expect(t, sptr.count == 1)
		}
	}
}

@(test)
test_dynamic_array :: proc(t: ^testing.T) {
	{
		// literal dynamic array
		// disabled by default, can be enabled with
		// #+feature dynamic-literals in the file top
		//
		// be careful, you must deallocate dynamic literals, since they are
		// syntatic sugar for the creation with make()
		array := [dynamic]int{1,2}
		defer delete(array)
		testing.expect(t, array[0] == 1 && array[1] == 2)
	}
	{
		// dynamic array created with make
		array := make([dynamic]int, 2, 2)
		array[0], array[1] = 1, 2
		defer delete(array)
		testing.expect(t, array[0] == 1 && array[1] == 2)
	}
	{
		// dynamic array created with make
		array := make([dynamic]int, 0, 2)
		append(&array, 1, 2)
		defer delete(array)
		testing.expect(t, array[0] == 1 && array[1] == 2)
	}
}


@(test)
test_map :: proc(t: ^testing.T) {
	{
		mapInt := map[int]int{1=2, 3=4}
		defer delete(mapInt)
		testing.expect(t, mapInt[1] == 2 && mapInt[3] == 4)
	}
	{
		mapInt : map[int]int
		mapInt = make(map[int]int, 2)
		mapInt[1], mapInt[3] = 2, 4
		defer delete(mapInt)
		testing.expect(t, mapInt[1] == 2 && mapInt[3] == 4)
	}
}

// core:c has the C types needed to interface with C libraries
import "core:c"

foreign import adder "libadder/mac/libadder.a"
foreign import addershared "libadder/mac/libadder.dylib"

@(test)
test_link_lib :: proc(t: ^testing.T) {
	{ // statically linked
		@(default_calling_convention="c")
		foreign adder {
			@(link_name="add")
			add_static :: proc(a, b: c.int) -> c.int ---
		}
		r := add_static(1,2)
		testing.expect(t, r == 3)
	}
	{ // dynamically linked
		@(default_calling_convention="c")
		foreign addershared {
			@(link_name="add")
			add_shared :: proc(a, b: c.int) -> c.int ---
		}
		r := add_shared(1,2)
		testing.expect(t, r == 3)
	}
}

@(test)
test_process_exec :: proc(t: ^testing.T) {
	{ // executing processes
		process_desc : os2.Process_Desc
		cmd := [?]string{"./scripts/adder.sh", "1", "2"}
		process_desc.command = cmd[:]
		state, stdout, stderr, err := os2.process_exec(
			desc=process_desc, allocator=context.temp_allocator
		)
		testing.expect(t, err == nil)
		defer free_all(allocator=context.temp_allocator)
		testing.expect(t, len(stdout) == 1)
		testing.expect(t, cast(string)stdout == "3")
		if state.exit_code != 0 {
			log.errorf("%s\n", cast(string)stderr)
		}
		testing.expect(t, state.exit_code == 0)
	}
}
