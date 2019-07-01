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
testResult_t *runTest(const char *input);

bool inRange(double lower, char *i, double upper);
bool matchRegex(const char *pattern, const char *output);

int main(int argc, char **argv)
{
	int successes = 0;
	int failures = 0;

	int expectedReturnValues[] = {0,0};
	char *resultPatterns[] = { "asdf", "fdsa" };

	for (int i = 1; i <= TOTAL_TESTS; i++)
	{
		printf("%s %d/%d%s", "Running test", i, TOTAL_TESTS, "... ");
		testResult_t *result = runTest("ls");
		if (result->testFunctionedCorrectly && result->returnCode == expectedReturnValues[i] && matchRegex(resultPatterns[i], result->output))
		{
			successes++;
			printf("%s\n", "success ✔️");
		}
		else
		{
			failures++;
			printf("%s\n", "failed ❌");
		}
	}

	return 0;
}

testResult_t *runTest(const char *input)
{
	testResult_t *testResult = (testResult_t *)calloc(1, sizeof(testResult_t));

	FILE *fp = popen(input, "r");

	if (fp == NULL)
	{
		fprintf(stderr, "%s\n", "Could not open process");
		testResult->testFunctionedCorrectly = false;
		return testResult;
	}

	char lineBuffer[BUFFER_SIZE];
	stringList_t *buffer = NULL;
	stringList_t *bufferEnd = NULL;

	int bufferLength = 0;

	while (fgets(lineBuffer, BUFFER_SIZE, fp) != NULL)
	{
		size_t lineLength = strlen(lineBuffer);
		bufferLength += lineLength;

		stringList_t *bufferLine = (stringList_t *)malloc(sizeof(stringList_t));
		if (bufferLine == NULL)
		{
			fprintf(stderr, "%s\n", "Could not allocate line-buffer\n");
			testResult->testFunctionedCorrectly = false;
			return testResult;
		}

		bufferLine->length = lineLength;
		bufferLine->val = (char *)malloc(lineLength * sizeof(char));
		bufferLine->next = NULL;
		strcpy(bufferLine->val, lineBuffer - 1);

		if (bufferEnd != NULL)
		{
			bufferEnd->next = bufferLine;
		}
		else
		{
			buffer = bufferLine;
		}

		bufferEnd = bufferLine;
	}

	char *allOutput = malloc(sizeof(char) * (bufferLength + 1));
	size_t loc = 0;
	stringList_t *bufptr = buffer;
	while (bufptr != NULL)
	{
		if (bufptr->val != NULL)
		{
			strcpy(allOutput + loc, bufptr->val);
			loc += bufptr->length;
		}
		bufptr = bufptr->next;
	}
	allOutput[bufferLength] = '\0';
	allOutput[bufferLength - 1] = '\0';

	int result = WEXITSTATUS(pclose(fp));

	while (buffer != NULL)
	{
		stringList_t *next = buffer->next;
		if (buffer->val != NULL)
		{
			free(buffer->val);
		}
		free(buffer);
		buffer = next;
	}

	testResult->output = allOutput;
	testResult->returnCode = result;
	testResult->testFunctionedCorrectly = true;

	return testResult;
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
