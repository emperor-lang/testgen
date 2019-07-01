#include <stdio.h>

#define ITER_1 10
#define ITER_2 5

int main(int, char**);

int main(int argc, char** argv)
{
	if (argc != 0)
	{
		printf("%s\n", argv[0]);
	}

	printf("Hello, world!\n");
	int t = 0;
	for (int i = 0; i < ITER_1; i++, t++)
	{
		printf("i = %d\n", i);
	}
	for (int j = 0; j < ITER_2; j++, t++)
	{
		printf("j = %d\n", j);
	}
	printf("t = %d\n", t);
}
