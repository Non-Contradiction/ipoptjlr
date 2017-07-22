.Ipopt <- new.env(parent = emptyenv())

IPOPT <- function(x,
                  x_L,
                  x_U,
                  g_L,
                  g_U,
                  eval_f,
                  eval_g,
                  eval_grad_f,
                  jac_g1,
                  jac_g2,
                  h1,
                  h2) {
    .Ipopt$IPOPT(x,
                 x_L,
                 x_U,
                 g_L,
                 g_U,
                 eval_f,
                 eval_g,
                 eval_grad_f,
                 jac_g1,
                 jac_g2,
                 h1,
                 h2)
}


setup <- function() {
    julia_setup()
    .julia$using("Ipopt")
    .julia$source("./inst/julia/Ipopt2.jl")
    .Ipopt$IPOPT <- .julia$get_function("IPOPT")
}
