## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width = 10,
  fig.height = 6,
  collapse = TRUE,
  comment = "#>"
)


## ----packages-----------------------------------------------------------------
cat("=== Importation des packages ===\n")

library(mlr3)
library(mlr3learners)
library(mlr3learners.gpfit)
library(mlr3tuning)
library(paradox)
library(ggplot2)
library(data.table)


## ----config-------------------------------------------------------------------
cat("=== Configuration ===\n")

n_folds <- 5
max_k <- 30
seed <- 42
set.seed(seed)

cat("  - Nombre de folds:", n_folds, "\n")
cat("  - k max pour KNN:", max_k, "\n")
cat("  - Seed:", seed, "\n\n")


## ----data---------------------------------------------------------------------
cat("=== Préparation des données ===\n")

# Dataset Iris pour prédire Sepal.Length
data(iris)
df_iris_sepal <- as.data.table(iris)
df_iris_sepal[, Species := NULL]
setnames(df_iris_sepal, "Sepal.Length", "y")

# Dataset Iris pour prédire Petal.Length
df_iris_petal <- as.data.table(iris)
df_iris_petal[, Species := NULL]
setnames(df_iris_petal, "Petal.Length", "y")

cat("  - iris_sepal:", nrow(df_iris_sepal), "observations,", ncol(df_iris_sepal)-1, "features\n")
cat("  - iris_petal:", nrow(df_iris_petal), "observations,", ncol(df_iris_petal)-1, "features\n\n")


## ----tasks--------------------------------------------------------------------
cat("=== Création des tâches ===\n")

task_list <- list(
  iris_sepal = TaskRegr$new("iris_sepal", df_iris_sepal, target = "y"),
  iris_petal = TaskRegr$new("iris_petal", df_iris_petal, target = "y")
)

cat("Tâches créées:\n")
print(task_list)
cat("\n")


## ----learners-----------------------------------------------------------------
cat("=== Définition des learners ===\n")

# Application de GPfit 
learner_gpfit <- lrn("regr.gpfit", id = "gpfit")
cat("  1. GPfit (Gaussian Process)\n")

# Application de Featureless 
learner_featureless <- lrn("regr.featureless", id = "featureless")
cat("  2. Featureless (baseline)\n")

# Application de CV-Glmnet (modèle linéaire)
learner_glmnet <- lrn("regr.cv_glmnet", id = "cv_glmnet")
cat("  3. CV-Glmnet (linear model)\n")

# Application de KNN avec tuning (k entre 1 et 30)
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
cat("  4. KNN with tuning (k=1 to", max_k, ")\n\n")

# Liste finale des learners
learner.list <- list(
  gpfit = learner_gpfit,
  featureless = learner_featureless,
  cv_glmnet = learner_glmnet,
  knn = learner_knn
)


## ----benchmark----------------------------------------------------------------
cat("=== Lancement du benchmark ===\n")
cat("Configuration: 2 datasets × 4 learners × 5 folds = 40 expériences\n\n")

rsmp_cv <- rsmp("cv", folds = n_folds)

bench.grid <- benchmark_grid(
  task_list,
  learner.list,
  rsmp_cv
)

start_time <- Sys.time()
cat("Début:", format(start_time, "%H:%M:%S"), "\n")

bench.result <- suppressWarnings(benchmark(bench.grid, store_models = TRUE))

end_time <- Sys.time()
duration <- difftime(end_time, start_time, units = "mins")
cat("Fin:", format(end_time, "%H:%M:%S"), "\n")
cat("Durée:", round(duration, 2), "minutes\n\n")


## ----scores-------------------------------------------------------------------
cat("=== Calcul des scores ===\n")

test_measure_list <- msrs("regr.mse")
score_dt <- bench.result$score(test_measure_list)

# Afficher les scores
cat("\nScores détaillés:\n")
print(score_dt[, .(task_id, learner_id, iteration, regr.mse)])


## ----scores_table-------------------------------------------------------------
knitr::kable(
  score_dt[, .(task_id, learner_id, iteration, regr.mse)],
  caption = "Scores MSE pour chaque fold de validation croisée",
  digits = 4
)


## ----plot, fig.cap="Erreur de prédiction en validation croisée à 5 folds"-----
cat("\n=== Création du graphique ===\n")

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


## ----mean_errors--------------------------------------------------------------
cat("\n=== Analyse des résultats ===\n")

# Calcul des moyennes
mean_err <- score_dt[
  ,
  .(mean_mse = mean(regr.mse)),
  by = .(task_id, learner_id)
]

mean_err <- mean_err[order(task_id, mean_mse)]

cat("Erreurs moyennes par algorithme:\n")
print(mean_err)
cat("\n")


## ----mean_table---------------------------------------------------------------
knitr::kable(
  mean_err,
  caption = "Erreurs moyennes (MSE) par algorithme et dataset",
  digits = 4,
  col.names = c("Dataset", "Algorithme", "MSE Moyen")
)


## ----question1----------------------------------------------------------------
cat("QUESTION 1: Est-ce que GPfit apprend quelque chose de non-trivial?\n")
cat("--------------------------------------------------------------------\n\n")

for (dataset in unique(score_dt$task_id)) {
  gpfit_mse <- mean(score_dt[task_id == dataset & learner_id == "gpfit", regr.mse])
  featureless_mse <- mean(score_dt[task_id == dataset & learner_id == "featureless", regr.mse])
  
  improvement <- ((featureless_mse - gpfit_mse) / featureless_mse) * 100
  
  cat(sprintf("Dataset: %s\n", dataset))
  cat(sprintf("  - GPfit MSE:        %.4f\n", gpfit_mse))
  cat(sprintf("  - Featureless MSE:  %.4f\n", featureless_mse))
  cat(sprintf("  - Amélioration:     %.2f%%\n", improvement))
  
  if (improvement > 0) {
    cat(sprintf("  OUI, GPfit apprend des patterns non-triviaux\n\n"))
  } else {
    cat("  Non, pas d'apprentissage significatif\n\n")
  }
}


## ----question2----------------------------------------------------------------
cat("QUESTION 2: GPfit est-il aussi bon que les autres algorithmes?\n")
cat("--------------------------------------------------------------------\n\n")

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
  cat(sprintf("\n  GPfit se classe #%d sur %d\n", gpfit_rank, nrow(perf)))
  
  if (gpfit_rank == 1) {
    cat("   GPfit est le MEILLEUR!\n\n")
  } else if (gpfit_rank <= 2) {
    cat("  GPfit est très compétitif (top 2)\n\n")
  } else {
    cat("  GPfit est surpassé par d'autres méthodes\n\n")
  }
}


## ----save_results-------------------------------------------------------------
cat("\n=== Sauvegarde des résultats ===\n")

# Sauvegarder seulement les colonnes importantes
score_dt_export <- score_dt[, .(task_id, learner_id, iteration, regr.mse)]

cat("Résultats détaillés:\n")
print(score_dt_export)
cat("\n")

cat("Résumé:\n")
print(mean_err)
cat("\n")


## ----session_info-------------------------------------------------------------
sessionInfo()

