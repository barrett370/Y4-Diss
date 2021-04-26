# Draft report feedback 

As an overall note, make sure you 

- don't include too much extraneous information (in particular in diagrams, but also e.g. consider how much of the history of genetic algorithms is important to your project report).
- [x] include all the important information and be specific about it. Define or explain new technical terms or abbreviations when they first appear (such as "GA", "genotype", "phenotype"). 
- whenever you use a new variable or parameter in an equation, define or
explain what it represents and what kind of values it can take (unless
the latter is fairly self-evident, e.g. for a population size or a
probability).




p. 16: Should I change this superscript notation? subscript is being
used to denote which control points are being considered.

I don't understand your current definition of Bezier curves well enough
to be able to advise (see the note above about variables/parameters), so
you'll first need to clarify that. What is t in (2.6) and (2.7)? What
are P_0 to P_n ? What exactly does B specify? (vectors in the plane?)

----

p. 25: is this clear/ necessary?

Does this refer to the paragraph or the figure? The paragraph is fine,
though you could be clearer on how the communication between the threads
works. Does every thread just use whatever information is in the array
at the given time and update their route whenever they want, or is there
a common clock to make all routes update at the same time?
I don't understand Figure 4.5, can you give more explanation in the
caption and/or the text? I assume the a_k are the agents from the text
above the diagram, though that's not entirely clear. What does V Threads
mean? What do the boxes labelled GA represent? What does the vertical
double-arrow mean? What about the blue and the red box?

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

----

p. 35: Is this a clear way of formatting? I would reference the ID when
talking about a plot. I would still include a still as a figure

I'm generally in favour of having the link text be more meaningful.
Ideally the entire URL should be written out somewhere, either here or
in a footnote or reference (some pdf readers can be a bit fiddly about
clicking on embedded links, so it's good to have the alternative).

What is your goal with this overview of the dynamic plots; how will it
help the reader? (I'm not saying it's bad, I'm just not quite sure about
its purpose without any context.) An alternative could be to
include/reference the links to the online version in either the caption
of the corresponding "still" figure, or in the text where you discuss
that figure.


