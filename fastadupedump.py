#!/usr/bin/python

import sys
import random
if len(sys.argv) < 2:
  print("Needs input fasta file, and number of pseudoreplicates")
  sys.exit()

file=open(sys.argv[1], "r")
dic={}
seq=""
ctg=""
for i in file:
  if ">" in i.strip():
    dic[seq]=ctg
    seq=""
    ctg=i.strip()
  else:
    seq = seq + i.strip()
dic[seq]=ctg

for i in dic.keys():
 print dic[i]
 print i

