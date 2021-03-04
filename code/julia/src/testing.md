
# Timing Comparison

- parallelPlanner w/ async methods
117.647026 seconds (7.47 G allocations: 240.528 GiB, 70.72% gc time)
- parallelPlanner w/o async methods
115.895220 seconds (7.39 G allocations: 238.457 GiB, 68.86% gc time)

Async doesn't seem to offer much other than more confusing code 
