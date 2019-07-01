#!/usr/bin/python3

from abc import ABC, abstractmethod
import json
import jsonschema
import sys

schemaFile:str = '../argspec/arguments.schema.json'

def printe(x:object) -> None:
	print(x, file=sys.stderr)

def standardise(spec:dict, schema:dict) -> dict:
	# Precondition: the spec has been validated against the schema
	if 'program' not in spec:
		spec['program'] = schema['program']['default']
	if 'examples' not in spec:
		spec['args'] = []

	return spec

class Tests(object):
	def __cinit__(self:object):
		self.numericTests = []
		self.stringTests = []
		self.tests = [self.stringTests, self.numericTests]

	def __str__(self:object) -> str:
		return ''

class Test(ABC):
	def __cinit__(self, inputString):
		self.input:str = inputString
	
	def __str__() -> str:
		return ''

def genTests(spec:dict) -> int:
	# Ensure an example spec has been given
	if 'examples' not in spec:
		printe('Missing "examples" section; could not generate tests')
		return -1

	totalTests:int = len(spec['examples'])
	if totalTests == 0:
		printe('Empty examples section; could not generate tests')
		return -1
	
	testLines:[str] = []

	stringTests:[dict] = list(filter(lambda example:example['output']['type'] == 'string', spec['examples']))
	numericTests:[dict] = list(filter(lambda example:example['output']['type'] == 'number', spec['examples']))

	totalStringTests:int = len(stringTests)
	totalNumericTests:int = len(numericTests)

	stringTestInput:[str] = []
	expectedReturnCodes:[int] = []
	validPatterns:[str] = []
	# returnStrings:[str] = []

	for example in stringTests:
		desc:str = example['description'] if 'description' in example else None
		inp:str = example['input']
		out:dict = example['output']
		stringTestInput += [
			f'"{inp}"'
		]
		expectedReturnCodes.append(example['exitCode'] if 'exitCode' in example else 0)
		if desc is not None:
			printe(desc)
		# print('"%s" -> "%s"' %(inp, out['value']))
		# returnStrings.append(out['value'])
		if 'validPattern' in out:
			if out['validPattern'][0] != '^':
				out['validPattern'] = '^' + out['validPattern']
			if out['validPattern'][-1] != '$':
				out['validPattern'] += '$'
			# print('validPattern: %s' % out['validPattern'])
			validPatterns.append('"' + out['validPattern'] + '"')
		else:
			validPatterns.append('"' + out['value'] + '"')

		# if 'sideEffects' in out:
		# 	print('sideEffects: %s' % out['sideEffects'])

	stringTestInputString:str = '\tchar *stringInput[] = { ' + ', '.join(stringTestInput) + ' };'
	validPatternsString:str = '\tchar *regexes[] = { ' + ', '.join(validPatterns) + ' };'
	stringTestLines:[str] = [
		stringTestInputString,
		validPatternsString
	]
	numericTestLines:[str] = []
		# if 'validRange' in out:
		# 	print('validRange: %s' % out['validRange'])

	for example in numericTests:
		expectedReturnCodes.append(example['exitCode'] if 'exitCode' in example else 0)

	expectedReturnCodesString:str = '\tint expectedReturnCodes[] = {' + ', '.join(list(map(lambda i: str(i), expectedReturnCodes))) + '};'

	setupLines:[str] = [
		'#include <limits.h>',
		'#include <pcre.h>',
		'// #include <signal.h>',
		'#include <stdlib.h>',
		'#include <stdio.h>',
		'#include <string.h>',
		'#include <stdbool.h>',
		'',
		'#define BUFFER_SIZE 1024',
		'#define O_VECTOR_LENGTH 3',
		f'#define TOTAL_TESTS {totalTests}',
		f'#define STRING_TESTS {totalStringTests}',
		f'#define NUMERIC_TESTS {totalNumericTests}',
		'',
		'typedef struct stringList',
		'{',
		'	size_t length;',
		'	char *val;',
		'	struct stringList *next;',
		'} stringList_t;',
		'',
		'typedef struct testResult',
		'{',
		'	bool testFunctionedCorrectly;',
		'	char *output;',
		'	int returnCode;',
		'} testResult_t;',
		'',
		'int main(int argc, char **argv);',
		'testResult_t *runTest(int testNumber, int *successes, int *failures, int expectedReturnValue);',
		'',
		'bool inRange(double lower, char *i, double upper);',
		'bool matchRegex(const char *pattern, const char *output);',
	]

	summaryLines:[str] = [
		'\tprintf("--------------------------------------------------------------------------------\\n");',
		'\tprintf("%s\\n", "Summary:");',
		'\tprintf("%s%d\\n", "\\tFailed tests: ", failures);',
		'\tprintf("%s%d\\n", "\\tPassed tests: ", successes);'
	]

	mainMethod:[str] = [
		'int main(int argc, char **argv)',
		'{',
		'\tint successes = 0;',
		'\tint failures = 0;',
		'\tint currentTest = 0;',
		'\t',
	] + stringTestLines + [
		'\t',
		'\tfor (int i = 0; i <= STRING_TESTS; i++, currentTest++)',
		'\t{',
		'\t\ttestResult_t *result = runTest(stringTestInputs[currentTest]);',
		'\t\tif (result == NULL || !result->testFunctionedCorrectly)',
		'\t\t{',
		'\t\t\tfprintf(stderr, "Test %d did not function correctly, aborting tests...\\n", i);',
		'\t\t\treturn -1;',
		'\t\t}',
		'\t\telse if (result->returnCode == expectedReturnCodes[i] && (!matchesRegex[i] || matchRegex(regexes[i], result->output)))',
		'\t\t{',
		'\t\t\tsuccesses++;',
		'\t\t}',
		'\t\telse if (result->returnCode != expectedReturnCodes[i])',
		'\t\t{',
		'\t\t\tfprintf(stderr, "Test %d did not give correct return code", currentTest);',
		'\t\t\tfailures++;',
		'\t\t}',
		'\t\telse',
		'\t\t{',
		'\t\t\tfprintf(stderr, "Test %d did not give correct return code", currentTest);',
		'\t\t}',
		'\t\tfree(result);',
		'\t}',
		'\t',
		'\tfor (int i = 0; i <= NUMERIC_TESTS + STRING_TESTS; i++, currentTest++)',
		'\t{',
		'\t\ttestResult_t *result = runTest(stringTestInputs[currentTest]);',
		'\t\tfree(result);',
		'\t}',
		''
	] + summaryLines + [
		'\treturn 0;',
		'}'
	]

	isRangeLines:[str] = [
		'bool inRange(double lower, char *value, double upper)',
		'{',
		'	if (!matchRegex("[0-9]*", value))',
		'	{',
		'		return false;',
		'	}',
		'',
		'	int j = atoi(value);',
		'	return lower <= j && j <= upper;',
		'}'
	]

	regexMatchLines:[str] = [
		r'bool matchRegex(const char *pattern, const char *output)',
		r'{',
		r'	// Store errors',
		r'	const char *error;',
		r'	int errorOffset;',
		r'',
		r'	pcre *re = pcre_compile(pattern, 0, &error, &errorOffset, NULL);',
		r'	if (re == NULL)',
		r'	{',
		r'		fprintf(stderr, "Failed to compile PCRE regular expression at location %d: %s\n", errorOffset, error);',
		r'		return 1;',
		r'	}',
		r'',
		r'	int oVector[O_VECTOR_LENGTH];',
		r'	int matches = pcre_exec(re, NULL, output, strlen(output), 0, 0, oVector, O_VECTOR_LENGTH);',
		r'',
		r'	if (matches < 0)',
		r'	{',
		r'		switch (matches)',
		r'		{',
		r'			case PCRE_ERROR_NOMATCH:',
		r'				break;',
		r'			default:',
		r'				printf("PCRE returned code: %d\n", matches);',
		r'				break;',
		r'		}',
		r'		pcre_free(re);',
		r'		return false;',
		r'	}',
		r'	else if (matches == 0)',
		r'	{',
		r'		printf("Can only recognise %d matches!", O_VECTOR_LENGTH / 3 - 1);',
		r'		pcre_free(re);',
		r'		return false;',
		r'	}',
		r'	else',
		r'	{',
		r'		pcre_free(re);',
		r'		return true;',
		r'	}',
		r'}',
	]

	print('\n'.join(setupLines), end='\n\n')
	print('\n'.join(mainMethod), end='\n\n')
	# print('\n'.join(isRangeLines), end='\n\n')
	# print('\n'.join(regexMatchLines))

	return 0

def main(args:[str]) -> int:
	spec:dict
	try:
		spec = json.load(sys.stdin)
	except json.decoder.JSONDecodeError as jsonde:
		printe(str(jsonde) + f' while handling json from stdin')
		return -1

	schema:dict
	with open(schemaFile, 'r+') as i:
		try:
			schema = json.load(i)
		except json.decoder.JSONDecodeError as jsonde:
			printe(str(jsonde) + f' while handling schema in "{schemaFile}"')
			return -1

	try:
		jsonschema.validate(instance=spec, schema=schema)
	except jsonschema.exceptions.ValidationError as ve:
		printe(f'Input specification did not match the schema (using schema: "{schemaFile}"')
		printe(str(ve))
		return -1

	spec = standardise(spec, schema)

	return genTests(spec)

if __name__ == '__main__':
	sys.exit(main(sys.argv[1:]))