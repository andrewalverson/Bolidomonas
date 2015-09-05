#!/usr/bin/python

import sys
import re
if len(sys.argv) < 2:
  print("Needs input fasta file")
  sys.exit()

file=open(sys.argv[1], "r")
seq=""
ctg=""
for i in file:
  if ">" in i.strip():
    print ctg 
    print re.sub('[^ATGCN]', '', seq.upper())
    seq=""
    ctg=i.strip()
  else:
	seq = seq + i.strip()

print ctg 
print re.sub('[^ATGCN]', '', seq.upper())

