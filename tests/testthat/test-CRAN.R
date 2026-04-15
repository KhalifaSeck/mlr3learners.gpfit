library(testthat)
library(mlr3)

test_that("LearnerRegrGPfit train and predict work", {
  skip_if_not_installed("GPfit")
  
  # Creation de la task using mlr3::tsk()
  task = tsk("mtcars")
  
  # Creation de la learner
  learner = lrn("regr.gpfit")
  
  # Entraînement du modèle
  suppressWarnings(learner$train(task))
  
  # Vérification que le modèle a été entraîné et est de la classe attendue
  expect_true(!is.null(learner$model))
  expect_s3_class(learner$model, "GP")
  
  # Prediction
  prediction = learner$predict(task)
  
  # Vérification des prédictions
  expect_true(is.numeric(prediction$response))
  expect_equal(length(prediction$response), task$nrow)
  expect_true(all(!is.na(prediction$response)))
  expect_true(sd(prediction$response) > 0)
})

test_that("LearnerRegrGPfit learns non-trivial patterns", {
  skip_if_not_installed("GPfit")
  
  task = tsk("mtcars")
  
  # GP learner
  learner_gp = lrn("regr.gpfit")
  suppressWarnings(learner_gp$train(task))
  pred_gp = learner_gp$predict(task)
  mse_gp = pred_gp$score(msr("regr.mse"))
  
  # Featureless baseline learner
  learner_fl = lrn("regr.featureless")
  learner_fl$train(task)
  pred_fl = learner_fl$predict(task)
  mse_fl = pred_fl$score(msr("regr.mse"))
  
  # GP doit faire mieux que le baseline
  expect_true(mse_gp < mse_fl)
})

