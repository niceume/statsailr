require "r_bridge"
require "statsailr/sts_output/output_manager"
require "statsailr/block_to_r/proc_setting_support/proc_setting_manager.rb"

module StatSailr
def self.initR( unlimited_cstack )
  RBridge.init_embedded_r( unlimited_cstack: unlimited_cstack )
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
      @new_device_info = { "file_output" => false, "dev_off_required" => false }

    when "cairoraster"  # (e.g.) ["CairoRaster", {"width" => 800, "height" => 600 }, {"file_output_opt" => {"dir_path"=> dir_to_save , "prefix"=> "plot", "type" => "png"} }]
      puts "Use Cairo function in Cairo library"
      if ! device_info[1].is_a?(Hash)
        raise "The second element of device info needs to be Hash"
      end
      cairo_info = device_info[1].dup
      file_output_opt = device_info[2]["file_output_opt"]
      if ! ["png", "jpeg"].include? file_output_opt["type"]
        raise "only png or jpeg is supported for type"
      else
        case file_output_opt["type"]
        when "png"
          # load png library
          lib_func = RBridge.create_library_function("png")
          RBridge.exec_function_no_return(lib_func)
        when "jpeg"
          # use default jpeg device
        end
      end
      lib_func = RBridge.create_library_function("Cairo")
      RBridge.exec_function_no_return(lib_func)

      @new_device_info = { "file_output" => true, "dev_off_required" => true ,"file_output_opt" => file_output_opt,
                           "dev_control" => {
                             "new" => lambda {
                               RBridge.exec_function_no_return(
                               RBridge.create_function_call("Cairo",
                                 { "width" => RBridge.create_intvec([ cairo_info["width"] ]),
                                   "height" => RBridge.create_intvec([ cairo_info["height"] ]),
                                   "type" => RBridge.create_strvec([ "raster" ])  }))
                             },
                             "off" => lambda {
                               RBridge.exec_function_no_return(
                               RBridge.create_function_call("dev.off", {}))
                             },
                             "get_size" => lambda {
                               {:width => cairo_info["width"], :height => cairo_info["height"]}
                             },
                             "set_size" => lambda {|width, height|
                               cairo_info["width"] = width
                               cairo_info["height"] = height
                             }
                           }
                         }
      @new_device_info["dev_control"]["new"].call()

    else
      puts "Unknown device type: #{device_type}"
    end
  end
  RBridge.exec_function_no_return( RBridge.create_function_call("options", {"warn" => RBridge.create_intvec([ 1 ])} ))
end

def self.initial_procs_registration( procs_gem )
  if @proc_setting_manager.nil?
    @proc_setting_manager = ProcSettingManager.new

    if procs_gem.nil?
      puts "No PROC(s) are instructed to be registered. nil specified."
    elsif ! [String, Array].include? procs_gem.class
      raise "procs_gem needs to be specified in String or Array."
    else
      if procs_gem.class == String
        procs_gem = [procs_gem]
      end

      procs_gems_name_class_array = procs_gem.filter_map(){|gem_name| 
        if gem_name =~ /^statsailr_(\w+)/
          class_name = $1.split("_").map(){|elem| elem.capitalize()}.join("")
          [ gem_name, class_name ]
        else
          raise 'gem name specified for procs_gem is not appropriate. The name pattern should be /^statsailr_(\w+)/'
        end
      }

      puts ("Load gems for PROC settings")
      procs_gems_name_class_array.each{|procs_gem_name, procs_class_name|
      # Add PROCs from gems
        begin
          require(procs_gem_name)
          @proc_setting_manager.add_proc_settings_from_dir( Module.const_get( "StatSailr::" + procs_class_name).send( "path_to_proc_setting") )
          puts "#{procs_gem_name} gem is loaded (ver. #{Gem.loaded_specs[procs_gem_name].version.to_s})"
        rescue LoadError => e
          puts e.message
          puts "#{procs_gem_name} gem failed to be loaded"
          e.set_backtrace( [] )
        rescue NameError
        rescue RuntimeError
        end
      }
    end
  end
end

def self.endR()
  if ! @new_device_info.nil?
    if @new_device_info["dev_off_required"]
      RBridge.exec_function_no_return( RBridge.create_function_call("dev.off", {}))
    end
  end
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


def self.build_exec( script , initR_beforeExec: false , endR_afterExec: false , block_idx_start: 1, set_working_dir: nil, device_info: nil,
                     unlimited_cstack: false,
                     output_mngr: Output::OutputManager.new(capture: false), 
                     procs_gem: "statsailr_procs_base" )

require_relative("scanner/sts_scanner.rb")

output_mngr.move_to_new_node("Tokenize code")
tokens = []
output_mngr.add_new_message(:output).run($stdout){
  s = STSScanDriver.new( script )
  tokens = s.tokenize()
}
output_mngr.move_up()

