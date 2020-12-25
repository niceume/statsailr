convert_to_factor = function( data, vars ){
  data[vars] = lapply(data[vars], as.factor)
  print( paste( "as.factor is applied to", paste( vars, collapse=",") , sep=" ") )
  return( data )
}
