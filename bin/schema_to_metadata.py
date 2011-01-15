#!/usr/bin/env python

# 
# LSST Data Management System
# Copyright 2008, 2009, 2010 LSST Corporation.
# 
# This product includes software developed by the
# LSST Project (http://www.lsst.org/).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the LSST License Statement and 
# the GNU General Public License along with this program.  If not, 
# see <http://www.lsstcorp.org/LegalNotices/>.
#

# want to extract:
# per table:
#   name
#   engine
# per column:
#   type 
#   notnull
#   defaultValue
#   <descr>...</descr>
#   <unit>...</unit>
#   <ucd>...</ucd>


import commands
import optparse
import os
import re
import sys

###############################################################################
# Configuration information
###############################################################################

# Tagged values to be extracted from within <tag>...</tag>
columnTags = ["descr", "ucd", "unit"]

# Fields for tables in the metadata (values obtained with custom code).
tableFields = ["engine",  "description"]

columnFields = ["description", "type", "notNull", "defaultValue",
                "unit", "ucd", "displayOrder"]

numericFields = ["notNull", "displayOrder"]

###############################################################################
# Usage and command line processing
###############################################################################

usage = """%prog -i inputSchemaFile.sql -v VERSION

The script extract information from the input file and generates the output
file that can be used by the schema browser. The output will be placed in
/tmp/metadata_{VERSION}.sql

A "CREATE TABLE AAA_Version_{version}" statement is also prepended to the
file, as is a standard comment header.

The input schema file should be in subversion (svn info -R will be executed
on that file)

"""

parser = optparse.OptionParser(usage=usage)
parser.add_option("-i", help="Input schema file")
parser.add_option("-v", help="Version, e.g., DC3b, PT1_1")

options, arguments = parser.parse_args()

if not options.i or not options.v:
    sys.stderr.write(os.path.basename(sys.argv[0]) + usage[5:])
    sys.exit(1)

if not os.path.isfile(options.i):
    sys.stderr.write("File '%s' does not exist\n" % iF)
    sys.exit(1)

###############################################################################
# DDL for creating database and tables
###############################################################################

databaseDDL = """
DROP DATABASE IF EXISTS lsst_schema_browser_%s;
CREATE DATABASE lsst_schema_browser_%s;
USE lsst_schema_browser_%s;

""" % (options.v, options.v, options.v)

# Names of fields in these tables after "name" must match the names in the
# Fields variables above.

tableDDL = """
CREATE TABLE md_Table (
	tableId INTEGER NOT NULL UNIQUE PRIMARY KEY,
	name VARCHAR(255) NOT NULL UNIQUE,
	engine VARCHAR(255),
	description TEXT
);

CREATE TABLE md_Column (
	columnId INTEGER NOT NULL UNIQUE PRIMARY KEY,
	tableId INTEGER NOT NULL REFERENCES md_Table (tableId),
	name VARCHAR(255) NOT NULL,
	description TEXT,
	type VARCHAR(255),
	notNull INTEGER DEFAULT 0,
	defaultValue VARCHAR(255),
	unit VARCHAR(255),
	ucd VARCHAR(255),
        displayOrder INTEGER NOT NULL,
	INDEX md_Column_idx (tableId, name)
);

"""


###############################################################################
# Standard header to be prepended
###############################################################################

LSSTheader = """
-- LSST Database Metadata
-- $Revision$
-- $Date$
--
-- See <http://dev.lsstcorp.org/trac/wiki/Copyrights>
-- for copyright information.

"""


################################################################################
# 
################################################################################


# get the svn revision of the input file
cmd = "svn info -R " + options.i + "| grep Revision"
print cmd
r = commands.getoutput(cmd)
if len(r.split()) > 2:
    sys.stderr.write("Can't determine svn revision of the input file '%s', error was: %s" % (options.i, r))
    sys.exit(1)
revision = int(r.split()[1])
if not revision or revision < 1:
    sys.stderr.write("Can't determine svn revision of the input file '%s'" %s)
    sys.exit(1)

