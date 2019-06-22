#!/usr/bin/python3

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

test:str = '\n'.join(
	[
		''
	]
)

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

	for example in spec['examples']:
		desc:str = example['description'] if 'description' in example else None
		inp:str = example['input']
		out:dict = example['output']
		if desc is not None:
			print(desc)
		print('"%s" -> "%s"' %(inp, out['value']))
		if 'validRange' in out:
			print('validRange: %s' % out['validRange'])
		if 'validPattern' in out:
			print('validPattern: %s' % out['validPattern'])
		if 'sideEffects' in out:
			print('sideEffects: %s' % out['sideEffects'])

	setupLines:[str] = [
		'#include <signal.h>',
		'#include <stdlib.h>',
		'#include <stdio.h>',
		'#include <string.h>',
		'',
		'#define TOTAL_TESTS 2',
		'#define BUFFER_SIZE 1024',
		'',
		'int main(int, char **);',
		'',
		'typedef struct stringList',
		'{',
		'	size_t length;',
		'	char *val;',
		'	struct stringList *next;',
		'} stringList_t;'
	]

	summaryLines:[str] = [
		'\tprintf("--------------------------------------------------------------------------------\\n");',
		'\tprintf("%s\\n", "Summary:");',
		'\tprintf("%s%d\\n", "\\tFailed tests: ", failures);',
		'\tprintf("%s%d\\n", "\\tPassed tests: ", successes);'
	]

	mainMethod:[str] = [
		'int main(int argc, char **argv)',
		'{'
		'\tint successes = 0;',
		'\tint failures = 0;',
		'\t',
		'\tfor (int i = 1; i <= TOTAL_TESTS; i++)',
		'\t{',
		'\t}'
	] + summaryLines + [
		'\treturn 0;',
		'}'
	]

	print('\n'.join(setupLines), end='\n\n')
	print('\n'.join(mainMethod))

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