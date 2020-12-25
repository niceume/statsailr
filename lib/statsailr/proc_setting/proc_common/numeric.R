convert_to_numeric = function( data, vars ){
  data[vars] = lapply(data[vars], as.numeric)
  print( paste( "as.numeric is applied to", paste( vars, collapse=",") , sep=" ") )
  return( data )
}
