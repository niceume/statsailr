sts_plot_hist = function( data , var , ... ){
  if( (! is.character(var)) || length(var) != 1 ){
    stop("vars argument requires character vector with size of 1")
  }

  hist(data[[var]], main=paste( "Histogram of", var ), xlab=var, ... )
}

sts_plot_box = function( data , var , ... ){
  if( (! is.character(var)) || length(var) != 1 ){
    stop("vars argument requires character vector with size of 1")
  }

  boxplot(data[var] , ... )
}

sts_plot_scatter = function( data , vars , ... ){
  if( (! is.character(vars)) || length(vars) != 2 ){
    stop("vars argument requires character vector with size of 2")
  }

  plot(data[vars] , ... )
}

