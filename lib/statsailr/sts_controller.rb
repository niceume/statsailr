STDOUT.sync = true

require "statsailr"
require "stringio"

require_relative "sts_build_exec.rb"

class StatSailrController
  INITIAL_BLOCK_COUNTER = 1
  @block_counter = INITIAL_BLOCK_COUNTER
  def self.capture_stream(stream)
    raise ArgumentError, 'missing block' unless block_given?
    orig_stream = stream.dup
    IO.pipe do |r, w|
      # system call dup2() replaces the file descriptor 
      stream.reopen(w) 
      # there must be only one write end of the pipe;
      # otherwise the read end does not get an EOF 
      # by the final `reopen`
      w.close 
      t = Thread.new { r.read }
      begin
        yield
      ensure
        stream.reopen orig_stream # restore file descriptor 
      end
      t.value # join and get the result of the thread
    end
  end

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

    num_executed = 0
    output = capture_stream($stdout){ num_executed = StatSailr.build_exec( " ", initR_beforeExec: true, endR_afterExec: false,
                                        block_idx_start: @block_counter, set_working_dir: working_dir, device_info: device_info ) }
    @block_counter = num_executed + @block_counter
    return output
  end

  def self.run(script)
    begin
      num_executed = 0
      output = ""
      output = capture_stream($stdout){ num_executed = StatSailr.build_exec( script, initR_beforeExec: false, endR_afterExec: false,
                                          block_idx_start: @block_counter) }
    rescue RuntimeError => e
      print e.backtrace.map.with_index{|elem, idx| idx.to_s + " " + elem }.reverse.join("\n")
      puts "  \e[1m#{e.message}\e[22m"  # show in bold
      output << "Error\n"
      output << "\n" << e.message << "\n\n" # output error for user
      # ToDo, obtain num_executed before error rased.
      num_executed = e.block_num_executed
    ensure
      @block_counter = num_executed + @block_counter
      script = ""
    end

    return output
  end
  
  def self.stop
    output = StatSailr.build_exec( " ", initR_beforeExec: false, endR_afterExec: true , block_idx_start: @block_counter )
    return output
  end
end


