#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <pcre.h>
#include <stdbool.h>

#define O_VECTOR_LENGTH 3

bool matchRegex(const char *pattern, const char *output);
bool inRange(double lower, char *i, double upper);

int main(int argc, char **argv)
{
	printf("%d\n", matchRegex("^[^ ]* [^ ]*$", "Hello, world!"));
	printf("%d\n", inRange(1, "10123.asd", 5));
}

bool inRange(double lower, char *i, double upper)
{
	if (!matchRegex("[0-9]*", i))
	{
		return false;
	}

	int j = atoi(i);
	return lower <= j && j <= upper;
}

bool matchRegex(const char *pattern, const char *output)
{
	// Store errors
	const char *error;
	int errorOffset;

	pcre *re = pcre_compile(pattern, 0, &error, &errorOffset, NULL);
	if (re == NULL)
	{
		fprintf(stderr, "Failed to compile PCRE regular expression at location %d: %s\n", errorOffset, error);
		return 1;
	}

	int oVector[O_VECTOR_LENGTH];
	int matches = pcre_exec(re, NULL, output, strlen(output), 0, 0, oVector, O_VECTOR_LENGTH);

	if (matches < 0)
	{
		switch (matches)
		{
		case PCRE_ERROR_NOMATCH:
			break;
		default:
			printf("PCRE returned code: %d\n", matches);
			break;
		}
		pcre_free(re);
		return false;
	}
	else if (matches == 0)
	{
		printf("Can only recognise %d matches!", O_VECTOR_LENGTH / 3 - 1);
		pcre_free(re);
		return false;
	}
	else
	{
		pcre_free(re);
		return true;
	}
}