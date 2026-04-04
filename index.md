# mlr3learners.gpfit

Learner de régression par Processus Gaussiens pour
[mlr3](https://mlr3.mlr-org.com/) utilisant le package
[GPfit](https://CRAN.R-project.org/package=GPfit).

**Note** : Ce package implémente **GPfit** (R pur) au lieu de
**GPyTorch** (Python) comme suggéré dans l’[issue
\#487](https://github.com/mlr-org/mlr3extralearners/issues/487). GPfit a
été choisi pour éviter les dépendances Python (reticulate) et fournir
une implémentation entièrement en R, plus simple à maintenir et
déployer.

## Documentation

📚 **Site web complet** : <https://mlr3learners-gpfit.netlify.app/>

Contient : - Documentation complète de toutes les fonctions - Guide
d’utilisation - Exemples de code

## Installation

Installation depuis GitHub :

``` r
# install.packages("remotes")
remotes::install_github("KhalifaSeck/mlr3learners.gpfit")
```

## Utilisation

``` r
library(mlr3)
library(mlr3learners.gpfit)

# Créer une tâche de régression avec iris
task = as_task_regr(iris, target = "Sepal.Length", id = "iris_sepal")

# Créer le learner GP
learner = lrn("regr.gpfit")

# Entraîner le modèle
learner$train(task)

# Faire des prédictions
prediction = learner$predict(task)
print(prediction)

# Évaluer la performance
prediction$score(msr("regr.mse"))
```

## Résultats du benchmark

GPfit a été comparé à 3 autres algorithmes sur 2 jeux de données de
régression (validation croisée à 5 folds) :

| Jeu de données | GPfit      | CV-Glmnet | KNN    | Featureless |
|----------------|------------|-----------|--------|-------------|
| iris_sepal     | **0.1002** | 0.1103    | 0.1311 | 0.6850      |
| iris_petal     | **0.0696** | 0.1194    | 0.1075 | 3.1047      |

**GPfit obtient les meilleures performances sur les deux jeux de données
!** 🏆

L’analyse complète du benchmark est disponible dans le fichier
`vignettes/benchmark.Rmd` du package.

## Développement

Ce package inclut :

- ✅ **7 tests unitaires** (100% réussis)
- ✅ **Vignette** avec analyse complète du benchmark
- ✅ **Intégration continue** via GitHub Actions
- ✅ **Couverture de code** suivie via Codecov
- ✅ **Site web de documentation** déployé sur Netlify

## Travaux connexes

- **Wiki du cours** :
  <https://github.com/tdhock/2026-01-aa-grande-echelle/wiki/projets>
- **Package GPfit** : <https://CRAN.R-project.org/package=GPfit>
- **Issue mlr3extralearners \#487** :
  <https://github.com/mlr-org/mlr3extralearners/issues/487> (GPyTorch →
  GPfit)
- **Livre mlr3** : <https://mlr3book.mlr-org.com/>

## Auteur

**Khalifa SECK** - [GitHub](https://github.com/KhalifaSeck)

## Licence

MIT License
