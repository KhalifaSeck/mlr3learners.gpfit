library(testthat)
library(mlr3)

test_that("LearnerRegrGPfit train and predict work", {
  skip_if_not_installed("GPfit")
  
  task = tsk("mtcars")
  learner = lrn("regr.gpfit")
  
  suppressWarnings(learner$train(task))
  
  expect_true(!is.null(learner$model))
  expect_s3_class(learner$model, "GP")
  
  prediction = learner$predict(task)
  
  expect_true(is.numeric(prediction$response))
  expect_equal(length(prediction$response), task$nrow)
  expect_true(all(!is.na(prediction$response)))
  expect_true(sd(prediction$response) > 0)
})

test_that("LearnerRegrGPfit learns non-trivial patterns", {
  skip_if_not_installed("GPfit")
  
  task = tsk("mtcars")
  
  learner_gp = lrn("regr.gpfit")
  suppressWarnings(learner_gp$train(task))
  pred_gp = learner_gp$predict(task)
  mse_gp = pred_gp$score(msr("regr.mse"))
  
  learner_fl = lrn("regr.featureless")
  learner_fl$train(task)
  pred_fl = learner_fl$predict(task)
  mse_fl = pred_fl$score(msr("regr.mse"))
  
  expect_true(mse_gp < mse_fl)
})

test_that("LearnerRegrGPfit hyperparameters work with exponential", {
  skip_if_not_installed("GPfit")
  
  task = tsk("mtcars")
  learner = lrn("regr.gpfit")
  
  # Test avec exponential et power personnalisé
  learner$param_set$values = list(corr_type = "exponential", corr_power = 1.9)
  suppressWarnings(learner$train(task))
  prediction = learner$predict(task)
  
  expect_s3_class(prediction, "PredictionRegr")
  expect_true(is.numeric(prediction$response))
  expect_equal(length(prediction$response), task$nrow)
  expect_true(all(!is.na(prediction$response)))
})

test_that("LearnerRegrGPfit hyperparameters work with matern", {
  skip_if_not_installed("GPfit")
  
  task = tsk("mtcars")
  learner = lrn("regr.gpfit")
  
  # Test avec Matérn
  learner$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
  suppressWarnings(learner$train(task))
  prediction = learner$predict(task)
  
  expect_s3_class(prediction, "PredictionRegr")
  expect_true(is.numeric(prediction$response))
  expect_equal(length(prediction$response), task$nrow)
  expect_true(all(!is.na(prediction$response)))
})


