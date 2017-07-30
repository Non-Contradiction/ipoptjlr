Sys.setenv("R_TESTS" = "")
library(testthat)
library(ipoptjlr)

test_check("ipoptjlr")
