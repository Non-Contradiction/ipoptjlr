.Ipopt <- new.env(parent = emptyenv())

#' Use Ipopt solver to solve optimization problems.
#'
#' \code{IPOPT} returns the solution to the optimization problem found by Ipopt solver.
#'
#' @param x         Starting point
#' @param x_L       Variable lower bounds
#' @param x_U       Variable upper bounds
#' @param g_L       Constraint lower bounds
#' @param g_U       Constraint upper bounds
#' @param eval_f                     Callback: objective function
#' @param eval_g                     Callback: constraint evaluation
#' @param eval_grad_f                Callback: objective function gradient
#' @param jac_g1,jac_g2              Callback: Jacobian evaluation
#' @param h1,h2                      Callback: Hessian evaluation
#'
#' @return The return value will be a list which contains three components:
#'   status: the status of the ipopt solver,
#'   value: the optimized objective value,
#'   x: the best set of parameters found.
#'
#' @export
IPOPT <- function(x,
                  x_L,
                  x_U,
                  g_L,
                  g_U,
                  eval_f,
                  eval_g,
                  eval_grad_f,
                  jac_g1, jac_g2,
                  h1, h2) {
    .julia$wrap_all("IPOPT", list(x, x_L, x_U, g_L, g_U, eval_f,
                                  eval_g, eval_grad_f, jac_g1, jac_g2, h1, h2))
}

#' Do initial setup for the ipoptjlr package.
#'
#' \code{setup} does the initial setup for the ipoptjlr package.
#'
#' @examples
#' setup()
#'
#' @export
setup <- function() {
    julia_setup()
    .julia$source(system.file("julia/Ipopt2.jl", package = "ipoptjlr"))
}
