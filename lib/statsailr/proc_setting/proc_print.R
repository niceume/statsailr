sts_print_nth = function( x , positions ){

# positions are passed as strvec which is already splitted by spaces and signs
# group these elements

shift_vec = function( x, n , fill=NA ){
  if( n == 0 ){
    return( x )
  }else if( n > 0 ){
    return( c( rep(fill, n), head(x, -n)) )
  }else if( n < 0 ){
    return( c( tail(x, length(x) + n), rep(fill, -n)) )
  }else{
    print("inappropriate n.")
    return(x)
  }
}

colon_pos = (positions == ":")
colon_after_pos = shift_vec( colon_pos , 1, F )
group_num = cumsum( !( colon_pos | colon_after_pos) )

position_strvec = sapply( split(positions, group_num) , function(elem){ paste( elem, collapse="" )} )
names( position_strvec) = position_strvecp

# Convert them to a list of int vectors

position_list = lapply(position_strvec, function(elem){
  range_sep = ":"
  if( grepl( range_sep, elem, fixed = TRUE) ){ # grepl(pattern, x)
    range = strsplit(elem, range_sep, fixed=TRUE)[[1]]
    if( length(range) != 2){
      print("Range should be specified with x:y form (meaning from x to y).")
      return( 0 )
    }else{
      range_int = strtoi(range)
      return( seq(range_int[1], range_int[2]) )
    }
  }else{
    return( strtoi(elem))
  }
})

# For each int vector, print corresponding rows

lapply( position_list, function(nth){
  x[ nth , ]
})

}

sts_print_random = function( x , n  ){
  row_num = nrow(x)
  index = ceiling(row_num * runif(n))
  sorted_index = sort(index)
  x[ sorted_index , ]
}

