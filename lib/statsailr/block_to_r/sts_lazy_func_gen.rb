require "r_bridge"

module LazyFuncGeneratorSettingUtility
  def read_as_formula(ary)
    return RBridge.create_formula_from_syms( ary )
  end

  def read_as_strvec(ary)
    return RBridge.create_strvec( ary.map(){|elem| elem.to_s } )
  end

  def read_as_one_str(ary)
    return RBridge.create_strvec( [ ary.map(){|elem| elem.to_s }.join(" ") ] )
  end

  def read_as_numvec(ary)
    if ary.any?(){|elem| elem.is_a?(Float) }
      read_as_realvec(ary)
    else
      read_as_intvec(ary)
    end
  end

  def read_as_intvec(ary)
    return RBridge.create_intvec( ary )
  end

  def read_as_realvec(ary)
    return RBridge.create_realvec( ary )
  end

  def read_as_symbol(ary)
    raise "main argument is expected to be length of 1" unless ary.length == 1
    raise "symbol is expected" unless ary[0].is_a?( RBridge::SymbolR )
    return ary[0].to_r_symbol
  end

  def read_symbols_as_strvec(ary)
    raise "symbol is expected as an element" unless ary.all?{|elem| elem.is_a?( RBridge::SymbolR )}
    return RBridge.create_strvec( ary.map(){|elem| elem.to_s } )
  end

  def read_symbols_or_functions_as_strvec(ary)
    deapth_ary = Array.new( ary.size )
    idx = 0
    last_idx = ary.size - 1
    deapth = 0
    while( idx <= last_idx )
      if( ary[idx].is_a?(RBridge::SymbolR) && (ary[idx + 1].is_a?(RBridge::SignR) && ary[idx + 1].to_s == "("))
        # function starts
        deapth_ary[idx] = deapth
        deapth = deapth + 1
        idx = idx + 1
        deapth_ary[idx] = deapth
      elsif( ary[idx].is_a?(RBridge::SignR) && ary[idx].to_s == "(")
        # parenthesis starts
        deapth = deapth + 1
        deapth_ary[idx] = deapth
      elsif( ary[idx].is_a?(RBridge::SignR) && ary[idx].to_s == ")")
        # parenthesis ends or function ends
        deapth_ary[idx] = deapth
        deapth = deapth - 1
      else
        deapth_ary[idx] = deapth
      end
      idx = idx + 1
    end

    result_ary = []
    ary.zip( deapth_ary).each(){|elem, deapth|
      if elem.respond_to? :to_s_for_r_parsing
        elem_str = elem.to_s_for_r_parsing
      else
        elem_str = elem.to_s
      end

      if( deapth == 0)
        result_ary.push( elem_str )
      else
        result_ary.last << " " << elem_str
      end
    }

    return RBridge.create_strvec( result_ary )
  end

  def read_named_args_as_named_strvec(ary)
    arg_num_ary = Array.new( ary.size )
    deapth_ary = Array.new( ary.size )
    idx = 0
    last_idx = ary.size - 1
    arg_num = nil
    deapth = nil

    while( idx <= last_idx )
      if( idx == 0 )
        # name starts
        unless ( deapth.nil? && ary[idx].is_a?(RBridge::SymbolR) && (ary[idx + 1].is_a?(RBridge::SignR) && ary[idx + 1].to_s == "="))
          raise "read_named_args_as_named_strvec requires an argument to start with name=expr"
        end
        arg_num = 0
        deapth = 0
      elsif( deapth == 0 && ary[idx].is_a?(RBridge::SymbolR) && (ary[idx + 1].is_a?(RBridge::SignR) && ary[idx + 1].to_s == "="))
        # name starts
        arg_num = arg_num + 1
      elsif( ary[idx].is_a?(RBridge::SymbolR) && (ary[idx + 1].is_a?(RBridge::SignR) && ary[idx + 1].to_s == "("))
        # function starts
        deapth_ary[idx] = deapth
        arg_num_ary[idx] = arg_num
        deapth = deapth + 1
        idx = idx + 1
        deapth_ary[idx] = deapth
      elsif( ary[idx].is_a?(RBridge::SignR) && ary[idx].to_s == "(")
        # parenthesis starts
        deapth = deapth + 1
        deapth_ary[idx] = deapth
      elsif( ary[idx].is_a?(RBridge::SignR) && ary[idx].to_s == ")")
        # parenthesis ends or function ends
        deapth_ary[idx] = deapth
        deapth = deapth - 1
      else
        deapth_ary[idx] = deapth
      end
      arg_num_ary[idx] = arg_num
      idx = idx + 1
    end

    result_ary = []
    name_ary = []
    prev_arg_num = -1
    idx = 0
    elem_arg_num_ary = ary.zip( arg_num_ary )
    while( idx < elem_arg_num_ary.size )
      elem = ary[idx]
      arg_num = arg_num_ary[idx]
      if elem.respond_to? :to_s_for_r_parsing
        elem_str = elem.to_s_for_r_parsing
      else
        elem_str = elem.to_s
      end

      if( arg_num != prev_arg_num ) # starts new 'name=expr'
        name_ary.push elem_str
        idx = idx + 1
        if( ary[idx].to_s != "=" )
          raise "An argument should be in the form of 'name=expr'"
        end
      else
        if( result_ary[arg_num].nil? )
          unless result_ary.size == arg_num
            raise "arg_num is not an appropriate number."
          end
          result_ary[arg_num] = [elem_str]
        else
          result_ary[arg_num].push( elem_str )
        end
      end
      idx = idx + 1
      prev_arg_num = arg_num
    end

    result_vec = RBridge.create_strvec( result_ary.map(){|ary| ary.join(" ") } )
    name_vec = RBridge.create_strvec( name_ary )
    add_name_func = RBridge.create_ns_function_call("stats", "setNames", {"object" => result_vec, "nm" => name_vec })
    result_name_vec = RBridge.exec_function( add_name_func )
    return result_name_vec
  end

  def result( name , *addl )
    if addl.empty?
      return RBridge::RResultName.new(name)
    else
      ary = ([name] + addl).map(){|elem|
        RBridge::RResultName.new(elem)
      }
      return RBridge::RResultNameArray.new(ary)
    end
  end

  def param( name )
    return RBridge::RParamName.new(name)
  end

  def previous_or( default_obj )
    return RBridge::RResultPrevious.new( default_obj )
  end

  def previous_inst_name()
    return RBridge::RInstPrevious.new()
  end

  def r_obj( val )
    return RBridge.convert_to_r_object( val )
  end

  def is_result_name?( val )
    val.is_a? RBridge::RResultName
  end

  def is_result_name_array?( val )
    val.is_a? RBridge::RResultNameArray
  end

  def is_param_name?( val )
    val.is_a? RBridge::RParamName
  end

  def is_r_obj?(val)
    RBridge.is_pointer?(val)
  end

  def one_from( name, *addl )
    if addl.empty?
      if ! ( is_result_name?(name) || is_result_name_array?(name) || is_param_name?(name) ||  is_pointer?(name) )
          raise "one_from() create RBridge::RNameContainer, which only stores RResultName, RParamName or R object(pointer)."
      end
      return name
    else
      ary = ([name] + addl).map(){|elem|
        elem
      }
      return RBridge::RNameContainer.new(ary)
    end
  end

