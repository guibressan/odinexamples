package odinexamples

import "core:fmt"
import "core:thread"
import "core:sync"
import "core:time"
import "core:log"

add :: proc(a, b: $T) -> T {
	return a + b
}

T_Data :: struct {
	mu: sync.Mutex,
	wg: sync.Wait_Group,
	count: int,
	target: int,
}

worker :: proc(t: rawptr) {
	data := cast(^T_Data)t
	defer sync.wait_group_done(&data.wg)
	for {
		sync.mutex_lock(&data.mu)
		defer sync.mutex_unlock(&data.mu)
		{ // we can put the defer inside the block, so it will be executed at end
			// of scope
			if data.count >= data.target {
				break
			}
			data.count += 1
		}
	}
}

add_in_thread :: proc($n_threads: int, target: int) -> int {
	tdata := T_Data{target=target}
	thandles := [n_threads]^thread.Thread{}
	sync.wait_group_add(&tdata.wg, n_threads)
	for i in 0..<n_threads {
		handle := thread.create_and_start_with_data(&tdata, worker)
		if handle == nil {
			panic("failed to create thread")
		}
		thandles[i] = handle
	}
	// wait for the termination of all the tasks
	sync.wait_group_wait(&tdata.wg)
	// wait for threads to terminate and destroy
	for i in 0..<n_threads {
		thread.destroy(thandles[i])
	}
	sync.mutex_lock(&tdata.mu)
	defer sync.mutex_unlock(&tdata.mu)
	return tdata.count
}

