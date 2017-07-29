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
    .julia$source("./inst/julia/Ipopt2.jl")
    # .Ipopt$IPOPT <- .julia$get_function("IPOPT")
    .Ipopt$IPOPT <- inline::cfunction(
        sig = c(args = "list"),
        body = 'jl_function_t *func = jl_function_t(jl_eval_string("IPOPT1"));
                jl_value_t *args
                jl_call
        // Do something with args (e.g. call jl_... functions)
        JL_GC_POP();
                jl_eval_string(CHAR(STRING_ELT(cmd, 0))); return R_NilValue;',
        includes = "#include <julia.h>",
        cppargs = .julia$cppargs
    )
}
