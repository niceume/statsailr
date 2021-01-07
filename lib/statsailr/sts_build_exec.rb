require "r_bridge"

module StatSailr
def self.initR()
  RBridge.init_embedded_r()
  puts "R program initialized"
end

def self.initial_setting_for_r(device_info)
  p device_info
  if (! device_info.nil?) && (device_info.is_a? Array )  # (e.g.) ["Gtk3", <FFI::Pointer>]
    device_type = device_info[0]
    case device_type.downcase
    when "gtk3"
      puts "Use asCairoDevice function in cairoDeviceGtk3 library"
      if ! device_info[1].is_a?(FFI::Pointer)
        raise "Pointer to GtkWidget needs to be specified"
      end
      p device_info
      p_widget = device_info[1]
      lib_func = RBridge.create_library_function("cairoDeviceGtk3")
      RBridge.exec_function_no_return(lib_func)
      attach_widget_func = RBridge.create_function_call("asCairoDevice", {"widget" => RBridge.create_extptr(p_widget) } )
      RBridge.exec_function_no_return(attach_widget_func)
    else
      puts "Unknown device type: #{device_type}"
    end
  end
  RBridge.exec_function_no_return( RBridge.create_function_call("options", {"warn" => RBridge.create_intvec([ 1 ])} ))
end

def self.endR()
  RBridge.end_embedded_r()
  puts "R program safely finished"
end

def self.change_working_dir( set_working_dir )
  unless Dir.exists?(set_working_dir)
    raise "New working directory not found: #{set_working_dir}"
  end
  RBridge.exec_function_no_return( RBridge.create_function_call("setwd", {"dir" => RBridge.create_strvec([set_working_dir])}))
  puts "R program working directory is set to #{set_working_dir}"
end


def self.build_exec( script , initR_beforeExec: false , endR_afterExec: false , block_idx_start: 1, set_working_dir: nil, device_info: nil )

require_relative("scanner/sts_scanner.rb")

s = STSScanDriver.new( script )
tokens = s.tokenize()

if tokens.empty?
  puts "Input token is empty"
  if initR_beforeExec
    initR()
    initial_setting_for_r( device_info )
  end
  if endR_afterExec
    endR()
  end
  return 0
end

require_relative("parser/sts_parse.tab.rb")

gram_nodes = STSParserDriver.run( tokens )

require_relative("block_builder/sts_block.rb")

blocks = []
gram_nodes.each(){|node|
  case node.type
  when :TOP_BLOCK
    blocks << TopStmt.new_from_gram_node(node)
  when :DATA_BLOCK
    blocks << DataBlock.new_from_gram_node(node)
  when :PROC_BLOCK
    blocks << ProcBlock.new_from_gram_node(node)
  end
}

require_relative("block_to_r/sts_block_to_r.rb")
require_relative("block_to_r/proc_setting_support/proc_setting_manager.rb")

if initR_beforeExec
  initR()
  initial_setting_for_r( device_info )
end

if ! set_working_dir.nil?
  change_working_dir( set_working_dir )
end

if @proc_setting_manager.nil?
  @proc_setting_manager = ProcSettingManager.new
  @proc_setting_manager.add_proc_settings_from_dir( File.expand_path( "proc_setting/" , __dir__ ) )
end

begin
block_idx = block_idx_start
blocks.each(){|blk|
  RBridge.ptr_manager_open ("Block No. " + block_idx.to_s) {
    begin
      puts "BLOCK NO. " + block_idx.to_s
      case blk
      when TopStmt
        func = TopStmtToR.create_function( blk )
        RBridge.exec_function_no_return( func ) unless func.nil?
      when DataBlock
        func = DataBlockToR.create_function( blk )
        RBridge.exec_function_no_return( func )
      when ProcBlock
        result_manager = RBridge::RResultManager.new
        lazy_funcs_with_print_result_opts = ProcBlockToR.create_lazy_funcs( blk , @proc_setting_manager )
        lazy_funcs_with_print_result_opts.each(){|lazy_func, print_opt, store_result , result_name |
          puts "Instruction #{result_name}"
          r_obj = RBridge.exec_lazy_function( lazy_func , result_manager , allow_nil_result: true)
          if(store_result)
            result_manager.add_inst_r_obj( result_name, r_obj)
          end
          if(print_opt.nil? || print_opt == false)
            # nop
          elsif(print_opt == true )
            print_func = RBridge::create_function_call("print", { "x" => r_obj } )
            RBridge::exec_function_no_return(print_func)
          elsif(print_opt.is_a? String)
            func_before_print = print_opt
            print_func = RBridge::create_function_call("print", {"x" => RBridge::create_function_call( func_before_print , { "" => r_obj }) })
            RBridge::exec_function_no_return(print_func)
          else
            raise "print_opt needs to be true, false, String."
          end
        }
      end
    rescue => e
      e.class.module_eval { attr_accessor :block_num_executed}  # Add block_num_executed attribute to the current error object dynamically.
      e.block_num_executed = block_idx - block_idx_start
      raise e
    end
  }
  puts()
  block_idx = block_idx + 1
}
rescue => error
  puts "stopped working in block no." + block_idx.to_s
  RBridge.gc_all()
  puts "gc is explicitly executed for this block"
  raise
end

if endR_afterExec
  endR()
end

return ( block_idx - block_idx_start ) # number of blocks processed. 

end

end