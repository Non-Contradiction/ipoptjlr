.julia <- new.env(parent = emptyenv())

julia_setup <- function() {
    .julia$bin_dir <-
        system("julia -E 'println(JULIA_HOME)'", intern = TRUE)[1]
    .julia$dll_file <-
        system("julia -E 'println(Libdl.dllist()[1])'", intern = TRUE)[1]
    .julia$dll <- dyn.load(.julia$dll_file, FALSE, TRUE)
    .julia$include_dir <-
        sub("/bin", "/include/julia", .julia$bin_dir)
    .julia$cppargs <- paste0("-I ", .julia$include_dir)

    .julia$VERSION <- system("julia -E 'println(VERSION)'", intern = TRUE)[1]

    if (.julia$VERSION < "0.6.0") {
        .julia$init <- inline::cfunction(
            sig = c(dir = "character"),
            body = "jl_init(CHAR(STRING_ELT(dir, 0))); return R_NilValue;",
            includes = "#include <julia.h>",
            cppargs = .julia$cppargs
        )

        message("Julia initiation...")

        .julia$init(.julia$bin_dir)
    }
    if (.julia$VERSION >= "0.6.0") {
        .julia$init <- inline::cfunction(
            sig = c(),
            body = "jl_init(); return R_NilValue;",
            includes = "#include <julia.h>",
            cppargs = .julia$cppargs
        )

        message("Julia initiation...")

        .julia$init()
    }

    .julia$cmd <- inline::cfunction(
        sig = c(cmd = "character"),
        body = "jl_eval_string(CHAR(STRING_ELT(cmd, 0))); return R_NilValue;",
        includes = "#include <julia.h>",
        cppargs = .julia$cppargs
    )

    .julia$source <- function(file_name) {
        .julia$cmd(readr::read_file(file_name))
    }

    .julia$install_package <- function(pkg_name) {
        .julia$cmd(paste0('Pkg.add("', pkg_name, '")'))
    }

    .julia$install_packages <- Vectorize(.julia$install_package)

    .julia$using <- function(pkg) {
        .julia$cmd(paste0("using ", pkg))
    }

    .julia$eval2 <- inline::cfunction(
        sig = c(cmd = "character"),
        body = "return SEXP(jl_eval_string(CHAR(STRING_ELT(cmd, 0)))); ",
        includes = "#include <julia.h>",
        cppargs = .julia$cppargs
    )

    .julia$get_function <- function(cmd) {
        .julia$eval2(paste0("unsafe_load(RObject(", cmd, ").p)"))
    }

    reg.finalizer(.julia, function(e){message("Julia exit."); .julia$cmd("exit()")}, onexit = TRUE)

    .julia$using("RCall")

    #.julia$evals <- .julia$get_function("function(x)eval(parse(x)) end")
}
