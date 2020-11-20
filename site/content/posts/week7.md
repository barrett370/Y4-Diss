# Log : Week 7

This week I have been continuing to work on the programmatic implementation of my project. I have implemented population generation and the GA up to the selection phase. Performance of curve generation seems good, plotting is the slowest part by far and that would not occur in a deployed application of the system.
I have been going back and revising earlier code as I come to learn nice syntax tricks in Julia such as the use of the piping operator `|>` and functional operators such as `map`, `reduce`, and `filter` which allow me to avoid ugly nested loops

In fact the composition of my GA is taking the shape of:

```julia

(init_population 
    |> selection |> crossover |> mutation |> P -> filter(isValid,P)
    |> P -> map(p -> p.fitness = p |> Fitness, P)
    |> generate_new_pop |> next_generation)

```
Which I feel to be extremely clean and idiomatic.


I have also been responding to feedback on my presentation & re-recoding it ready for submission on Friday.

