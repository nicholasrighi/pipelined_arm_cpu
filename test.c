#include "libmc/libmc.h"

int fib_iter(int n)
{
	int x = 0;
	int y = 1;
	int z = 0;
	int current_fib = 0;
	for (int i = 0; i < n; i++) {
		current_fib = x;
		z = x + y;
		x = y;
		y = z;
	}
	return current_fib;
}

int fact(int n)
{
	if (n <= 1)
		return 1;
	return n * fact(n - 1);
}

int main()
{
	/*
	int sum = 0;
	for (int i = 0; i < 10; i++) {
		if (i % 2 ==0)
			sum += fact(i);
		else 
			sum += fib_iter(i);
	}
	for (int i = -9; i < 1; i++) {
		if (i % 2 == 0)
			sum += fact(~i + 1);
		else
			sum += fib_iter(~i +1);
	}
	*/
	return 4;
}