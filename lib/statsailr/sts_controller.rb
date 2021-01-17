STDOUT.sync = true

require "statsailr"
require "stringio"

require "statsailr/sts_build_exec"
require "statsailr/sts_output/output_manager"

class StatSailrController
  INITIAL_BLOCK_COUNTER = 1
  @block_counter = INITIAL_BLOCK_COUNTER

  def self.init( working_dir: nil ,  device_info: nil)
    if ! device_info.nil?
      # This parameter should be something like ["Gtk3", <FFI::Pointer>]
      raise "device_info parameter needs to be an Array" unless device_info.is_a? Array
      raise "device_info parameter needs to be size 2" unless device_info.size == 2
      raise "device_info parameter requires String for its first element" unless device_info[0].is_a? String
      raise "device_info parameter requires FFI::Pointer to GtkWidget for its second element" unless device_info[1].is_a? FFI::Pointer
    end

    if working_dir.nil?
      working_dir = File.expand_path('~')
    end

    @output_mngr = StatSailr::Output::OutputManager.new(capture: true)

    num_executed = 0
    num_executed = StatSailr.build_exec( " ", initR_beforeExec: true, endR_afterExec: false,
                                        block_idx_start: @block_counter, set_working_dir: working_dir, device_info: device_info,
                                        output_mngr: @output_mngr )
    @block_counter = num_executed + @block_counter
    return @output_mngr.to_s
  end

  def self.run(script)
    begin
      num_executed = 0
      output = ""
      num_executed = StatSailr.build_exec( script, initR_beforeExec: false, endR_afterExec: false,
                                          block_idx_start: @block_counter, output_mngr: @output_mngr.reset  )
    rescue RuntimeError => e
      print e.backtrace.map.with_index{|elem, idx| idx.to_s + " " + elem }.reverse.join("\n")
      puts "  \e[1m#{e.message}\e[22m"  # show in bold
      output << "Error\n"
      output << "\n" << e.message << "\n\n" # output error for user
      # ToDo, obtain num_executed before error rased.
      num_executed = e.block_num_executed
    ensure
      output << @output_mngr.to_s
      @block_counter = num_executed + @block_counter
      script = ""
    end

    return output
  end
  
  def self.stop
    StatSailr.build_exec( " ", initR_beforeExec: false, endR_afterExec: true , block_idx_start: @block_counter, output_mngr: @output_mngr.reset )
    output = @output_mngr.to_s
    return output
  end
end


