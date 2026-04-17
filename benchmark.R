cat("=== Importing packages ===\n")

library(mlr3)
library(mlr3learners)
library(mlr3learners.gpfit)
library(mlr3tuning)
library(paradox)
library(ggplot2)
library(data.table)

cat("=== Configuration ===\n")

n_folds <- 5
max_k <- 30
seed <- 42
set.seed(seed)

cat("  - Number of folds:", n_folds, "\n")
cat("  - Max k for KNN:", max_k, "\n")
cat("  - Seed:", seed, "\n\n")

cat("=== Data preparation ===\n")

# Iris dataset to predict Sepal.Length
data(iris)
df_iris_sepal <- as.data.table(iris)
df_iris_sepal[, Species := NULL]
setnames(df_iris_sepal, "Sepal.Length", "y")

# Iris dataset to predict Petal.Length
df_iris_petal <- as.data.table(iris)
df_iris_petal[, Species := NULL]
setnames(df_iris_petal, "Petal.Length", "y")

cat("  - iris_sepal:", nrow(df_iris_sepal), "observations,", ncol(df_iris_sepal)-1, "features\n")
cat("  - iris_petal:", nrow(df_iris_petal), "observations,", ncol(df_iris_petal)-1, "features\n\n")

cat("=== Creating tasks ===\n")

task_list <- list(
  iris_sepal = TaskRegr$new("iris_sepal", df_iris_sepal, target = "y"),
  iris_petal = TaskRegr$new("iris_petal", df_iris_petal, target = "y")
)

cat("Tasks created:\n")
print(task_list)
cat("\n")

cat("=== Defining learners ===\n")

# GPfit learner
learner_gpfit <- lrn("regr.gpfit", id = "gpfit")

# Featureless baseline
learner_featureless <- lrn("regr.featureless", id = "featureless")

# CV-Glmnet (linear model)
learner_glmnet <- lrn("regr.cv_glmnet", id = "cv_glmnet")

# KNN with tuning (k from 1 to 30)
knn_learner <- lrn("regr.kknn")
knn_learner$param_set$values$k <- to_tune(1, max_k)

kfoldcv <- rsmp("cv")
kfoldcv$param_set$values$folds <- 3

learner_knn <- auto_tuner(
  learner = knn_learner,
  tuner = tnr("grid_search"),
  resampling = kfoldcv,
  measure = msr("regr.mse")
)
learner_knn$id <- "knn"

# Final learner list
learner.list <- list(
  gpfit = learner_gpfit,
  featureless = learner_featureless,
  cv_glmnet = learner_glmnet,
  knn = learner_knn
)

cat("=== Running benchmark ===\n")
cat("Configuration: 2 datasets × 4 learners × 5 folds = 40 experiments\n\n")

rsmp_cv <- rsmp("cv", folds = n_folds)

bench.grid <- benchmark_grid(
  task_list,
  learner.list,
  rsmp_cv
)

start_time <- Sys.time()
cat("Start:", format(start_time, "%H:%M:%S"), "\n")

bench.result <- tryCatch(
  suppressWarnings(benchmark(bench.grid, store_models = TRUE)),
  error = function(e) {
    benchmark(bench.grid, store_models = FALSE)
  }
)
if (is.null(bench.result)) {
  cat("\nERROR: Benchmark failed completely. Exiting.\n")
  stop("Benchmark failed due to numerical instability.")
}

end_time <- Sys.time()
duration <- difftime(end_time, start_time, units = "mins")
cat("End:", format(end_time, "%H:%M:%S"), "\n")
cat("Duration:", round(duration, 2), "minutes\n\n")

cat("=== Computing scores ===\n")

test_measure_list <- msrs("regr.mse")
score_dt <- bench.result$score(test_measure_list)

# Display scores
cat("\nDetailed scores:\n")
print(score_dt[, .(task_id, learner_id, iteration, regr.mse)])

cat("\n=== Creating plot ===\n")
gg <- ggplot(score_dt, aes(x = regr.mse, y = learner_id)) +
  geom_point(size = 3, alpha = 0.7) +
  facet_grid(task_id ~ ., scales = "free_x") +
  labs(
    x = "Mean Squared Error (MSE)", 
    y = "Algorithm",
    title = "Prediction Error in 5-Fold Cross-Validation"
  ) +
  theme_bw()

print(gg)

# Save plot
ggsave("benchmark_results.png", gg, width = 10, height = 6, dpi = 300)
cat("Plot saved: benchmark_results.png\n\n")

cat("\n=== Results analysis ===\n")

# Compute means
mean_err <- score_dt[
  ,
  .(mean_mse = mean(regr.mse)),
  by = .(task_id, learner_id)
]

mean_err <- mean_err[order(task_id, mean_mse)]

cat("Mean errors by algorithm:\n")
print(mean_err)
cat("\n")

cat("QUESTION 1: Does GPfit learn non-trivial patterns?\n")