end

class LazyFuncGeneratorSetting
  include LazyFuncGeneratorSettingUtility

  attr_accessor :libname, :envname, :func_name, :main_arg_and_how_to_treat, :runtime_args, :store_result, :print_opt, :plot_opt
  def initialize
    @libname = nil
    @envname = nil
    @func_name = nil

    @main_arg_and_how_to_treat = nil
    @runtime_args = nil

    @store_result = true
    @print_opt = nil
    @plot_opt = nil
  end

  def create_func_arg_hash( main_arg, opt_args )
    if ! @main_arg_and_how_to_treat.nil?
      main_arg_name, how_to_treat, allow_nil = @main_arg_and_how_to_treat
    else
      main_arg_name, how_to_treat, allow_nil = [nil, nil, nil]
    end
    runtime_args = @runtime_args

    if( ! main_arg_name.nil? )
      if( ! main_arg.empty? )
        if( how_to_treat.to_s =~ /^read/ )
          r_main_arg_hash = {main_arg_name => self.send( how_to_treat, main_arg)  }
        else
          raise "String element that specifies how_to_treat should start from 'read_'"
        end
      elsif allow_nil.to_s == "allow_nil"
        r_main_arg_hash = {}
      else
        raise "main_arg needs needs to be specified or setting.main_arg_and_how_to_treat needs to allow nil"
      end
    else
      r_main_arg_hash = {}
    end

    if( ! opt_args.nil? )
      r_opt_arg_hash = convert_args_to_r_args( opt_args )
    else
      r_opt_arg_hash = {}
    end

    if( !runtime_args.nil?)
      raise "rumtime_args needs to be Hash" if ! runtime_args.is_a?( Hash )
    else
      runtime_args = {}
    end

    r_args = {}
    r_args.merge!( runtime_args )
    r_args.merge!( r_opt_arg_hash )
    r_args.merge!( r_main_arg_hash )
    # The latter hashes have higher priority

    return r_args
  end

  private
  def convert_args_to_r_args( hash )
    r_hash = {}
    hash.each(){|key, value|
      if value.is_a?(Hash) && value["type"] == :func
        case value["fname"]
        when "param"
          raise "function for " + value["fname"] + " should have one argument." if value["fargs"].size > 1
          r_hash[key] = param(value["fargs"][0].to_s)
        when "result"
          raise "function for " + value["fname"] + " should have one argument." if value["fargs"].size > 1
          r_hash[key] = result(value["fargs"][0].to_s)
        else
          raise "unknown function name in optional argument: " + value.fname
        end
      elsif value.is_a?(Array)
        r_hash[key] = RBridge::convert_to_r_object(value)
      else
        r_hash[key] = RBridge::convert_to_r_object(value)
      end
    }
    return r_hash
  end
