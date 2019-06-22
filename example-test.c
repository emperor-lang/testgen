#include <signal.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define TOTAL_TESTS 2
#define BUFFER_SIZE 1024

int main(int, char **);

typedef struct stringList
{
	size_t length;
	char *val;
	struct stringList *next;
} stringList_t;

int main(int argc, char **argv)
{
	int successes = 0;
	int failures = 0;

	for (int i = 1; i <= TOTAL_TESTS; i++)
	{
		printf("%s %d/%d%s", "Running test", i, TOTAL_TESTS, "... ");

		const char *command = "/bin/ls";
		FILE *fp = popen(command, "r");

		if (fp == NULL)
		{
			fprintf(stderr, "%s\n", "Could not open process");
			return -1;
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
				return -1;
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

		if (result == 0)
		{
			successes++;
			printf("%s\n", "success ✔️");
		}
		else
		{
			failures++;
			printf("%s\n", "failed ❌");
		}

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
		free(allOutput);
	}


	return 0;
}