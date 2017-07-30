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
    .julia$wrap_all("IPOPT", list(x, x_L, x_U, g_L, g_U, eval_f,
                                  eval_g, eval_grad_f, jac_g1, jac_g2, h1, h2))
}


setup <- function() {
    julia_setup()
    .julia$source(system.file("julia/Ipopt2.jl", package = "ipoptjlr"))
}
