#!/usr/bin/env bash
####################
set -e
####################

_build_odin_shared_lib() {
	odin build \
	./libadder_odin \
	-build-mode:shared \
	-out:out/libadder-odin.dylib
	#
	cc -c -o out/main.o main.c
	#
	cc -o out/main -Lout -ladder-odin out/main.o
}

_build_odin_static_lib() {
	# Not supported yet (on non-windows targets)
	return 0
	odin build \
	./libadder_odin \
	-build-mode:static \
	-out:out/libadder-odin.a
}

_build_libadder() {
	./libadder/build.sh
}

_build_test() {
	_build_libadder
	odin build . -out:out/test -debug -build-mode:test
}

build() {
	_build_odin_shared_lib
	_build_odin_static_lib
	echo "Calling odin library from C"
	./out/main
	sleep 1
	_build_test
	printf "\nRunning odin example tests\n"
	sleep 1
	./out/test
}

####################

build
