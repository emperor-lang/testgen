#!/usr/bin/make

# MAKEFLAGS := $(MAKEFLAGS) s
CC := gcc-8
CFLAGS := -fPIC $(shell python3-config --cflags)
CLIBS := $(shell python3-config --libs)
CYTHON := cython3
CYTHONFLAGS := --embed -X language_level=3
EXECUTABLE_INSTALL_LOCATION := /usr/bin/testgen

.DEFAULT_GOAL := testgen

all: testgen testgen-tester;
.PHONY: all

test: testgen-tester;
.PHONY: test

testgen-tester: testgen-tester.c
	$(CC) -Wall -Wextra -Werror -Wpedantic -pedantic-errors -g $^ -o $@

testgen-tester.c: ./testgen ./spec.json
	./testgen <./spec.json > testgen-tester.c

testgen: testgen.py.c
	$(CC) $(CFLAGS) $^ -o $@ $(CLIBS)

testgen.py.c: testgen.pyx; 
	$(CYTHON) $(CYTHONFLAGS) $< -o $@

%.h:;

%.json:;

install: testgen
	sudo install testgen $(EXECUTABLE_INSTALL_LOCATION)

clean:
	-@$(RM) testgen				2>/dev/null || true
	-@$(RM) *.py.c				2>/dev/null || true
	# -@$(RM) example-test		2>/dev/null || true
