#' @title Gaussian Process Regression Learner
#' @name mlr_learners_regr.gpfit
#'
#' @description
#' Gaussian Process regression using the GPfit package.
#' Calls [GPfit::GP_fit()] for training and predict method for predictions.
#' Features are automatically scaled to the unit hypercube as required by GPfit.
#'
#' @section Parameters:
#' * `corr_type` (`character(1)`)\cr
#'   Correlation function type: "exponential" (default) or "matern".
#' * `corr_power` (`numeric(1)`)\cr
#'   Power parameter for exponential correlation. Default: 1.95.
#' * `corr_nu` (`numeric(1)`)\cr
#'   Smoothness parameter for Matern correlation. Default: 2.5.
#'
#' @references
#' MacDonald, B., Ranjan, P., Chipman, H. (2015).
#' "GPfit: An R Package for Fitting a Gaussian Process Model to Deterministic Simulator Outputs."
#' Journal of Statistical Software, 64(12), 1-23.
#'
#' @export
#' @examples
#' library(mlr3)
#' 
#' # Create a regression task
#' task = tsk("mtcars")
#'
#' # Create the learner with default parameters
#' learner = lrn("regr.gpfit")
#' learner$train(task)
#' learner$predict(task)
#' 
#' # Use Matern correlation
#' learner2 = lrn("regr.gpfit")
#' learner2$param_set$values = list(corr_type = "matern", corr_nu = 1.5)
#' learner2$train(task)
LearnerRegrGPfit = R6::R6Class("LearnerRegrGPfit",
  inherit = mlr3::LearnerRegr,
  
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      # Define hyperparameters
      ps = paradox::ps(
        corr_type = paradox::p_fct(
          levels = c("exponential", "matern"),
          default = "exponential",
          tags = "train"
        ),
        corr_power = paradox::p_dbl(
          lower = 1, upper = 2,
          default = 1.95,
          tags = "train"
        ),
        corr_nu = paradox::p_dbl(
          lower = 0.5, upper = Inf,
          default = 2.5,
          tags = "train"
        )
      )
      
      super$initialize(
        id = "regr.gpfit",
        packages = "GPfit",
        feature_types = c("numeric", "integer"),
        predict_types = "response",
        param_set = ps,
        properties = character(0),
        label = "Gaussian Process Regression",
        man = "mlr3learners.gpfit::mlr_learners_regr.gpfit"
      )
    }
  ),
  
  private = list(
    # Stockage des paramètres de normalisation
    .x_min = NULL,
    .x_max = NULL,
    
    .train = function(task) {
      # Get training data
      data = task$data()
      X = as.matrix(data[, task$feature_names, with = FALSE])
      Y = data[[task$target_names]]
      
      # Normaliser X vers [0,1] (requis par GPfit)
      private$.x_min = apply(X, 2, min)
      private$.x_max = apply(X, 2, max)
      
      X_scaled = sweep(X, 2, private$.x_min, "-")
      X_scaled = sweep(X_scaled, 2, private$.x_max - private$.x_min, "/")
      
      # Gérer les features constantes
      constant_features = private$.x_max == private$.x_min
      if (any(constant_features)) {
        X_scaled[, constant_features] = 0.5
      }
      
      # Get hyperparameters avec valeurs par défaut EXPLICITES
      pv = self$param_set$get_values(tags = "train")
      
      # Valeurs par défaut si non spécifiées
      corr_type = if (is.null(pv$corr_type)) "exponential" else pv$corr_type
      corr_power = if (is.null(pv$corr_power)) 1.95 else pv$corr_power
      corr_nu = if (is.null(pv$corr_nu)) 2.5 else pv$corr_nu
      
      # Build corr argument for GPfit
      corr = list(type = corr_type)
      
      if (corr_type == "exponential") {
        corr$power = corr_power
      } else if (corr_type == "matern") {
        corr$nu = corr_nu
      }
      
      # Train GP model using GPfit::GP_fit()
      GPfit::GP_fit(X = X_scaled, Y = Y, corr = corr)
    },
    
    .predict = function(task) {
      # Get test data
      newdata = as.matrix(task$data(cols = task$feature_names))
      
      # Normaliser avec les paramètres de train
      newdata_scaled = sweep(newdata, 2, private$.x_min, "-")
      newdata_scaled = sweep(newdata_scaled, 2, private$.x_max - private$.x_min, "/")
      
      # Gérer les features constantes
      constant_features = private$.x_max == private$.x_min
      if (any(constant_features)) {
        newdata_scaled[, constant_features] = 0.5
      }
      
      # Make predictions using predict()
      pred = predict(object = self$model, xnew = newdata_scaled)
      
      # Return mlr3 PredictionRegr object
      mlr3::PredictionRegr$new(
        task = task,
        response = as.numeric(pred$Y_hat)
      )
    }
  )
)

