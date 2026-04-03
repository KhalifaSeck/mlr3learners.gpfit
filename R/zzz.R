#' @import data.table
#' @import mlr3
#' @importFrom R6 R6Class
#' @importFrom GPfit GP_fit
"_PACKAGE"

.onLoad = function(libname, pkgname) {
  # Register the learner in mlr3
  mlr3::mlr_learners$add("regr.gpfit", LearnerRegrGPfit)
}