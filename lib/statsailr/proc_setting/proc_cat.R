sts_cat_table = function( data , vars , missing = FALSE, ... ){
  if( (! is.character(vars)) || length(vars) != 2 ){
    stop("vars argument requires character vector with size of 2")
  }

  df_for_table = data[ , vars ]
  if( missing ){
    freq_ori = table(df_for_table, useNA = "ifany")
  }else{
    freq_ori = table(df_for_table)
  }

  freq = addmargins( freq_ori )
  allper = format( addmargins( prop.table( freq_ori) * 100), digits = 4)
  rowper = format( addmargins( prop.table( freq_ori, 1) * 100), digits = 4)
  colper = format( addmargins( prop.table( freq_ori, 2) * 100), digits = 4)

  nrow = nrow(freq)
  ncol = ncol(freq)
  nrow_ori = nrow(freq_ori)

  temp = as.array( numeric( nrow * ncol * 4 ))
  dim( temp ) = c( nrow * 4, ncol )
  result = as.table( temp )

  colnames(result) = c( colnames( freq_ori ) , "Total")

  row_label1 = c( rep("%",nrow_ori ) , "%")
  row_label2 = c( rep("Row%",nrow_ori ) , "")
  row_label3 = c( rep("Col%",nrow_ori ) , "")

  rownames(result) = as.vector( mapply( c, c( rownames( freq_ori ), "Total" ), row_label1 , row_label2 , row_label3 ))

  cat( paste( "\t", names(freq), "\n", sep = "\t", collapse = "\t" ))
  for( irow in seq(1, nrow) ){
    for( icol in seq(1, ncol) ){
      result[ (irow-1)*4 + 1, icol] = freq[irow, icol]
    }
    for( icol in seq(1, ncol) ){
      result[ (irow-1)*4 + 2, icol] = allper[irow, icol]
    }
    for( icol in seq(1, ncol) ){
      if(irow != nrow && icol != ncol){
        result[ (irow-1)*4 + 3, icol] = rowper[irow, icol]
      }else{
        result[ (irow-1)*4 + 3, icol] = NA
      }
    }
    for( icol in seq(1, ncol) ){
      if(icol != ncol && irow!= nrow){
        result[ (irow-1)*4 + 4, icol] = colper[irow, icol]
      }else{
        result[ (irow-1)*4 + 4, icol] = NA
      }
    }
  }
 
  cat( paste( vars[1] , " vs ", vars[2], "\n" ) )
  print( result )

  return( freq_ori )
}

