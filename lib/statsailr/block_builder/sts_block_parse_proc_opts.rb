class STSBlockParseProcOpts

  def initialize(elems, idx)
    @size = elems.size
    @elems = elems
    @idx = idx
    @result_hash = Hash.new()
  end

  def has_next?()
    if @idx + 1 < @size
      return true
    else
      return false
    end
  end

  def next_token()
    if has_next?
      @idx = @idx + 1
      @elems[@idx]
    else
      nil
    end
  end

  def peek()
    if has_next?
      @elems[@idx + 1]
    else
      nil
    end
  end

  def current_token()
    @elems[@idx]
  end

# Entry point
  def parse()
    arg_opts()
    return @result_hash
  end

# The following grammar is parsed using recursive descent algorithm

# arg_opts : arg_opt
#          | arg_opts arg_opt
#
# arg_opt  : IDENT = primary
#          | IDENT = array
#          | IDENT = func 
#
# parimary : STRING
#          | NUM
#          | IDENT
#
# array    : [ elems ]
#
# func     : IDENT ( elems )
#
# elems    : primary
#          | elems , primary
#
#

  def arg_opts()
    arg_opt()
    if has_next?
      next_token()
      arg_opts()
    end
  end

  def arg_opt()
    opt_key = ident()
    if (!peek.nil?) && peek.type == :sign && peek.e1 == "="
      next_token()  # At = 
      if peek.type == :sign && peek.e1 == "[" # RHS of = is array
        next_token() # Now at [
        opt_value = array()
      elsif peek.type == :ident # RHS of = is ident, meaning just ident or function 
        next_token()
        if (! peek.nil?) && peek.type == :sign && peek.e1 == "("
          opt_value = func()
        else
          opt_value = ident() # According to BNF, this should be parimary(). However, ident() is more direct and makes sense here.
        end
      elsif [:string, :num].include? peek.type
         next_token()
         opt_value = primary()
      else
        p current_token()
        raise "the token should be :ident or primaries such as :ident, :num and :string after = . Current token: " + current_token().type.to_s
      end
    else
      raise "proc instruction optional argumeents should be in the form of a sequence of 'key = value'"
    end
    @result_hash[opt_key.to_s] = opt_value
  end

  def array()
    raise "array should start with [ " if ! (current_token.type == :sign && current_token.e1 == "[")

    next_token()
    ary = Array.new()
    elems( ary )

    raise "array should end with ] " if ! (current_token.type == :sign && current_token.e1 == "]")

    return ary
  end

  def elems( ary )
    ary.push primary()
    next_token
    if current_token.type == :sign && current_token.e1 == ","
      next_token
      elems( ary )
    else
      return ary
    end
  end

  def primary()
    case current_token.type
    when :ident
      return ident()
    when :string
      return string()
    when :num
      return num()
    else
      raise "the current token should be :ident, :string or :num."
    end
  end

  def func()
    func_name = ident()
    parenthesis = next_token()
    raise "func arg should start with ( " if ! (parenthesis.type == :sign && parenthesis.e1 == "(")

    next_token()
    func_args = elems( Array.new() )
    raise "func should end with ) " if ! (current_token.type == :sign && current_token.e1 == ")")

    func_hash = {"type" => :func , "fname" => func_name.to_s , "fargs" => func_args}
    return func_hash
  end

  def ident()
    raise "the current token should be ident" if current_token.type != :ident 
    return type_adjust( current_token.e1, :ident)
  end

  def string()
    raise "the current token should be string" if current_token.type != :string 
    return type_adjust( current_token.e1, :string)
  end

  def num()
    raise "the current token should be num" if current_token.type != :num
    return type_adjust( current_token.e1, :num)
  end
end


