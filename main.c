#include <stdio.h>

// linked with odin shared library on build.sh
extern int add(int a, int b); 

int main() {
	switch (add(1, 2)) {
	case 3:
		printf("OK");
		break;
	default:
		printf("unexpected result");
		break;
	} 
}
