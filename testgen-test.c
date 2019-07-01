#include <limits.h>
#include <pcre.h>
// #include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#define BUFFER_SIZE 1024
#define O_VECTOR_LENGTH 3
#define TOTAL_TESTS 2
#define STRING_TESTS 2
#define NUMERIC_TESTS 0

typedef struct stringList
{
	size_t length;
	char *val;
	struct stringList *next;
} stringList_t;

typedef struct testResult
{
	bool testFunctionedCorrectly;
	char *output;
	int returnCode;
} testResult_t;

int main(int argc, char **argv);
testResult_t *runTest(int testNumber, int *successes, int *failures, int expectedReturnValue);

bool inRange(double lower, char *i, double upper);
bool matchRegex(const char *pattern, const char *output);

int main(int argc, char **argv)
{
	int successes = 0;
	int failures = 0;
	int currentTest = 0;
	
	char *stringInput[] = { "./emoji-test", "./emoji-test" };
\char *regexes
	
	for (int i = 0; i <= STRING_TESTS; i++, currentTest++)
	{
		testResult_t *result = runTest(stringTestInputs[currentTest]);
		if (result == NULL || !result->testFunctionedCorrectly)
		{
			fprintf(stderr, "Test %d did not function correctly, aborting tests...\n", i);
			return -1;
		}
		else if (result->returnCode == expectedReturnCodes[i] && (!matchesRegex[i] || matchRegex(regexes[i], result->output)))
		{
			successes++;
		}
		else if (result->returnCode != expectedReturnCodes[i])
		{
			fprintf(stderr, "Test %d did not give correct return code", currentTest);
			failures++;
		}
		else
		{
			fprintf(stderr, "Test %d did not give correct return code", currentTest);
		}
		free(result);
	}
	
	for (int i = 0; i <= NUMERIC_TESTS + STRING_TESTS; i++, currentTest++)
	{
		testResult_t *result = runTest(stringTestInputs[currentTest]);
		free(result);
	}

	printf("--------------------------------------------------------------------------------\n");
	printf("%s\n", "Summary:");
	printf("%s%d\n", "\tFailed tests: ", failures);
	printf("%s%d\n", "\tPassed tests: ", successes);
	return 0;
}