end


class LazyFuncGenerator
  include LazyFuncGeneratorSettingUtility
  SETTING_FOR_PREFIX = "setting_for_"

  def gen_lazy_func( command, proc_stmt , param_manager)

    inst = proc_stmt[0]
    main_arg = proc_stmt[1]
    opt_args = proc_stmt[2]

    underscored_inst = inst.gsub(/\./, "_")

    setting = LazyFuncGeneratorSetting.new()
    if respond_to?( SETTING_FOR_PREFIX + underscored_inst )
      send( SETTING_FOR_PREFIX + underscored_inst , setting )
    else
      raise "method for this instruction(#{inst})" "is not defined: " + SETTING_FOR_PREFIX + underscored_inst
    end
    libname = setting.libname 
    envname = setting.envname
    func_name = setting.func_name
    func_hash = setting.create_func_arg_hash( main_arg, opt_args )
    result_name = inst

    store_result = setting.store_result
    print_opt = setting.print_opt
    plot_opt = setting.plot_opt

    if libname.nil? || libname == ""
      libname = nil
    end
    if envname.nil? || libname == ""
      envname = nil
    end

    if ! libname.nil?
      lazy_func = RBridge::create_ns_lazy_function( libname, func_name, func_hash, param_manager)
    else
      if ! envname.nil?
        lazy_func = RBridge::create_env_lazy_function( envname, func_name, func_hash, param_manager)
      else
        lazy_func = RBridge::create_lazy_function( func_name, func_hash, param_manager)
      end
    end

    return [ lazy_func, print_opt, plot_opt, store_result, result_name  ]
  end

end


