#!/usr/bin/env python
# -*- coding: utf-8 -*-
import re 
import numpy as np 
import matplotlib.pyplot as plt

def get_re(r,string):
    match = re.search(r, string)
    if match:
        return float("".join(list(filter(lambda x: x!= '' and x != ' ',string[match.start():match.end()].split(":")[1]))))



test_str = '''
 memory estimate:  2.69 MiB
  allocs estimate:  85662
  --------------
  minimum time:     1.880 ms (0.00% GC)
  median time:      32.420 ms (35.24% GC)
  mean time:        34.541 ms (27.61% GC)
  maximum time:     116.098 ms (32.90% GC)
  --------------
  samples:          145
  evals/sample:     1
'''



def extract_data(benches):
    data = []
    print(len(benches))
    min_time_re = r'minimum time:[ ]+[0-9]+[^1-9][0-9]+'
    med_time_re = r'median time:[ ]+[0-9]+[^1-9][0-9]+'
    mean_time_re = r'mean time:[ ]+[0-9]+[^1-9][0-9]+'
    max_time_re = r'maximum time:[ ]+[0-9]+[^1-9][0-9]+'
    passes = 0
    for n_gens in range(10):
        data.append([])
        for n in range(20):
            min_time =get_re(min_time_re, benches[n_gens+n]) 
            med_time  = get_re(med_time_re, benches[n_gens+n])
            mean_time  = get_re(mean_time_re, benches[n_gens+n])
            max_time  = get_re(max_time_re, benches[n_gens+n])
            data[n_gens].append(mean_time)
            print(f"""
For {n_gens+1} generations and a pop size of {n+1}:
        min_time : {min_time}
        med_time : {med_time}
        mean_time : {mean_time}
        max_time: {max_time}
                  """)
            passes += 1
    return data

input_data = [[test_str]]
benches = open("./bench.txt").read().split(",")
input_data = benches
data = extract_data(input_data)
print(data)

ngens = [i for i in range(1,len(data)+1)]
ns = [i for i in range(1,len(data[0])+1)]
print(ngens)
print(ns)
#print(len(data) == len(ngens))
#print(len(data[-1]) == len(ns))
#print(len(data))
#print(list(map(lambda x: len(x), data)))

fig = plt.figure()
ax = plt.axes(projection='3d')
for ng in ngens:
    ax.scatter(ng,ns, data[ng-1])

plt.show()

