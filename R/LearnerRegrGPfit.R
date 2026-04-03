#' @title Gaussian Process Regression Learner
#' @name mlr_learners_regr.gpfit
#'
#' @description
#' Gaussian Process regression using the GPfit package.
#' Calls [GPfit::GP_fit()] for training and predict method for predictions.
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
#' # Create the learner
#' learner = lrn("regr.gpfit")
#'
#' # Train the model
#' learner$train(task)
#'
#' # Make predictions
#' prediction = learner$predict(task)
#' print(prediction)
LearnerRegrGPfit = R6::R6Class("LearnerRegrGPfit",
  inherit = mlr3::LearnerRegr,
  
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "regr.gpfit",
        packages = "GPfit",
        feature_types = c("numeric", "integer"),
        predict_types = "response",
        properties = character(0),
        label = "Gaussian Process Regression",
        man = "mlr3learners.gpfit::mlr_learners_regr.gpfit"
      )
    }
  ),
  
  private = list(
    .train = function(task) {
      # Get training data
      data = task$data()
      X = as.matrix(data[, task$feature_names, with = FALSE])
      Y = data[[task$target_names]]
      
      # Train GP model using GPfit::GP_fit()
      GPfit::GP_fit(X = X, Y = Y)
    },
    
    .predict = function(task) {
      # Get test data
      newdata = as.matrix(task$data(cols = task$feature_names))
      
      # Make predictions using predict()
      pred = predict(object = self$model, xnew = newdata)
      
      # Return mlr3 PredictionRegr object
      mlr3::PredictionRegr$new(
        task = task,
        response = as.numeric(pred$Y_hat)
      )
    }
  )
)