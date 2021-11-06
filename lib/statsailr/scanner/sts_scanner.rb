require "strscan"

module STSConstants
IDENT_PATTERN = /[a-zA-Z\-_.][0-9a-zA-Z\-_.]*/
PROC_INST_PATTERN = /[a-zA-Z\-_.][0-9a-zA-Z\-_.]*/
FLOATP_PATTERN = /[-+]?(([1-9][0-9]*)|0)\.[0-9]*/
INT_PATTERN = /[-+]?([1-9][0-9]*)|0/
SQ_STR_PATTERN = /'(\\'|[^'\n])*'/
DQ_STR_PATTERN = /"(\\"|[^"\n])*"/
end

module STSScannerSupport
  def interpret_escape_sequences(str)
    # This deals with escape sequences in double quoted string literals
    # The behavior should be same as libsailr (or datasailr)
    new_str = ""
    str_array = str.split(//)
    idx = 0
    while( idx < str_array.size) do
      c = str_array[idx]
      if(c == "\\")
        idx = idx + 1
        c = str_array[idx]
        raise "Tokenizer error: double quoted string literal should never end with \\" if idx >= str_array.size
        case c
        when 't'
          new_str << "\t"
        when 'n'
          new_str << "\n"
        when 'r'
          new_str << "\r"
        when "\\"
          new_str << "\\"
        when "\'"
          new_str << "\'"
        when "\""
          new_str << "\""
        when '?'
          new_str << '?'
        else
          new_str << c
        end
      else
        new_str << c
      end
      idx = idx + 1
    end
    return new_str
  end
end

class STSScanner
  include ::STSConstants
  include ::STSScannerSupport

  # Initialization & Terminating methods

  def initialize( script )
    @script = script
  end

  def start()
    @scanner = StringScanner.new(@script)
    @scan_state = :TOP
  end

  def terminate()
    @scanner.terminate()
  end

  # Delegate corresponding methods to StringScanner

  def scan(pattern)
    @scanner.scan(pattern)
  end

  def scan_until(pattern)
    @scanner.scan_until(pattern)
  end

  def skip_until(pattern)
    @scanner.skip_until(pattern)
  end

  def matched()
    @scanner.matched
  end

  def eos?()
    @scanner.eos?
  end

  def bol?()
    @scanner.bol?
  end

  def check(pattern)
    @scanner.check(pattern)
  end

  # Additional scanner methods

  def skip_spaces()
    scan(/[ \t]*/)
  end

  def skip_line()
    scan_until(/\n/)
  end

  def skip_rest_after_comment_sign()
    if scan(/[ \t]*(\/\/).*\n/)  # line after //
      return true
    else
      return false
    end
  end

  def skip_empty_line()
    if scan(/[ \t]*\n/)  # Empty line
      return true
    else
      return false
    end
  end

  def skip_multiple_line_comment()
    if scan(/\s*\/\*(.|\n)+?\*\//)
      return true
    else
      return false
    end
  end

  def scan_ident()
    scan(IDENT_PATTERN)
  end

  def tokenize_options()
    tokens = []
    while 1 do
      case
      when eos? || scan(/\n/)
        break
      when scan(/=/)
        tokens << [:ASSIGN, matched ]
      when scan(IDENT_PATTERN)
        tokens << [:IDENT, matched ]
      when scan(FLOATP_PATTERN)
        tokens << [:NUMBER, matched.to_f ]
      when scan(INT_PATTERN)
        tokens << [:NUMBER, matched.to_i ]
      when scan(SQ_STR_PATTERN)
        tokens << [:STRING, matched[Range.new(1, -2)] ]
      when scan(DQ_STR_PATTERN)
        tokens << [:STRING, interpret_escape_sequences(matched[Range.new(1, -2)]) ]
      when scan(/[ \t]/)
        #ignore
      else
        raise "options cannot be tokenized."
      end
    end
    return tokens
  end

  def scan_whole_line()
    scan(/.*\n/)
  end

  def scan_end_line?()
    if( scan(/[ \t]*E[Nn][Dd][ \t]*/))
      if scan(/\S+/)
        puts "Script after END is ignored (" + matched + ")"
      end
      scan_until(/\n/) # Move to the end of line
      return true
    else
      return false
    end
  end

  # Additional features for TOPLEVEL

  def scan_toplevel_instruction
    inst = Regexp.new( /\s*/.source() + IDENT_PATTERN.source() )
    scan( inst )
  end

  # Additional features for data script

  def prepare_data_script()
    @data_script = ""
  end

  def append_to_data_script( script )
    @data_script << script
  end

  def get_data_script()
    return @data_script
  end

  # Additional features for proc stmts

  def prepare_proc_tokens()
    @proc_tokens = []
  end

  def get_proc_tokens()
    return @proc_tokens
  end

  def append_to_proc_tokens( tokens )
    @proc_tokens.concat tokens
  end

  def scan_proc_inst()
    skip_spaces()
    scan(PROC_INST_PATTERN)
  end

  def scan_proc_special()
    case
    when scan(/\=/)
      return :P_EQ
    when scan(/\*/)
      return :P_MULT
    when scan(/\+/)
      return :P_PLUS
    when scan(/\-/)
      return :P_MINUS
    when scan(/\^/)
      return :P_HAT
    when scan(/\%in\%/)
      return :P_IN
    when scan(/\%in\%/)
      return :P_PERC
    when scan(/\~/)
      return :P_TILDA
    when scan(/\:/)
      return :P_COLON
    when scan(/\(/)
      return :P_LPAR
    when scan(/\)/)
      return :P_RPAR
    when scan(/\[/)
      return :P_LSQBR
    when scan(/\]/)
      return :P_RSQBR
    when scan(/\,/)
      return :P_COMMA
    end
  end

  def tokenize_proc_line()
    tokens = []
    while 1 do
      case
      when eos? || scan(/\n/)
        break
      when scan(IDENT_PATTERN)
        tokens << [:IDENT, matched ]
      when scan(FLOATP_PATTERN)
        tokens << [:NUMBER, matched.to_f ]
      when scan(INT_PATTERN)
        tokens << [:NUMBER, matched.to_i ]
      when scan(SQ_STR_PATTERN)
        tokens << [:STRING, matched[Range.new(1, -2)] ]
      when scan(DQ_STR_PATTERN)
        tokens << [:STRING, interpret_escape_sequences(matched[Range.new(1, -2)]) ]
      when type = scan_proc_special()
        tokens << [ type , matched ]
      when scan(/[ \t]/)  # Separators
        #ignore
      when scan(/\/\//)  # Start comment
        @scanner.unscan
        break
      when scan(/\/\*/)  # Start comment
        @scanner.unscan
        break
      when scan(/\//)  # slash to start options
        tokens << [:P_SLASH, matched]
      else
        scan(/.*\n/)
        raise "Current PROC line cannot be tokenized." + matched
      end
    end
    return tokens
  end

  # Manage scan states

  def scan_state_top?()
    if @scan_state == :TOP
      return true
    else
      return false
    end
  end

  def scan_state_data?()
    if @scan_state == :DATA
      return true
    else
      return false
    end
  end

  def scan_state_proc?()
    if @scan_state == :PROC
      return true
    else
      return false
    end
  end

  def scan_state_set_top()
    @scan_state = :TOP
  end

  def scan_state_set_data()
    @scan_state = :DATA
  end

  def scan_state_set_proc()
    @scan_state = :PROC
  end

  def get_scan_state()
    return @scan_state
  end
end

class STSScanDriver
  def initialize( path )
    @source_path = path
  end

  def tokenize
    s = STSScanner.new(@source_path)
    s.start()
    @tokens = []

while ! s.eos? do
  case
  when s.scan_state_top?
    case
    when s.bol? && s.scan(/[ \t]*D[Aa][Tt][Aa]/)
      @tokens << [:DATA_START, "DATA" ]
      s.skip_spaces()
      if s.scan(/\:/)
        @tokens << [:COLON, s.matched]
        s.skip_spaces
        s.scan_ident()
        @tokens << [:IDENT, s.matched]
        s.skip_spaces()
      end
      s.scan_ident()
      @tokens << [:IDENT, s.matched]
      s.skip_spaces()
      @tokens.concat s.tokenize_options()
      @tokens << [:TERMIN, "\n"]
      s.scan_state_set_data()
      s.prepare_data_script()
    when s.bol? && s.scan(/[ \t]*P[Rr][Oo][Cc]/)
      @tokens << [:PROC_START, "PROC" ]
      s.skip_spaces()
      s.scan_ident()
      @tokens << [:IDENT, s.matched]
      s.skip_spaces()
      @tokens.concat s.tokenize_options()
      @tokens << [:TERMIN, "\n"]
      s.scan_state_set_proc()
      s.prepare_proc_tokens()
    else
      if s.skip_rest_after_comment_sign()
      elsif s.skip_empty_line()
      elsif s.skip_multiple_line_comment()
      elsif s.scan_toplevel_instruction
        @tokens << [:TOP_INST, s.matched() ]
        @tokens.concat s.tokenize_options()
        @tokens << [:TOP_INST_END, "TOP_INST_END"]
        @tokens << [:TERMIN, "\n"]
      else
        print("Unknown part on TOP LEVEL(" + s.get_scan_state.to_s + ")  " )
        p s.check(/...../) # Show five letters
        if s.skip_until(/\n/)
          # Discard the current line
        else
          s.skip_until(/$/) # Last line
        end
      end
    end
  when s.scan_state_data?
    if s.scan_end_line?
      @tokens << [:DATA_SCRIPT, s.get_data_script() ]
      @tokens << [:DATA_END, "END"]
      @tokens << [:TERMIN, "D_TERMIN"]
      s.scan_state_set_top()  # Return to TOP_LEVEL
    else
      # Store data lines to one token
      s.scan_whole_line()
      line = s.matched()
      s.append_to_data_script( line )
    end
  when s.scan_state_proc?
    if s.scan_end_line?
      @tokens.concat s.get_proc_tokens()
      @tokens << [:PROC_END, "END"]
      @tokens << [:TERMIN, "P_TERMIN"]
      s.scan_state_set_top()  # Return to TOP_LEVEL
    elsif s.skip_rest_after_comment_sign() # Ignore after comment sign.
    elsif s.skip_empty_line()              # Ignore the empty line.
    elsif s.skip_multiple_line_comment()   # Ignore multiple comment.
    else
      s.scan_proc_inst()
      s.append_to_proc_tokens( [].append [:PROC_INST , s.matched ])
      proc_tokens = s.tokenize_proc_line() # Tokenize the current line
      s.append_to_proc_tokens(proc_tokens)
      s.append_to_proc_tokens( [].append [:TERMIN, "TERMIN"] )
    end
  else
    raise "Error: StatSailrScanner has an invalid scan state " + s.get_scan_state
  end
end

    s.terminate()
    return @tokens
  end

end


