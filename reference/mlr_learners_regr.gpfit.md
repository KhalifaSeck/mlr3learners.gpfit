# Gaussian Process Regression Learner

Gaussian Process regression using the GPfit package. Calls
[`GPfit::GP_fit()`](https://rdrr.io/pkg/GPfit/man/GP_fit.html) for
training and predict method for predictions. Features are automatically
scaled to the unit hypercube as required by GPfit.

## Parameters

- `corr_type` (`character(1)`)  
  Correlation function type: "exponential" (default) or "matern".

- `corr_power` (`numeric(1)`)  
  Power parameter for exponential correlation. Default: 1.95.

- `corr_nu` (`numeric(1)`)  
  Smoothness parameter for Matern correlation. Default: 2.5.

## References

MacDonald, B., Ranjan, P., Chipman, H. (2015). "GPfit: An R Package for
Fitting a Gaussian Process Model to Deterministic Simulator Outputs."
Journal of Statistical Software, 64(12), 1-23.

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`mlr3::LearnerRegr`](https://mlr3.mlr-org.com/reference/LearnerRegr.html)
-\> `LearnerRegrGPfit`

## Methods

### Public methods

- [`LearnerRegrGPfit$new()`](#method-LearnerRegrGPfit-new)

- [`LearnerRegrGPfit$clone()`](#method-LearnerRegrGPfit-clone)

Inherited methods

- [`mlr3::Learner$base_learner()`](https://mlr3.mlr-org.com/reference/Learner.html#method-base_learner)
- [`mlr3::Learner$configure()`](https://mlr3.mlr-org.com/reference/Learner.html#method-configure)
- [`mlr3::Learner$encapsulate()`](https://mlr3.mlr-org.com/reference/Learner.html#method-encapsulate)
- [`mlr3::Learner$format()`](https://mlr3.mlr-org.com/reference/Learner.html#method-format)
- [`mlr3::Learner$help()`](https://mlr3.mlr-org.com/reference/Learner.html#method-help)
- [`mlr3::Learner$predict()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict)
- [`mlr3::Learner$predict_newdata()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict_newdata)
- [`mlr3::Learner$print()`](https://mlr3.mlr-org.com/reference/Learner.html#method-print)
- [`mlr3::Learner$reset()`](https://mlr3.mlr-org.com/reference/Learner.html#method-reset)
- [`mlr3::Learner$selected_features()`](https://mlr3.mlr-org.com/reference/Learner.html#method-selected_features)
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)
- [`mlr3::LearnerRegr$predict_newdata_fast()`](https://mlr3.mlr-org.com/reference/LearnerRegr.html#method-predict_newdata_fast)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerRegrGPfit$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerRegrGPfit$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)

# Create a regression task
task = tsk("mtcars")

# Create the learner with default parameters
learner = lrn("regr.gpfit")
learner$train(task)
learner$predict(task)
#> 
#> ── <PredictionRegr> for 32 observations: ───────────────────────────────────────
#>  row_ids truth response
#>        1  21.0     21.0
#>        2  21.0     21.0
#>        3  22.8     22.8
#>      ---   ---      ---
#>       30  19.7     19.7
#>       31  15.0     15.0
#>       32  21.4     21.4

# Use Matern correlation
learner2 = lrn("regr.gpfit")
learner2$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
learner2$train(task)
```
