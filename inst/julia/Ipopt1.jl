# HS071
# min x1 * x4 * (x1 + x2 + x3) + x3
# st  x1 * x2 * x3 * x4 >= 25
#     x1^2 + x2^2 + x3^2 + x4^2 = 40
#     1 <= x1, x2, x3, x4 <= 5
# Start at (1,5,5,1)
# End at (1.000..., 4.743..., 3.821..., 1.379...)
using Ipopt
using RCall
n = 4
x_L = [1.0, 1.0, 1.0, 1.0]
x_U = [5.0, 5.0, 5.0, 5.0]

m = 2
g_L = [25.0, 40.0]
g_U = [2.0e19, 40.0]

function eval_f(x)
  return x[1] * x[4] * (x[1] + x[2] + x[3]) + x[3]
end

function id(f)
    function ff(x)
        f(x)
    end
    ff
end

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


function createProblem1(
    n::Int,                     # Number of variables
    x_L::Vector{Float64},       # Variable lower bounds
    x_U::Vector{Float64},       # Variable upper bounds
    m::Int,                     # Number of constraints
    g_L::Vector{Float64},       # Constraint lower bounds
    g_U::Vector{Float64},       # Constraint upper bounds
    nele_jac::Int,              # Number of non-zeros in Jacobian
    nele_hess::Int,             # Number of non-zeros in Hessian
    eval_f,                     # Callback: objective function
    eval_g,                     # Callback: constraint evaluation
    eval_grad_f,                # Callback: objective function gradient
    jac_g1, jac_g2,             # Callback: Jacobian evaluation
    h1, h2)
    createProblem(n, x_L, x_U, m, g_L, g_U, nele_jac, nele_hess,
        eval_f, xy(eval_g), xy(eval_grad_f), jac_g(jac_g1, jac_g2), h(h1, h2))
end


function eval_g(x)
    g = zeros(2)
    g[1] = x[1]   * x[2]   * x[3]   * x[4]
    g[2] = x[1]^2 + x[2]^2 + x[3]^2 + x[4]^2
    g
end

function eval_grad_f(x)
    grad_f = zeros(4)
    grad_f[1] = x[1] * x[4] + x[4] * (x[1] + x[2] + x[3])
    grad_f[2] = x[1] * x[4]
    grad_f[3] = x[1] * x[4] + 1
    grad_f[4] = x[1] * (x[1] + x[2] + x[3])
    grad_f
end

function jac_g1()
    cols = zeros(Int32, 8)
    rows = zeros(Int32, 8)
    rows[1] = 1;
    rows[2] = 1;
    rows[3] = 1;
    rows[4] = 1;
    # Constraint (row) 2
    rows[5] = 2;
    rows[6] = 2;
    rows[7] = 2;
    rows[8] = 2;

    cols[1] = 1
    cols[2] = 2
    cols[3] = 3
    cols[4] = 4
    # Constraint (row) 2
    cols[5] = 1
    cols[6] = 2
    cols[7] = 3
    cols[8] = 4

    [rows, cols]
end

function jac_g2(x)
    values = zeros(8)
    # Constraint (row) 1
    values[1] = x[2]*x[3]*x[4]  # 1,1
    values[2] = x[1]*x[3]*x[4]  # 1,2
    values[3] = x[1]*x[2]*x[4]  # 1,3
    values[4] = x[1]*x[2]*x[3]  # 1,4
    # Constraint (row) 2
    values[5] = 2*x[1]  # 2,1
    values[6] = 2*x[2]  # 2,2
    values[7] = 2*x[3]  # 2,3
    values[8] = 2*x[4]  # 2,4
    values
end

function h1()
    # Symmetric matrix, fill the lower left triangle only
    rows = zeros(Int32, 10)
    cols = zeros(Int32, 10)
    idx = 1
    for row = 1:4
      for col = 1:row
        rows[idx] = row
        cols[idx] = col
        idx += 1
      end
    end
    [rows, cols]
end

function h2(x, obj_factor, lambda)
    values = zeros(10)
    # Again, only lower left triangle
    # Objective
    values[1] = obj_factor * (2*x[4])  # 1,1
    values[2] = obj_factor * (  x[4])  # 2,1
    values[3] = 0                      # 2,2
    values[4] = obj_factor * (  x[4])  # 3,1
    values[5] = 0                      # 3,2
    values[6] = 0                      # 3,3
    values[7] = obj_factor * (2*x[1] + x[2] + x[3])  # 4,1
    values[8] = obj_factor * (  x[1])  # 4,2
    values[9] = obj_factor * (  x[1])  # 4,3
    values[10] = 0                     # 4,4

    # First constraint
    values[2] += lambda[1] * (x[3] * x[4])  # 2,1
    values[4] += lambda[1] * (x[2] * x[4])  # 3,1
    values[5] += lambda[1] * (x[1] * x[4])  # 3,2
    values[7] += lambda[1] * (x[2] * x[3])  # 4,1
    values[8] += lambda[1] * (x[1] * x[3])  # 4,2
    values[9] += lambda[1] * (x[1] * x[2])  # 4,3

    # Second constraint
    values[1]  += lambda[2] * 2  # 1,1
    values[3]  += lambda[2] * 2  # 2,2
    values[6]  += lambda[2] * 2  # 3,3
    values[10] += lambda[2] * 2  # 4,4

    values
end

#prob = createProblem1(n, x_L, x_U, m, g_L, g_U, 8, 10,
#    eval_f, eval_g, eval_grad_f, jac_g1, jac_g2, h1, h2)

# Set starting solution
#prob.x = [1.0, 5.0, 5.0, 1.0]

# Solve
#status = solveProblem(prob)

#println(Ipopt.ApplicationReturnStatus[status])
#println(prob.x)
#println(prob.obj_val)

function createProblem2(
    x,         # Number of variables
    x_L,       # Variable lower bounds
    x_U,       # Variable upper bounds
    m,                     # Number of constraints
    g_L,       # Constraint lower bounds
    g_U,       # Constraint upper bounds
    nele_jac,              # Number of non-zeros in Jacobian
    nele_hess,             # Number of non-zeros in Hessian
    eval_f,                     # Callback: objective function
    eval_g,                     # Callback: constraint evaluation
    eval_grad_f,                # Callback: objective function gradient
    jac_g1, jac_g2,             # Callback: Jacobian evaluation
    h1, h2)
    prob = createProblem(length(x), x_L, x_U, Int64(m), g_L, g_U, Int64(nele_jac), Int64(nele_hess),
        id(eval_f), xy(eval_g), xy(eval_grad_f), jac_g(jac_g1, jac_g2), h(h1, h2))
    prob.x = x
    status = solveProblem(prob)

    [Ipopt.ApplicationReturnStatus[status], prob.x, prob.obj_val]
end

function transfer(x)
    rcopy(RObject(x))
end

r = RObject(createProblem2)(RObject([1.0, 5.0, 5.0, 1.0]), RObject(x_L), RObject(x_U), RObject(m), RObject(g_L), RObject(g_U), RObject(8), RObject(10),
   RObject(eval_f), RObject(eval_g), RObject(eval_grad_f), RObject(jac_g1), RObject(jac_g2), RObject(h1), RObject(h2))

#
# r = createProblem2([1.0, 5.0, 5.0, 1.0], transfer(x_L), transfer(x_U), Int64(transfer(m)), transfer(g_L), transfer(g_U), Int64(transfer(8)), Int64(transfer(10)),
#     eval_f, transfer(eval_g), transfer(eval_grad_f), transfer(jac_g1), transfer(jac_g2), transfer(h1), transfer(h2))
