Sys.setenv("R_TESTS" = "")
JuliaCall::julia_setup()
library(testthat)
library(ipoptjlr)

test_check("ipoptjlr")
