sts_uni_list2str = function ( lst, exclude=c() ){
  str = ""
  for( i in seq(1,length(lst))){
    if (! names(lst)[i] %in% exclude ){
      key = names(lst)[i]
      value = lst[[i]]

      if( length( value ) == 1 ){
        str = paste0( str, key, "\t", value, "\n")
      }else if( is.null( attr( value, "names"))){
        str = paste0( str, key, "\t", paste( value , collapse=" ") , "\n")
      }else{
        str = paste0( str, key, "\n" )
        str = paste0( str, paste( mapply( paste0, "\t", names(value), "\t" , value), collapse="\n") , "\n")
      }
    }
  }
  return( str )
}


sts_uni_univariate = function( data , vars , hist = FALSE , ... ){
  if( (! is.character(vars)) || length(vars) == 0 ){
    stop("vars argument requires character vector")
  }
  check_name_existance = vars %in% colnames(data)
  if( ! all(check_name_existance) ){
    print( paste( check_name_existance , "\n") )
    stop("vars argument should be colnames of data")
  }

  results = list()
  df = data

  for( var in vars){
    result = list()
    result$vec = df[[ var ]]

    result$mean = mean( df[[ var ]] )
    result$N = length( df[[ var ]] )
    missing_pos = is.na(df[[ var ]])

    result$missing = sum( missing_pos )
    result$n = sum( ! missing_pos )

    non_missing = df[[ var ]][! missing_pos]

    quantiles = quantile(non_missing, probs = c(1, 0.99, 0.95, 0.90, 0.75, 0.5, 0.25, 0.1, 0.05, 0.01, 0), na.rm = TRUE)
    third_quart = quantiles[5]
    first_quart = quantiles[7]
    result$max = head(quantiles, 1)
    result$min = tail(quantiles, 1)

    result$mean = mean(non_missing)
    result$deviation = sd(non_missing)
    result$median = median(non_missing)
    result$IQR = c( first_quart ,third_quart )
    result$quantiles = quantiles

    # To be implemented
    # skewness 
    # kurtosis

    results[[var]] = result
  }

  result_str = ""
  result_num = length(results)
  for( i in seq(1, result_num)){
    result_str = paste0( result_str, names(results)[i], " ", "statistics\n")
    result_str = paste0( result_str, sts_uni_list2str(results[[i]], exclude=c("vec")), "\n")
  }

  # output
  if( hist ){
    layout( matrix(seq(1, result_num), ncol = 1))
    for( i in seq(1,result_num)){
      hist( results[[ i ]]$vec , main = paste( "Histogram of" , names(results)[i] ), xlab=names(results)[i] )
    }
    layout( matrix(c(1), ncol = 1))
  }

  cat( result_str )  # output is done using cat()
  return(results)  # return value to be used by other instructions is results
}


sts_uni_qqplot = function( results , var = NULL , qqline = FALSE, ... ){
  if ( (! is.null(var)) && (length(var) != 1) ){
    stop("main argument needs to be length of 1 character vector")
  }
  if( is.null(var) ){
    vec = results[[1]]$vec
  }else{
    vec = results[[var]]$vec
  }
  qqnorm(vec)
  if( qqline ){
    qqline(vec)
  }
}


