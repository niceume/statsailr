require "r_bridge"

module BlockToRSupport
end

require_relative "top_stmt/top_stmt_to_r_func.rb"
module TopStmtToR
  include BlockToRSupport
  def self.create_function( blk )
    r_func = nil
    case blk.command
    when /^(\w+)$/
      method_to_create_r_function = "create_r_func_for_" + $1.downcase
      if respond_to? method_to_create_r_function
        r_func = send( method_to_create_r_function , blk.opts)
      else
        raise "#{method_to_create_r_function} cannot be found. Unknown top level command: #{blk.command}"
      end
    else
      raise "Invalid TOPLEVEL command name: " + blk.command
    end
    puts "The following options are not used in " + blk.command + " : " + blk.opts.keys.join(" ") if ! blk.opts.empty?
    return r_func
  end
end

module DataBlockToR
  include BlockToRSupport
  @datasailr_library_loaded = false

  def self.load_datasailr_library
    if ! @datasailr_library_loaded
      begin
        lib_func1 = RBridge.create_library_function("datasailr")
        result = RBridge.exec_function(lib_func1)
        @datasailr_library_loaded = true
      rescue => err
        puts "ERROR: 'datasailr' package cannot be found in the following R library paths."
        libpath = RBridge.create_function_call(".libPaths", {})
        RBridge.exec_function_no_return( RBridge.create_function_call("print", {"x" => libpath}))
        puts "Please make sure that the package is installed in one of the libraries."
        err.set_backtrace([])
        raise err, "DATA block evaluation failed"
      end
    end
  end

  def self.create_function( blk )
    load_datasailr_library()

    out_ds = blk.out
    if set_ds = blk.opts["set"]
    else
      raise "DATA block requires set= option for input dataset"
    end

    puts "Processing data [input:#{set_ds.to_s} ouput:#{out_ds.to_s}]"

    ds_script = blk.script

    datasailr_func = RBridge.create_function_call( "sail" , {"df" => set_ds.to_r_symbol, "code" => RBridge.create_strvec([ds_script])} )
    r_func = RBridge.create_assign_function( out_ds.to_s , datasailr_func )   
  end
end


require_relative("sts_lazy_func_gen.rb")
require_relative("proc_setting_support/proc_setting_module.rb")

module ProcBlockToR
  include BlockToRSupport
  FINALIZER_NAME = "finalizer"

  def self.create_lazy_funcs( blk , proc_setting_manager )
    proc_command = blk.command
    param_manager = RBridge::RParamManager.new( blk.opts )
    proc_stmts = blk.stmts

    if ! proc_setting_manager.is_loaded?( proc_command )
      proc_setting_manager.load_setting( proc_command )
      p "#{proc_command} setting is loaded"
    end

    lzf_gen = LazyFuncGenerator.new
    lzf_gen.extend(Object.const_get("Proc"+proc_command.capitalize))
    
    validator = lzf_gen.validator
    if ! validator.nil?
      validator.check_and_modify( param_manager )
    end

    proc_lazy_funcs_with_print_result_opts = proc_stmts.map(){|proc_stmt|
      lzf_gen.gen_lazy_func( proc_command, proc_stmt, param_manager )
    }

    finalizer = lzf_gen.finalizer
    if finalizer.enabled?
      finalizer_func = lzf_gen.gen_lazy_func( proc_command , [ FINALIZER_NAME, "", nil] , param_manager )
      proc_lazy_funcs_with_print_result_opts.push( finalizer_func )
    end

    return proc_lazy_funcs_with_print_result_opts
  end
end



