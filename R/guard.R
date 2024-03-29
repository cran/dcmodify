

# conjucate two expressions
`%&%` <- function(e,f){
  if (is.null(e)) return(f)
  if (is.null(f)) return(e)
  bquote(.(e) & .(f))
}

# negate a expression
not <- function(e){
  if (is.call(e) && e[[1]] == "!"){
    return(e[[2]])
  }
  bquote(!.(e))
}

na_allowed <- function(e){
  # straight forward but less efficient would be
  #e_na <- bquote(.(e) | is.na(.(e)))
  
  e_na <- bquote((.i <- (.(e))) | is.na(.i))
  attributes(e_na) <- attributes(e)
  e_na
}

# get guard attribute
guard <- function(x){
  attr(x,"guard")
}

# condition <- function(x){
#   x[[2]]
# }

# calls of the form 
# if (<condition>){
#   <calls1>
# } else {
#   <calls2>
# }
# are translated to a list where each element is a call from {<calls1>, <calls2>}. 
# The elements of the list have a 'guard' attribute, which is a logical expression 
# indicating under which condition a call should be evaluated.
#
set_guards <- function(x, dplyr_verbs = FALSE){
  expr <- x
  
  if ( is_block(expr) ){
    v <- lapply(expr[-1], identity)
    attr(v[[1]],'guard') <- guard(x)
#    v <- lapply(expr[-1], function(ex){
#      attr(ex,'guard') <- guard(x)
#      ex
#    })
    return(unlist(lapply(v,set_guards, dplyr_verbs=dplyr_verbs)))
  }
  
  if(is_if(expr)){
    
    cond <- expr[[2]]
    if (is.null(cond) || (is.logical(cond) && is.na(cond))){
      stop("Invalid condition, no NULL or NA: '", deparse(expr), "'", call. = FALSE)
    }
    v <- expr[[3]] # expression
    
    attr(v,'guard') <- guard(x) %&% cond
    
    v <- list(v)
    
    if (length(expr)==4){ # there is an 'else'
      w <- expr[[4]]
      attr(w,'guard') <- guard(x) %&% not(cond)
      v <- c(v,w)
    }
    return(unlist(lapply(v,set_guards, dplyr_verbs=dplyr_verbs)))
  } 
  
  if (is_assignment(expr)){
    
    # remove "{" from single statements
    expr[[3]] <- unwrap(expr[[3]])
    
    value <- expr[[3]]
                  
    # rewrite case_when or ifelse into if statement...
    # make this optional, 
    if (isTRUE(dplyr_verbs)){
      if (is_case_when(value)){
        value <- case_when_into_if(value)
      } else if (is_ifelse(value)){
        value <- ifelse_into_if(value)
      }
    }

    if (is_if(value)){
      # this supports z <- if (x > 0) 1 else 3 syntax
      ifexpr <- value
      # persist assignment operator (i.e. "<-", ":=", "=")
      v <- substitute( a %op% b
                     , list( a      = expr[[2]]
                           , "%op%" = expr[[1]]
                           , b      = unwrap(ifexpr[[3]])
                           )
                     )
      attr(v,"guard") <- guard(x) %&% ifexpr[[2]]
      v <- list(v)
      
      if (length(ifexpr) == 4){
        v_else <- substitute( a %op% b
                            , list( a      = expr[[2]]
                                  , "%op%" = expr[[1]]
                                  , b      = unwrap(ifexpr[[4]])
                                  )
                            )
        attr(v_else, "guard") <- guard(x) %&% not(ifexpr[[2]])
        v <- c(v, v_else)
      return(unlist(lapply(v, set_guards, dplyr_verbs=dplyr_verbs)))
      }
    }
  }
  return(list(expr))
}

is_block <- function(e){
  is.call(e) && e[[1]] == "{"
}

# unwrap single statements, should not affect real block assignments...
# TODO also for "(" ?
unwrap <- function(e){
  while(is_block(e) && length(e) == 2){
    e <- e[[2]]
  }
  e
}

is_if <- function(e){
  is.call(e) && e[[1]] == "if"
}

is_assignment <- function(e){
  is.call(e) && as.character(e[[1]]) %in% c("<-", "=", ":=")
}

is_extract <- function(e){
  
}


is_ifelse <- function(e){
  is.call(e) && as.character(e[[1]]) %in% c("ifelse", "if_else")
}

ifelse_into_if <- function(e){
  if (!is_ifelse(e)){
    return(e)
  }
  cond <- e[[2]]
  e_true <- e[[3]]
  e_false <- e[[4]]
  # missing? (todo)
  bquote(if (.(cond)) .(e_true) else .(e_false))
}

