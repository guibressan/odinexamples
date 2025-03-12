#!/usr/bin/env bash
####################
set -e
####################

eprintln() {
	! [ -z "${1}" ] || eprintln 'eprintln: undefined message'
	printf "${1}\n" 1>&2
	exit 1
}

add() {
	! [ -z "${1}" ] && ! [ -z "${2}" ] || eprintln 'expected: <num1> <num2>' 
	printf "$((${1} + ${2}))"
}

####################

add ${1} ${2}
