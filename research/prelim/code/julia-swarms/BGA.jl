
function BGA()
    num_bit = 128
    crossover_prob = 0.85
    mutation_prob = 1 / num_bit
    num_ind = 100
    max_iter =100 
    num_parents = Integer(ceil(num_ind * 0.3))

# Initialisation 

    pop = rand(Bool, num_ind, num_bit)


    fitness = cal_fitness(pop)[1]
    #println(fitness)
    #println(fitness[:,1])

    sorted_idx = sortperm(fitness[:,1], rev = true)
    #println(sorted_idx)
    pop = pop[sorted_idx,:]
    #println(pop)
    termination_flag = false
    t = 1

    while !termination_flag
        #println("Num parents: $num_parents")
        parents = pop[1:num_parents,:]
        #println("init parents : $parents")
        offspring = parents

        for j = 1:floor(num_parents / 2)
            if rand(1)[1] < crossover_prob
                p_1_index = rand([1,num_parents])
                p_2_index = rand([1,num_parents])
                #println("p1i : $p_1_index, p2i : $p_2_index")
                p_1 = parents[p_1_index,:]  
                p_2 = parents[p_2_index,:]

                crossover_bit = rand([1,num_bit])
                #println("crossover bit: $crossover_bit")
                #println("parent 1: $p_1")
                #println("parent 2: $p_2")
                tmp = p_1[1:crossover_bit,:]
                p_1[1:crossover_bit,:] = p_2[1:crossover_bit,:]
                p_2[1:crossover_bit,:] = tmp[:,:]
                parents[p_1_index,:] = p_1
                parents[p_2_index,:] = p_2

            end
        end
        #println("parents after crossover $parents")
        for j = 1:num_parents
            for k = 1:num_bit
                #println("j: $j, k: $k")
                if rand(1)[1] < mutation_prob
                    if parents[j,k] == true
                        parents[j,k] = false
                    else 
                        parents[j,k] = true 
                    end
                end 
            end
        end
        #println("after mutation parents: $parents")
        tmp_pop = [pop; offspring]
        #println("tmp population $tmp_pop")
        fitness = cal_fitness(tmp_pop)[1]
        
        #println("fitness of tmp pop: $fitness")
        sorted_idx = sortperm(fitness[:,1], rev = true)
        fitness = fitness[sorted_idx]
        
        #println("sorted fitness of tmp pop: $fitness")

        pop = tmp_pop[sorted_idx[1:num_ind],:]
        #println("Top pop: $pop")
        t += 1 
        if t > max_iter
            #println("Max iterations reached ")
            termination_flag = true
        end
    end
    best_solution = pop[1,:]
    #println("best solution $best_solution")
    foo = falses(1,num_bit)
    #println(foo)
    foo = best_solution
    #println(foo)
    fitness, total_profit, total_cons_vio = cal_fitness(pop)
    #println(fitness)
    #println(total_cons_vio)
    best_fitness = fitness[1]
    println("Best solution: $best_solution")
    println("Fitness: $best_fitness")
    best_cons_vio = total_cons_vio[1]
    best_profit = total_profit[1]
    println("Best number of constraint_violations : $best_cons_vio" )
    println("Best profit: $best_profit")
end

function cal_fitness(pop)
    profits = [0.25 0.25 0.25 0.25]
    profits  = rand(1,128)
    project_year_bugets = [
       0.5 0.3 0.2
       1  0.8 0.2 
       1.5 1.5 0.3
       0.1 0.4 0.1
   ]
   project_year_bugets = rand(128,3)
    max_budgets = [3.1 2.5 0.4]

    num_ind = length(pop[:,1])
    #println("size of pop: $num_ind")
    total_profit = zeros(num_ind, 1)
    total_budgets = zeros(num_ind, 3)
    for i = 1:num_ind
        solution = pop[i,:]'
        total_profit[i,1] = (solution * profits')[1]
        total_budgets[i,:] = solution * project_year_bugets
    end
    #println("totoal profit $total_profit")
    constraint_violations = repeat(max_budgets, num_ind, 1) - total_budgets
    # tmp = [constraint_violations[i,:] for i = 1:num_ind if constraint_violations[i] < 0]
    # if length(tmp) > 0
    #     total_cons_vio = sum(tmp)
    # else
    #     total_cons_vio = zeros(num_ind, 1)
    # end
    #println("Constraint vio: $constraint_violations ")
    num_vio = zeros(num_ind,1)
    for i=1:length(constraint_violations[:,1])
        num_vio[i] = count(x->x<0, constraint_violations[i,:])
    end
    #println(num_vio)
    total_cons_vio =num_vio 
    fitness = total_profit - total_cons_vio
    return (fitness, total_profit, total_cons_vio)
end