

#' Store modification rules
#'
#' @keywords internal
setRefClass("modifier"
    , contains = "expressionset"
    , methods = list(
      show = function() show_modifier(.self)
      , initialize = function(..., .file) ini_modifier(.self, ..., .file=.file)
    ) 
)


show_modifier <- function(obj){
  cat(sprintf("Object of class %s with %d elements:\n",class(obj)[1],length(obj)))
  nm <- names(obj)
  lb <- label(obj)
  calls <- lapply(obj$rules,expr)
  
  for ( i in seq_along(calls)){
    cat(sprintf("%s: %s\n  %s\n\n",nm[i],lb[i],gsub("\n","\n  ",as.character(calls[i]))  ))
  }
  
}

call2text <- function(cl){
  capture.output(print(cl))
}


#' Create or read a set of data modification rules
#'
#'
#' @param ... A comma-separated list of modification rules.
#' @param .file A character vector of file locations.
#'
#' @return An object of class \code{modifier}.
#'
#' @examples 
#' m <- modifier( if (height < mean(height)) height <- 2*height
#' , if ( weight > mean(weight) ) weight <- weight/2  )
#' modify(women,m)
#' 
#' 
#' @export
modifier <- function(..., .file) new("modifier", ... , .file=.file)




ini_modifier <- function(obj ,..., .file){
  if ( missing(.file) ){
    validate::.ini_expressionset_cli(obj, ..., .prefix="M")
  } else {
    validate::.ini_expressionset_yml(obj, file=.file, .prefix="M")
  }
  
  i <- sapply(expr(obj),is_modifying)
  
  if ( !all(i) ){
    err <- paste(sprintf("\n[%03d] %s", which(!i), sapply(expr(obj)[!i], call2text )))
    warning(paste0(
      "Invalid syntax detected. The following expressions have been ignored:",
      paste(err,collapse="") 
      ))
  }
  if ( length(i) > 0 ){
    obj$rules <- obj$rules[i]
    obj$._options <- validate::.PKGOPT
    obj$._options(lin.eq.eps=0, lin.ineq.eps=0)
  }
  obj
}

# cl: a call.
is_modifying <- function(cl){
  # assignment or transient assignment (macro)
  if (deparse(cl[[1]]) %in% c("<-","=", ":=")) return(TRUE)
  
  # if statement. if-else currently not supported
  if ( cl[[1]] == "if" & length(cl) < 4 ) 
    return(all(sapply(cl[-c(1,2)],is_modifying)))
  
  # block
  if (cl[[1]]=="{") return(all(sapply(cl[-1],is_modifying)))
  
  
  FALSE
}

#### S4 GENERICS --------------------------------------------------------------


#' Modify a data set
#'
#' @param dat An R object carrying data
#' @param x An R object carrying modififying rules
#' @param ... Options.
#'
#' @export
setGeneric("modify", function(dat, x, ...) standardGeneric("modify"))


setGeneric("expr", function(x,...) standardGeneric("expr"))

#### S4 IMPLEMENTATIONS
setMethod("expr","modifier",function(x,...){
  lapply(x$rules, function(r) r@expr)
})







