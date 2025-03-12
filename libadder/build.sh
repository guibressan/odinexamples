#!/usr/bin/env bash
####################
set -e
####################
readonly RELDIR="$(dirname ${0})"
####################

_output_src() {
cat << EOF > adder.c
int add(int a, int b) {
	return a+b;
}
EOF
}

_build_mac() {
	mkdir -p mac
	# archive
	cc -c -o adder.o adder.c
	ar rcs mac/libadder.a adder.o
	#
	# shared
	# to use rpath
	#-install_name @rpath/libadder.dylib \
	cc -c -fPIC -o adder.o adder.c
	cc -shared \
	-install_name ${PWD}/mac/libadder.dylib \
	-o mac/libadder.dylib \
	adder.o
}

_clean() {
	rm -rf ${RELDIR}/{mac,*.o,*.c}
}

build() {
	local prev="${PWD}"
	cd ${RELDIR}
	#
	_clean
	_output_src
	_build_mac
	#
	cd ${prev}
}

####################

build
