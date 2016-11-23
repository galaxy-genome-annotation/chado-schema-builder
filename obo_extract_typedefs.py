
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
A parser for the OBO v1.2 format

Inspired from https://techoverflow.net/blog/2013/11/18/a-geneontology-obo-v1.2-parser-in-python/
"""

from __future__ import with_statement, print_function
from collections import OrderedDict

__author__    = "Uli Koehler, Anthony Bretaudeau"
__copyright__ = "Copyright 2013 Uli Koehler, 2016 Anthony Bretaudeau"
__license__   = "Apache v2.0"

def processTerm(term):
    """
    In an object representing a term, replace single-element lists with
    their only member.
    Returns the modified object as a dictionary.
    """
    ret = term #Input is a OrderedDict, might express unexpected behaviour
    for key, value in ret.iteritems():
        if len(value) == 1:
            ret[key] = value[0]
    return ret

def parseHeader(filename):
    """
    Parses a file in OBO v1.2 format.
    Yields each term
    Keyword arguments:
        filename: The filename to read
    """
    header = ""
    with open(filename, "r") as infile:
        currentTerm = None
        for line in infile:
            line = line.strip()
            if not line: continue #Skip empty
            if line == "[Term]" or line == "[Typedef]":
                return header
            else: #Not [Term]
                header += line + "\n"
    return header

def parseOBOTerms(filename):
    """
    Parses a file in OBO v1.2 format.
    Yields each term
    Keyword arguments:
        filename: The filename to read
    """
    with open(filename, "r") as infile:
        currentTerm = None
        for line in infile:
            line = line.strip()
            if not line: continue #Skip empty
            if line == "[Term]":
                if currentTerm: yield processTerm(currentTerm)
                currentTerm = OrderedDict()
            elif line == "[Typedef]":
                #Skip [Typedef sections]
                currentTerm = None
            else: #Not [Term]
                #Only process if we're inside a [Term] environment
                if currentTerm is None: continue
                key, sep, val = line.partition(":")
                if key not in currentTerm:
                    currentTerm[key] = []
                currentTerm[key].append(val.strip())
        #Add last term
        if currentTerm is not None:
            yield processTerm(currentTerm)

def parseOBOTypedefs(filename):
    """
    Parses a file in OBO v1.2 format.
    Yields each typedef
    Keyword arguments:
        filename: The filename to read
    """
    with open(filename, "r") as infile:
        currentTypedef = None
        for line in infile:
            line = line.strip()
            if not line: continue #Skip empty
            if line == "[Term]":
                #Skip [Term sections]
                currentTypedef = None
            elif line == "[Typedef]":
                if currentTypedef: yield processTerm(currentTypedef)
                currentTypedef = OrderedDict()
            else: #Not [Term]
                #Only process if we're inside a [Term] environment
                if currentTypedef is None: continue
                key, sep, val = line.partition(":")
                if key != 'is_a': # This is not really used and causes problem with SO
                    if key not in currentTypedef:
                        currentTypedef[key] = []
                    currentTypedef[key].append(val.strip())
        #Add last typedef
        if currentTypedef is not None:
            yield processTerm(currentTypedef)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('infile', help='The input file in OBO v1.2 format.')
    parser.add_argument('outfile', help='The output file in OBO v1.2 format with only Typedef not used in the OBO file.')
    args = parser.parse_args()

    #Iterate over terms
    termCounter = 0
    seenRelationships = []
    for term in parseOBOTerms(args.infile):
        if 'relationship' in term:
            if isinstance(term['relationship'], basestring):
                seenRelationships.append(term['relationship'].split()[0])
            else:
                for r in term['relationship']:
                    seenRelationships.append(r.split()[0])
        termCounter += 1
    print("Found %d terms" % termCounter)

    typedefCounter = 0
    unusedCounter = 0
    with open(args.outfile, "w") as outfile:
        header = parseHeader(args.infile)
        print(header, file=outfile)

        for typedef in parseOBOTypedefs(args.infile):
            if typedef['id'] not in seenRelationships:
                print("%s typedef was never seen" % typedef['name'])
                print("[Typedef]", file=outfile)
                for k in typedef:
                    print("%s: %s" % (k, typedef[k]), file=outfile)
                print("", file=outfile)
                unusedCounter += 1
            typedefCounter += 1
    print("Found %d typedefs, %s unused" % (typedefCounter, unusedCounter))
