if Pkg.installed("Ipopt") == nothing Pkg.add("Ipopt") end

using Ipopt

function xy(f)
    function ff(x, y)
        y .= f(x)
    end
    ff
end

function jac_g(f1, f2)
    function f(x, mode, rows, cols, values)
        if mode == :Structure
            r = f1()
            rows .= Array{Int32}(r[1])
            cols .= Array{Int32}(r[2])
        else
            values .= f2(x)
        end
    end
    f
end

function h(f1, f2)
    function f(x, mode, rows, cols, obj_factor, lambda, values)
        if mode == :Structure
            r = f1()
            rows .= Array{Int32}(r[1])
            cols .= Array{Int32}(r[2])
        else
            values .= f2(x, obj_factor, lambda)
        end
    end
    f
end

function IPOPT(
    x,         # Starting point
    x_L,       # Variable lower bounds
    x_U,       # Variable upper bounds
    g_L,       # Constraint lower bounds
    g_U,       # Constraint upper bounds
    eval_f,                     # Callback: objective function
    eval_g,                     # Callback: constraint evaluation
    eval_grad_f,                # Callback: objective function gradient
    jac_g1, jac_g2,             # Callback: Jacobian evaluation
    h1, h2                      # Callback: Hessian evaluation
    )

    prob = createProblem(length(x), x_L, x_U, length(g_L), g_L, g_U, length(jac_g1()[1]), length(h1()[1]),
        eval_f, xy(eval_g), xy(eval_grad_f), jac_g(jac_g1, jac_g2), h(h1, h2))
    # Set starting solution
    prob.x = x
    # Solve
    status = solveProblem(prob)

    Dict(:status => Ipopt.ApplicationReturnStatus[status],
         :x => prob.x,
         :value => prob.obj_val)
end
