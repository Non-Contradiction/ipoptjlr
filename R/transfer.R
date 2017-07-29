julia_setup()
.julia$cmd("function transfer_list(x) rcopy(RObject(Ptr{RCall.VecSxp}(x))) end")
.julia$cmd("function wrap(f, x) xx = transfer_list(x); f(xx...) end")

.julia$source('./inst/julia/Ipopt2.jl')

wrap <- inline::cfunction(
        sig = c(func_name = "character", arg = "SEXP"),
        body = '
        jl_function_t *wrap = (jl_function_t*)(jl_eval_string("wrap"));
        jl_value_t *func = jl_eval_string(CHAR(STRING_ELT(func_name, 0)));
        jl_value_t *arg1 = jl_box_int64((uintptr_t)(arg));
        jl_call2(wrap, func, arg1);
        return R_NilValue;',
        includes = "#include <julia.h>",
        cppargs = .julia$cppargs
    )

wrap_realsxp <- inline::cfunction(
    sig = c(func_name = "character", arg = "SEXP"),
    body = '
    jl_gc_enable(0);
    jl_function_t *wrap = (jl_function_t*)(jl_eval_string("wrap"));
    jl_value_t *func = jl_eval_string(CHAR(STRING_ELT(func_name, 0)));
    jl_value_t *arg1 = jl_box_int64((uintptr_t)(arg));
    jl_array_t *ret = (jl_array_t*)jl_call2(wrap, func, arg1);
    int n = jl_array_len(ret);
    double *p = (double*)jl_array_data(ret);
    SEXP out = PROTECT(allocVector(REALSXP, n));
    double *pp = REAL(out);
    int i;
    /* for loop execution */
    for (i = 0; i < n; i++){
        pp[i] = p[i];
    }
    UNPROTECT(1);
    return out;',
    includes = "#include <julia.h>",
    cppargs = .julia$cppargs
)

# IPOPT <- inline::cfunction(
#     sig = c(arg = "SEXP"),
#     body = '
#     int n = length(VECTOR_ELT(arg, 0));
#     jl_function_t *func = (jl_function_t*)(jl_eval_string("IPOPT1"));
#     jl_function_t *pop = (jl_function_t*)(jl_eval_string("pop!"));
#     jl_value_t *arg1 = jl_box_int64((uintptr_t)(arg));
#     jl_value_t *ret = jl_call1(func, arg1);
#     //JL_GC_PUSH1(&ret);
#
#     SEXP x = PROTECT(allocVector(REALSXP, n));
#     SEXP obj_value = PROTECT(allocVector(REALSXP, 1));
#
#     REAL(obj_value)[0] = jl_unbox_float64(jl_call1(pop, ret));
#
#     double *xData = REAL(x);
#
#     double *xxData = (double*)jl_array_data((jl_array_t*)jl_call1(pop, ret));
#
#     int i;
#
#     /* for loop execution */
#     for (i = 0; i < n; i++){
#         xData[i] = xxData[i];
#     }
#
#     //JL_GC_POP();
#
#     SEXP vec = PROTECT(allocVector(VECSXP, 2));
#     SET_VECTOR_ELT(vec, 0, x);
#     SET_VECTOR_ELT(vec, 1, obj_value);
#
#     UNPROTECT(3);
#     return vec;',
#     includes = "#include <julia.h>",
#     cppargs = .julia$cppargs
# )
