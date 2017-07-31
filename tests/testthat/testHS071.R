context("Optimization Problem HS071")

skip_on_travis()

skip_on_cran()

# HS071
# min x1 * x4 * (x1 + x2 + x3) + x3
# st  x1 * x2 * x3 * x4 >= 25
#     x1^2 + x2^2 + x3^2 + x4^2 = 40
#     1 <= x1, x2, x3, x4 <= 5
# Start at (1,5,5,1)
# End at (1.000..., 4.743..., 3.821..., 1.379...)


x <- c(1.0, 5.0, 5.0, 1.0)
x_L <- c(1.0, 1.0, 1.0, 1.0)
x_U <- c(5.0, 5.0, 5.0, 5.0)

g_L <- c(25.0, 40.0)
g_U <- c(2.0e19, 40.0)

eval_f <- function(x){
    x[1] * x[4] * (x[1] + x[2] + x[3]) + x[3]
}

eval_g <- function(x){
    g = rep(0, 2)
    g[1] = x[1]   * x[2]   * x[3]   * x[4]
    g[2] = x[1]^2 + x[2]^2 + x[3]^2 + x[4]^2
    g
}

eval_grad_f <- function(x){
    grad_f = rep(0, 4)
    grad_f[1] = x[1] * x[4] + x[4] * (x[1] + x[2] + x[3])
    grad_f[2] = x[1] * x[4]
    grad_f[3] = x[1] * x[4] + 1
    grad_f[4] = x[1] * (x[1] + x[2] + x[3])
    grad_f
}

jac_g1 <- function(x){
    rows = rep(0, 8)
    cols = rep(0, 8)
    rows[1] = 1; cols[1] = 1
    rows[2] = 1; cols[2] = 2
    rows[3] = 1; cols[3] = 3
    rows[4] = 1; cols[4] = 4
    # Constraint (row) 2
    rows[5] = 2; cols[5] = 1
    rows[6] = 2; cols[6] = 2
    rows[7] = 2; cols[7] = 3
    rows[8] = 2; cols[8] = 4
    list(rows, cols)
}

jac_g2 <- function(x){
    values = rep(0, 8)
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
}

h1 <- function(x){
    # Symmetric matrix, fill the lower left triangle only
    rows = rep(0, 10)
    cols = rep(0, 10)
    idx = 1
    for (row in 1:4) {
        for (col in 1:row) {
            rows[idx] = row
            cols[idx] = col
            idx = idx + 1
        }
    }
    list(rows, cols)
}

h2 <- function(x, obj_factor, lambda){
    values = rep(0, 10)
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
    values[2] = values[2] + lambda[1] * (x[3] * x[4])  # 2,1
    values[4] = values[4] + lambda[1] * (x[2] * x[4])  # 3,1
    values[5] = values[5] + lambda[1] * (x[1] * x[4])  # 3,2
    values[7] = values[7] + lambda[1] * (x[2] * x[3])  # 4,1
    values[8] = values[8] + lambda[1] * (x[1] * x[3])  # 4,2
    values[9] = values[9] + lambda[1] * (x[1] * x[2])  # 4,3

    # Second constraint
    values[1]  = values[1] + lambda[2] * 2  # 1,1
    values[3]  = values[3] + lambda[2] * 2  # 2,2
    values[6]  = values[6] + lambda[2] * 2  # 3,3
    values[10] = values[10] + lambda[2] * 2  # 4,4

    values
}

library(ipoptjlr)

setup()

r <- IPOPT(x, x_L, x_U, g_L, g_U, eval_f, eval_g, eval_grad_f, jac_g1, jac_g2, h1, h2)

test_that("str_length is number of characters", {
    expect_named(r, c("status", "value", "x"), ignore.order = TRUE)
    expect_equal(r$status, "Solve_Succedded")
    expect_equal(r$x, c(1.000, 4.743, 3.821, 1.379), tolerance = 0.001)
})

