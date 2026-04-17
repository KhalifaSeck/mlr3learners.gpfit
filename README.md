# mlr3learners.gpfit

<!-- badges: start -->
[![R-CMD-check](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/check.yaml/badge.svg)](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/check.yaml)
[![test-coverage](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/test-coverage.yaml)
[![codecov](https://codecov.io/github/KhalifaSeck/mlr3learners.gpfit/graph/badge.svg?token=PH1D4HEWA6)](https://codecov.io/github/KhalifaSeck/mlr3learners.gpfit)
[![pkgdown](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions/workflows/pkgdown.yaml)
[![Netlify](https://img.shields.io/netlify/YOUR-SITE-ID)](https://mlr3learners-gpfit.netlify.app)
<!-- badges: end -->

This R package provides an interface to the [GPfit](https://CRAN.R-project.org/package=GPfit) package for the [mlr3](https://mlr3.mlr-org.com/) ecosystem. It implements Gaussian Process regression with automatic feature scaling and tunable hyperparameters.

**Note**: This package implements **GPfit** (pure R) instead of **GPyTorch** (Python) as suggested in [issue #487](https://github.com/mlr-org/mlr3extralearners/issues/487). GPfit was chosen to avoid Python dependencies (reticulate) and provide a pure R implementation that is easier to maintain and deploy.

## Documentation

The site can be found at: **https://mlr3learners-gpfit.netlify.app/**

This site includes API references, usage guides and detailed performance benchmarks.

## Installation

To install it, you can use this command:

```r
# install.packages("remotes")
remotes::install_github("KhalifaSeck/mlr3learners.gpfit")
```

## Usage

This package provides the `regr.gpfit` learner for mlr3. Features are automatically scaled to [0,1] as required by GPfit.

### Basic example

```r
library(mlr3)
library(mlr3learners.gpfit)

# Create regression task (exclude factor columns)
iris_numeric = iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")]
task = as_task_regr(iris_numeric, target = "Sepal.Length", id = "iris_sepal")

# Create and train learner
learner = lrn("regr.gpfit")
learner$train(task)

# Make predictions
prediction = learner$predict(task)
prediction$score(msr("regr.mse"))
```

### Tunable hyperparameters

```r
# Matérn correlation with custom smoothness
learner = lrn("regr.gpfit")
learner$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
learner$train(task)

# Exponential correlation with custom power
learner = lrn("regr.gpfit")
learner$param_set$values = list(corr_type = "exponential", corr_power = 1.8)
learner$train(task)
```

**Available hyperparameters:**
- `corr_type`: Correlation function type ("exponential" or "matern")
- `corr_power`: Power parameter for exponential correlation (default: 1.95)
- `corr_nu`: Smoothness parameter for Matérn correlation (default: 2.5)

## Benchmark results

Performance was evaluated using Mean Squared Error (MSE). Results are based on 5-fold cross-validation.

| Dataset | GPfit | CV-Glmnet | KNN (Tuned) | Featureless |
|---------|-------|-----------|-------------|-------------|
| iris_sepal | **0.1002** | 0.1103 | 0.1311 | 0.6850 |
| iris_petal | **0.0696** | 0.1194 | 0.1075 | 3.1047 |

**Note**: Lower values indicate better performance. **Bold values** represent the best learner for each task.

### Analysis

**Does GPfit learn non-trivial patterns?**
- **iris_sepal**: 85.38% improvement over baseline
- **iris_petal**: 97.76% improvement over baseline

 **YES, GPfit learns non-trivial patterns**

**Is GPfit competitive with other algorithms?**
- **iris_sepal**: GPfit ranks **#1 out of 4** algorithms
- **iris_petal**: GPfit ranks **#1 out of 4** algorithms

 **GPfit achieves the best performance on both datasets**

The complete benchmark analysis is available in the `benchmark.R` file.

## Feature scaling validation

Automatic feature scaling to [0,1] is correctly applied during both training and prediction. The learner stores scaling parameters (.x_min, .x_max) during training and reuses them for consistent normalization at prediction time.

### Validation results (70% train / 30% test split)

**iris_sepal:**

| Configuration | MSE Train | MSE Test | Improvement |
|---------------|-----------|----------|-------------|
| Default (exponential, power=1.95) | 0.0886 | 0.0902 | 82.2% |
| Matérn (nu=1.5) | 0.0940 | 0.0860 | 83.0% |
| Baseline (featureless) | 0.7564 | 0.5056 | - |

**iris_petal:**

| Configuration | MSE Train | MSE Test | Improvement |
|---------------|-----------|----------|-------------|
| Default (exponential, power=1.95) | 0.0533 | 0.0826 | 97.8% |
| Matérn (nu=1.5) | 0.0574 | 0.0846 | 97.8% |
| Exponential (power=1.8) | 0.0504 | 0.0819 | 97.8% |
| Baseline (featureless) | 2.7962 | 3.7950 | - |

**Key observations:**
- MSE Train < MSE Test → Proper scaling and no overfitting
- MSE Test << MSE Baseline → Excellent generalization
- Improvement > 80% on both datasets
- Hyperparameters allow fine-tuning of performance

## Technical features

- **Automatic feature scaling**: Features are automatically normalized to [0,1] as required by GPfit
- **Numerical stability**: GPfit uses a 'nugget' parameter for stability (MSE Train ≠ 0, which prevents overfitting)
- **Tunable hyperparameters**: Choice between exponential and Matérn correlation with adjustable parameters

## Development

This package includes:

- **9 unit tests** (100% passing)
- **Complete validation** of prediction quality
- **Comparative benchmark** with 3 other algorithms
- **Continuous integration** via GitHub Actions
- **Code coverage** tracked via Codecov
- **Documentation website** deployed on Netlify
- **Automatic feature scaling** with validation
- **Tunable hyperparameters** (corr_type, corr_power, corr_nu)

## Related work

- **Course wiki**: https://github.com/tdhock/2026-01-aa-grande-echelle/wiki/projets
- **GPfit (CRAN)**: https://CRAN.R-project.org/package=GPfit - Core package for Gaussian Process regression
- **Issue mlr3extralearners #487**: https://github.com/mlr-org/mlr3extralearners/issues/487 (GPyTorch → GPfit)
- **mlr3 book**: https://mlr3book.mlr-org.com/

## Author

**Khalifa SECK** - [GitHub](https://github.com/KhalifaSeck)

## Licence

MIT License