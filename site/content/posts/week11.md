# Log: Week 


This week I have begun to look at the cooperative planning element of my project. The first task I undertook was to implement the functionality to detect intersects between two bezier curves. This proved to be a non-trivial task with many solutions used in computer graphics proving to be too unreliable for a system such as mine. I ended up implementing a process of recursive subdivision using De Casteljau's algorithm for splitting Bezier curves. There does not exist, as far as I can see, an existing library for this so I was forced to implement it myself from scratch.

I have successfully implemented a system that can detect intersections to a decent degree of reliability. I was forced to implement a recursion depth break at around 8 otherwise the process would happily reach the max depth of over 27,000. A value of 8 proves to be deep enough to perform well and be relatively efficient. 8 may not sound like it takes much time but as in each recursion 4 new recursive processes are spawned it quickly gets out of hand!

The next stage is to incorporate this into my fitness function. Initially, I will simply have it s.t. any intersection between parallel routes will be classed as an infeasible route and a heavy penalty to the fitness. A priority based system may be implemented over the top of this.
I will also intend to re-implement this such that time is incorporated into planning i.e. two routes that intersect do not necessarily do so at the same point in time.
