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
  
  # Test with exponential and custom power
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
  
  # Test with Matern 
  learner$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
  suppressWarnings(learner$train(task))
  prediction = learner$predict(task)
  
  expect_s3_class(prediction, "PredictionRegr")
  expect_true(is.numeric(prediction$response))
  expect_equal(length(prediction$response), task$nrow)
  expect_true(all(!is.na(prediction$response)))
})

# Quality test 

test_that("LearnerRegrGPfit prediction quality on iris_sepal with default params", {
  skip_if_not_installed("GPfit")
  
  # Create task
  iris_numeric = iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")]
  task = as_task_regr(iris_numeric, target = "Sepal.Length", id = "iris_sepal")
  learner = lrn("regr.gpfit")
  
  # Split train/test (70/30)
  set.seed(123)
  train_idx = sample(1:task$nrow, 0.7 * task$nrow)
  test_idx = setdiff(1:task$nrow, train_idx)
  
  # Train
  suppressWarnings(learner$train(task, row_ids = train_idx))
  
  # Predict on train et test
  pred_train = learner$predict(task, row_ids = train_idx)
  mse_train = pred_train$score(msr("regr.mse"))
  
  pred_test = learner$predict(task, row_ids = test_idx)
  mse_test = pred_test$score(msr("regr.mse"))
  
  # Compare with baseline
  learner_baseline = lrn("regr.featureless")
  learner_baseline$train(task, row_ids = train_idx)
  pred_baseline = learner_baseline$predict(task, row_ids = test_idx)
  mse_baseline = pred_baseline$score(msr("regr.mse"))
  
  # Verifications
  expect_true(mse_train < mse_test)  
  expect_true(mse_test < mse_baseline) 
  improvement = (mse_baseline - mse_test) / mse_baseline * 100
  expect_true(improvement > 50)  
})

test_that("LearnerRegrGPfit prediction quality on iris_sepal with Matern", {
  skip_if_not_installed("GPfit")
  
  iris_numeric = iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")]
  task = as_task_regr(iris_numeric, target = "Sepal.Length", id = "iris_sepal")
  learner = lrn("regr.gpfit")
  learner$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
  
  set.seed(123)
  train_idx = sample(1:task$nrow, 0.7 * task$nrow)
  test_idx = setdiff(1:task$nrow, train_idx)
  
  suppressWarnings(learner$train(task, row_ids = train_idx))
  pred_test = learner$predict(task, row_ids = test_idx)
  mse_test = pred_test$score(msr("regr.mse"))
  
  learner_baseline = lrn("regr.featureless")
  learner_baseline$train(task, row_ids = train_idx)
  pred_baseline = learner_baseline$predict(task, row_ids = test_idx)
  mse_baseline = pred_baseline$score(msr("regr.mse"))
  
  expect_true(mse_test < mse_baseline)
  expect_true(mse_test < 0.2)
})

test_that("LearnerRegrGPfit prediction quality on iris_petal with default params", {
  skip_if_not_installed("GPfit")
  
  iris_numeric = iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")]
  task = as_task_regr(iris_numeric, target = "Petal.Length", id = "iris_petal")
  learner = lrn("regr.gpfit")
  
  set.seed(456)
  train_idx = sample(1:task$nrow, 0.7 * task$nrow)
  test_idx = setdiff(1:task$nrow, train_idx)
  
  suppressWarnings(learner$train(task, row_ids = train_idx))
  
  # Scores train et test
  pred_train = learner$predict(task, row_ids = train_idx)
  mse_train = pred_train$score(msr("regr.mse"))
  
  pred_test = learner$predict(task, row_ids = test_idx)
  mse_test = pred_test$score(msr("regr.mse"))
  
  # Baseline
  learner_baseline = lrn("regr.featureless")
  learner_baseline$train(task, row_ids = train_idx)
  pred_baseline = learner_baseline$predict(task, row_ids = test_idx)
  mse_baseline = pred_baseline$score(msr("regr.mse"))
  
  # Verifications
  expect_true(mse_train < mse_test)  
  expect_true(mse_test < mse_baseline)  
  improvement = (mse_baseline - mse_test) / mse_baseline * 100
  expect_true(improvement > 50)
})

test_that("LearnerRegrGPfit prediction quality on iris_petal with custom power", {
  skip_if_not_installed("GPfit")
  
  iris_numeric = iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")]
  task = as_task_regr(iris_numeric, target = "Petal.Length", id = "iris_petal")
  learner = lrn("regr.gpfit")
  learner$param_set$values = list(corr_type = "exponential", corr_power = 1.8)
  
  set.seed(456)
  train_idx = sample(1:task$nrow, 0.7 * task$nrow)
  test_idx = setdiff(1:task$nrow, train_idx)
  
  suppressWarnings(learner$train(task, row_ids = train_idx))
  pred_test = learner$predict(task, row_ids = test_idx)
  mse_test = pred_test$score(msr("regr.mse"))
  
  learner_baseline = lrn("regr.featureless")
  learner_baseline$train(task, row_ids = train_idx)
  pred_baseline = learner_baseline$predict(task, row_ids = test_idx)
  mse_baseline = pred_baseline$score(msr("regr.mse"))
  
  expect_true(mse_test < mse_baseline)
  expect_true(mse_test < 0.5)
})

