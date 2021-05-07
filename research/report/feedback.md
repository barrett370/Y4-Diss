# Draft report feedback 

As an overall note, make sure you 

- don't include too much extraneous information (in particular in diagrams, but also e.g. consider how much of the history of genetic algorithms is important to your project report).
- [x] include all the important information and be specific about it. Define or explain new technical terms or abbreviations when they first appear (such as "GA", "genotype", "phenotype"). 
- whenever you use a new variable or parameter in an equation, define or
explain what it represents and what kind of values it can take (unless
the latter is fairly self-evident, e.g. for a population size or a
probability).





---

p. 28: Is this figure clear enough? Should I move it to appendix?

The detail in Figure 4.6 is too small and some of the individual
diagrams overlap. Can you reduce the recursion depth you're
representing, say to 3 or at most 4, and increase the size of the
individual diagrams? I assume the tiny labels (both the names for the
curves and the numbers associated with the tickson the axes) are not
actually relevant here; if that's correct, then leave them out. 

Again, a more detailed caption or explanation in the text would be
useful here. You could for example link different steps in the figure to
the steps of your procedure described in the text (e.g. something along
the lines of "the diagram labelled (X) illustrates a branch where the
bounding boxes don't overlap so we don't need to proceed further there").

I would probably keep the figure in the main body: if you make it more
legible, it will be a good illustration of your procedure.

----

p. 31: do I need to make it more obvious that these algorithms are my
own work? Are they clear enough?

You could always rephrase this sentence as "I developed Algorithm 2 to
solve this problem" if you want to be very clear. It's also common for
academic papers to have an "our contributions" subsection in the
introduction, which summarises all the new ideas that will be presented
in the paper; this may be useful for your report too.

As with figures, it's good to give a prose description of (the
high-level structure of) an algorithm because even pseudo-code can be
tricky to understand without already having an intuition for what it's
meant to do.