oFName = "/tmp/metadata_%s.sql" % options.v
oF = open(oFName, mode='wt')
oF.write(LSSTheader)
oF.write(databaseDDL)
oF.write("\nCREATE TABLE AAA_Revision_%i (r CHAR);\n\n" % revision)
oF.write(tableDDL)

###############################################################################
# Parse sql
###############################################################################

def isColumnDefinition(c):
    return c not in ["PRIMARY", "KEY", "INDEX", "UNIQUE"]


def retrieveIsNotNull(str):
    if re.search('NOT NULL', str):
        return '1'
    return '0'
                
def retrieveType(str):
    arr = str.split()
    t = arr[1]
    if t == "FLOAT(0)":
        return "FLOAT"
    return t


def retrieveDefaultValue(str):
    if re.search(' DEFAULT ', str) is None:
        return None
    arr = str.split()
    returnNext = 0
    for a in arr:
        if returnNext:
            return a.rstrip(',')
        if a == 'DEFAULT':
            returnNext = 1



in_table = None
in_col = None
table = {}

tableStart = re.compile(r'CREATE TABLE (\w+)*')
tableEnd = re.compile(r"\)")
engineLine = re.compile(r'\) TYPE=(\w+)*;')
columnLine = re.compile(r'[\s]+(\w+) ([\w\(\)]+)')
descrStart = re.compile(r'<descr>')
descrEnd = re.compile(r'</descr>')
unitStart = re.compile(r'<unit>')
unitEnd = re.compile(r'</unit>')

colNum = 1

tableNumber = 1000

iF = open(options.i, mode='r')
for line in iF:
    #print "processing ", line
    m = tableStart.search(line)
    if m is not None:
        tableName = m.group(1)
        if not re.match('AAA_Version_', tableName):
            table[tableNumber] = {}
            table[tableNumber]["name"] = tableName
            colNum = 1
            in_table = table[tableNumber]
            tableNumber += 1
            #print "Found table ", in_table
    elif tableEnd.match(line):
        m = engineLine.match(line)
        if m is not None:
            engineName = m.group(1)
            in_table["engine"] = engineName
        #print "end of the table"
        #print in_table
        in_table = None
    elif in_table is not None: # process columns for given table
        m = columnLine.match(line)
        if m is not None:
            firstWord = m.group(1)
            if isColumnDefinition(firstWord):
                in_col = {"name" : firstWord, 
                          "displayOrder" : str(colNum),
                          "type" : retrieveType(line),
                          "notNull" : retrieveIsNotNull(line),
                          }
                dv = retrieveDefaultValue(line)
                if dv is not None:
                    in_col["defaultValue"] = dv
                colNum += 1
                if "columns" not in in_table:
                    in_table["columns"] = []
                in_table["columns"].append(in_col)
            #print "found col: ", in_col
            in_col = None
iF.close()

###############################################################################
# Output DML
###############################################################################

def handleField(ptr, field, indent):
    if field not in ptr:
        return
    q = '"'
    if field in numericFields:
        q = ''
    oF.write(",\n")
    oF.write("".join(["\t" for i in xrange(indent)]))
    oF.write(field + " = " + q + ptr[field] + q)

tableId = 0
colId = 0
for k in sorted(table.keys(), key=lambda x: table[x]["name"]):
    t = table[k]
    tableId += 1
    oF.write("".join(["-- " for i in xrange(25)]) + "\n\n")
    oF.write("INSERT INTO md_Table\n")
    oF.write('SET tableId = %d, name = "%s"' % (tableId, t["name"]))
    for f in tableFields:
        handleField(t, f, 1)
    oF.write(";\n\n")

    if "columns" in t:
        for c in t["columns"]:
            colId += 1
            oF.write("\tINSERT INTO md_Column\n")
            oF.write('\tSET columnId = %d, tableId = %d, name = "%s"' %
                    (colId, tableId, c["name"]))
            for f in columnFields:
                handleField(c, f, 2)
            oF.write(";\n\n")

oF.close()