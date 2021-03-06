@testset "3 stages serial" begin
    include("data.jl")

    numScen = 2

    x = Matrix{Vector{JuMP.Variable}}(2,2)
    v = Matrix{Vector{JuMP.Variable}}(2,2)
    y = Matrix{Matrix{JuMP.Variable}}(2,2)
    models = Vector{JuMP.Model}(3)

    model = StructuredModel(num_scenarios=numScen)

    x[1,1] = @variable(model, [1:n], lowerbound=0)
    v[1,1] = @variable(model, [1:n], lowerbound=0)
    @constraints model begin
        x[1,1] .== v[1,1]
    end
    @objective(model, Min, dot(ic, v[1]))

    models[1] = model

    for s in 1:numScen
        model = StructuredModel(parent=models[1], prob=p2[s], same_children_as=(s == 1 ? nothing : models[2]), id=s)
        y[1,s] = @variable(model, [1:n, 1:m], lowerbound=0)
        x[2,s] = @variable(model, [1:n], lowerbound=0)
        v[2,s] = @variable(model, [1:n], lowerbound=0)
        @constraints model begin
            x[2,s] .== x[1,1] + v[2,s]
            demand[j=1:m], sum(y[1,s][:,j]) == D2[j,s]
            ylim[i=1:n], sum(y[1,s][i,:]) <= x[1,1][i]
        end
        @objective(model, Min, dot(ic, v[2,s]) + dot(C, y[1,s] * T))
        if s == 1
            models[2] = model
        end
    end
    for s in 1:numScen
        model = StructuredModel(parent=models[2], prob=p2[s], same_children_as=(s == 1 ? nothing : models[3]), id=s)
        y[2,s] = @variable(model, [1:n, 1:m], lowerbound=0)
        @constraints model begin
            demand[j=1:m], sum(y[2,s][:,j]) == D2[j,s]
            ylim[i=1:n], sum(y[2,s][i,:]) <= x[2,1][i]
        end
        @objective(model, Min, dot(C, y[2,s] * T))
        if s == 1
            models[3] = model
        end
    end

    fulltest(models[1], 3, 406712.49, [2986,0,7329,854], 402593.71614, 17319.095064)
end
