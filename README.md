# mlr3learners.gpfit

<!-- badges: start -->
[![R-CMD-check](https://github.com/KhalifaSeck/mlr3learners.gpfit/workflows/R-CMD-check/badge.svg)](https://github.com/KhalifaSeck/mlr3learners.gpfit/actions)
<!-- badges: end -->

Gaussian Process regression learner for [mlr3](https://mlr3.mlr-org.com/) using the [GPfit](https://CRAN.R-project.org/package=GPfit) package.

## Installation

Install from GitHub:
```r
# install.packages("remotes")
remotes::install_github("KhalifaSeck/mlr3learners.gpfit")
```

## Usage
```r
library(mlr3)
library(mlr3learners.gpfit)

# Create a regression task
task = tsk("mtcars")

# Create the GP learner
learner = lrn("regr.gpfit")

# Train the model
learner$train(task)

# Make predictions
prediction = learner$predict(task)
print(prediction)

# Evaluate performance
prediction$score(msr("regr.mse"))
```

## Related work

- **Course wiki**: https://github.com/tdhock/2026-01-aa-grande-echelle/wiki/projets
- **GPfit package**: https://CRAN.R-project.org/package=GPfit
- **mlr3extralearners issue #487**: https://github.com/mlr-org/mlr3extralearners/issues/487