for (dataset in unique(score_dt$task_id)) {
  gpfit_mse <- mean(score_dt[task_id == dataset & learner_id == "gpfit", regr.mse])
  featureless_mse <- mean(score_dt[task_id == dataset & learner_id == "featureless", regr.mse])
  
  improvement <- ((featureless_mse - gpfit_mse) / featureless_mse) * 100
  
  cat(sprintf("Dataset: %s\n", dataset))
  cat(sprintf("  - GPfit MSE:        %.4f\n", gpfit_mse))
  cat(sprintf("  - Featureless MSE:  %.4f\n", featureless_mse))
  cat(sprintf("  - Improvement:      %.2f%%\n", improvement))
  
  if (improvement > 0) {
    cat(sprintf("  YES, GPfit learns non-trivial patterns\n\n"))
  } else {
    cat("  No, no significant learning\n\n")
  }
}

cat("QUESTION 2: Is GPfit as good as other algorithms?\n")

for (dataset in unique(score_dt$task_id)) {
  cat(sprintf("Dataset: %s\n", dataset))
  
  perf <- mean_err[task_id == dataset][order(mean_mse)]
  
  for (i in 1:nrow(perf)) {
    cat(sprintf("  %d. %-15s MSE = %.4f\n", 
                i, 
                perf$learner_id[i], 
                perf$mean_mse[i]))
  }
  
  gpfit_rank <- which(perf$learner_id == "gpfit")
  cat(sprintf("\n  GPfit ranks #%d out of %d\n", gpfit_rank, nrow(perf)))
  
  if (gpfit_rank == 1) {
    cat("  GPfit is the BEST!\n\n")
  } else if (gpfit_rank <= 2) {
    cat("  GPfit is very competitive (top 2)\n\n")
  } else {
    cat("  GPfit is outperformed by other methods\n\n")
  }
}
devtools::load_all()  # SI tu développes
library(mlr3learners.gpfit) 
# Validation of hyperparameters on iris datasets
validate_hyperparameters = function(task, seed = 123) {
  set.seed(seed)
  train_idx = sample(1:task$nrow, 0.7 * task$nrow)
  test_idx = setdiff(1:task$nrow, train_idx)
  
  # Configurations to test
  configs = list(
    list(name = "Default (exponential, power=1.95)", params = list()),
    list(name = "Matern (nu=1.5)", params = list(corr_type = "matern", corr_nu = 1.5)),
    list(name = "Exponential (power=1.8)", params = list(corr_type = "exponential", corr_power = 1.8))
  )
  
  results = data.table()
  
  for (config in configs) {
    learner = lrn("regr.gpfit")
    if (length(config$params) > 0) {
      learner$param_set$values = config$params
    }
    
    # Try to train, skip if error
    train_success = tryCatch({
      suppressWarnings(learner$train(task, row_ids = train_idx))
      TRUE
    }, error = function(e) {
      cat("  WARNING: Config '", config$name, "' failed (numerical instability)\n", sep = "")
      FALSE
    })
    
    if (!train_success) {
      next  # Skip this configuration
    }
    
    pred_train = learner$predict(task, row_ids = train_idx)
    pred_test = learner$predict(task, row_ids = test_idx)
    
    mse_train = pred_train$score(msr("regr.mse"))
    mse_test = pred_test$score(msr("regr.mse"))
    
    results = rbind(results, data.table(
      Configuration = config$name,
      MSE_Train = round(mse_train, 4),
      MSE_Test = round(mse_test, 4)
    ))
  }
  
  # Baseline
  learner_baseline = lrn("regr.featureless")
  learner_baseline$train(task, row_ids = train_idx)
  pred_train_baseline = learner_baseline$predict(task, row_ids = train_idx)
  pred_test_baseline = learner_baseline$predict(task, row_ids = test_idx)
  
  mse_train_baseline = pred_train_baseline$score(msr("regr.mse"))
  mse_test_baseline = pred_test_baseline$score(msr("regr.mse"))
  
  results = rbind(results, data.table(
    Configuration = "Baseline (featureless)",
    MSE_Train = round(mse_train_baseline, 4),
    MSE_Test = round(mse_test_baseline, 4)
  ))
  
  # Compute improvements (only for non-baseline)
  if (nrow(results) > 1) {
    results[, Improvement := ifelse(
      Configuration == "Baseline (featureless)",
      "-",
      sprintf("%.1f%%", (mse_test_baseline - MSE_Test) / mse_test_baseline * 100)
    )]
  }
  
  return(results)
}

# Validation on iris_sepal
cat("Dataset: iris_sepal (70% train / 30% test)\n")
results_sepal = validate_hyperparameters(task_list$iris_sepal, seed = 123)
print(results_sepal)
cat("\n")

# Validation on iris_petal
cat("Dataset: iris_petal (70% train / 30% test)\n")
results_petal = validate_hyperparameters(task_list$iris_petal, seed = 456)
print(results_petal)
cat("\n")

# Save validation results
fwrite(results_sepal, "validation_iris_sepal.csv")
fwrite(results_petal, "validation_iris_petal.csv")
cat("Validation results saved:\n")
cat("  - validation_iris_sepal.csv\n")
cat("  - validation_iris_petal.csv\n\n")

cat("\n=== Saving benchmark results ===\n")

# Save only important columns
score_dt_export <- score_dt[, .(task_id, learner_id, iteration, regr.mse)]
fwrite(score_dt_export, "benchmark_detailed_results.csv")
fwrite(mean_err, "benchmark_summary.csv")

cat("\n=== Displaying results ===\n")

cat("--- benchmark_detailed_results.csv ---\n")
print(score_dt_export)
cat("\n")

cat("--- benchmark_summary.csv ---\n")
print(mean_err)
cat("\n")
