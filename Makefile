#!/usr/bin/make

# MAKEFLAGS := $(MAKEFLAGS) s
CC := gcc-8
CFLAGS := -fPIC $(shell python3-config --cflags)
CLIBS := $(shell python3-config --libs)
CYTHON := cython3
CYTHONFLAGS := --embed -X language_level=3
EXECUTABLE_INSTALL_LOCATION := /usr/bin/testgen

.DEFAULT_GOAL := all

all: testgen;
.PHONY: all

testgen: testgen.py.c
	$(CC) $(CFLAGS) $^ -o $@ $(CLIBS)

testgen.py.c: testgen.pyx; 
	$(CYTHON) $(CYTHONFLAGS) $< -o $@

%.h:;

%.json:;

install: testgen
	sudo install testgen $(EXECUTABLE_INSTALL_LOCATION)

clean:
	-@$(RM) argparser			2>/dev/null || true
	-@$(RM) arggen 				2>/dev/null || true
	-@$(RM) arggen.py.c			2>/dev/null || true
	-@$(RM) test				2>/dev/null || true
	-@$(RM) *.hi				2>/dev/null || true
	-@$(RM) *.o					2>/dev/null || true
	-@$(RM) args.hs				2>/dev/null || true
	-@$(RM) args				2>/dev/null || true
	-@$(RM) test_c				2>/dev/null || true
	-@$(RM) t					2>/dev/null || true
	-@$(RM) t.c					2>/dev/null || true
	-@$(RM) tester_arg_parser.h	2>/dev/null || true