if tokens.empty?
  puts "Input token is empty"
  if initR_beforeExec
    initR( unlimited_cstack )
    initial_setting_for_r( device_info )

    output_mngr.move_to_new_node("Load PROCs")
    output_mngr.add_new_message(:output).run($stdout){
      initial_procs_registration( procs_gem )
    }
    output_mngr.move_up()
  end
  if endR_afterExec
    endR()
  end
  return 0
end

require_relative("parser/sts_parse.tab.rb")

gram_nodes = nil
output_mngr.move_to_new_node("Parse tokens")
output_mngr.add_new_message(:output).run($stdout){
  gram_nodes = STSParserDriver.run( tokens )
}
output_mngr.move_up()

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

if initR_beforeExec
  initR( unlimited_cstack )
  initial_setting_for_r( device_info )

  output_mngr.move_to_new_node("Load PROCs")
  output_mngr.add_new_message(:output).run($stdout){
    initial_procs_registration( procs_gem )
  }
  output_mngr.move_up()
end

if ! set_working_dir.nil?
  change_working_dir( set_working_dir )
end

begin
output_mngr.move_to_new_node("BLOCK_TO_R")
block_idx = block_idx_start
blocks.each(){|blk|
  RBridge.ptr_manager_open ("Block No. " + block_idx.to_s) {
    begin
      block_num_str = "BLOCK NO. " + block_idx.to_s + "\n"
      case blk
      when TopStmt
        output_mngr.move_to_new_node("TopStmt")
        output_mngr.add_new_message(:text).set_content( block_num_str )
        output_mngr.add_new_message(:output).run($stdout){
          func = TopStmtToR.create_function( blk )
          RBridge.exec_function_no_return( func ) unless func.nil?
          puts ""
        }
        output_mngr.move_up()
      when DataBlock
        output_mngr.move_to_new_node("DataBlock")
        output_mngr.add_new_message(:text).set_content( block_num_str )
        output_mngr.add_new_message(:output).run($stdout){
          func = DataBlockToR.create_function( blk )
          RBridge.exec_function_no_return( func )
          puts ""
        }
        output_mngr.move_up()
      when ProcBlock
        output_mngr.move_to_new_node(["ProcBlock", blk.command ])
        output_mngr.add_new_message(:text).set_content( block_num_str )
        result_manager = RBridge::RResultManager.new
        lazy_funcs_with_print_result_opts = ProcBlockToR.create_lazy_funcs( blk , @proc_setting_manager )
        lazy_funcs_with_print_result_opts.each(){|lazy_func, print_opt, plot_opt, store_result , result_name |
          output_mngr.move_to_new_node(["inst", result_name])
          output_mngr.add_new_message(:text).set_content( "inst: #{result_name}\n" )
          output_mngr.add_new_message(:output).run($stdout){
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
          output_mngr.add_new_message(:new_line).set_content("\n")

          if( plot_opt.nil? || plot_opt == false || @new_device_info.nil? )
            #nop
          else
            if @new_device_info["file_output"] == true
              # The plot needs to be saved on disk.
              file_output_opt = @new_device_info["file_output_opt"]
              temp_path = ""
              temp_file = Tempfile.new( [file_output_opt["prefix"] , "." + file_output_opt["type"] ] , file_output_opt["dir_path"] )
              temp_path = temp_file.path
              temp_file.close(true)

              if ["png", "jpeg" ].include? file_output_opt["type"]
                # writePNG( image=Cairo.capture( device=dev.cur() ), target="./plot.png" )
                r_func_curr_dev = RBridge::create_function_call("dev.cur", {})
                r_func_cairo_capture = RBridge::create_function_call("Cairo.capture",{"device" => r_func_curr_dev})
                r_str_file_path = RBridge::create_strvec([temp_path])
                if file_output_opt["type"] == "png"
                  r_func_write_png = RBridge::create_function_call("writePNG", {"image" => r_func_cairo_capture, "target" => r_str_file_path })
                  RBridge::exec_function_no_return( r_func_write_png )
                elsif file_output_opt["type"] == "jpeg"
                  # todo: jpeg
                end
              end

              @new_device_info["dev_control"]["off"].call()
              @new_device_info["dev_control"]["new"].call()

              if(File.exist? temp_path)
                output_mngr.add_new_message(:plot_file).set_content( temp_path )
              end
            end
          end
          output_mngr.move_up()
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
ensure
  output_mngr.move_to_root()
end

if endR_afterExec
  output_mngr.move_to_new_node("INIT_R")
  output_mngr.add_new_message(:output).run($stdout){
    endR()
  }
  output_mngr.move_up()
end

return ( block_idx - block_idx_start ) # number of blocks processed. 

end

end
