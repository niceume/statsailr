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

  attr_accessor :libname, :func_name, :main_arg_and_how_to_treat, :runtime_args, :store_result, :print_opt, :plot_opt
  def initialize
    @libname = nil
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
    func_name = setting.func_name
    func_hash = setting.create_func_arg_hash( main_arg, opt_args )
    result_name = inst

    store_result = setting.store_result
    print_opt = setting.print_opt
    plot_opt = setting.plot_opt

    if libname.nil? || libname == ""
      libname = nil
    end

    lazy_func = RBridge::create_ns_lazy_function( libname, func_name, func_hash, param_manager)

    return [ lazy_func, print_opt, plot_opt, store_result, result_name  ]
  end

end


