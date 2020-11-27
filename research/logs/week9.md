---
title: Log: Week 9
---

I have started keeping a copy of my WIP report [here](https://sambarrett.online/Y4-Diss/report.pdf)

This week, I have been initially working on the background section of my report. I went on to work on my implmentation. I have decided to start the transition to cooperative route planning. To do this I have begun collating and reading papers on the subject. There appears to be promising research in the area of cooperative route planning so hopefully I will be able to implement a cooperative wrapper around my current code with *relative* ease.

From what I have read so far, one approach is to bake the cooperative nature into the fitness function. In so doing, one can completely parallelise the generation and evolution of the sub-populations (representing routes for different agents). This is an attractive concept in a real-time system that could potentially become slower the more the system is developed. With cores being a much cheaper alternative to clock speed or reductions in solution efficiency.
