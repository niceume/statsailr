require_relative "sts_build_exec.rb"

module StatSailr
  module Service
    def self.start( reader , writer , fork_or_thread: "fork" )
      if $service_started
        puts "StatSailr::Service has already started"
        return false
      else
        $service_started = true
      end

      child_exec = lambda{
        p self
        if fork_or_thread == "fork"    
          writer.close()  # close child's writer
        end
        script = ""
        block_idx = 1
        @first_time = true

        puts "Ready to input"
        print "(^0^): "
        while line = reader.gets() do  # !exit is dealt by REPL.
          if line[0] == "!"
            if line =~ /^!exec/ || line =~ /^!!$/
                ### Execute script ###
                begin
                  if @first_time
                    num_executed = StatSailr.build_exec( script, initR_beforeExec: true, endR_afterExec: false )  # start R
                    @first_time = false
                  else
                    num_executed = StatSailr.build_exec( script, initR_beforeExec: false, endR_afterExec: false , block_idx_start: block_idx )
                  end
                rescue RuntimeError => e
                  print e.backtrace.map.with_index{|elem, idx| idx.to_s + " " + elem }.reverse.join("\n")
                  puts "  \e[1m#{e.message}\e[22m"  # show in bold
                  if e.respond_to? "block_num_executed"
                    num_executed = e.block_num_executed
                  end
                ensure
                  if num_executed.nil?
                    puts "Information about num_executed is not returned: set 0"
                    num_executed = 0
                  end
                  block_idx = block_idx + num_executed
                end
                script = "" ;  puts()
            elsif line =~ /^!clear/
              script = ""
              puts "script is cleared"
            elsif line =~ /^!script/
              puts "script currently in queue"
              puts script
            else
              puts "Unknown command line is ignored : " + line
              puts "Available commends: !exec !exit !clear !script"
            end
          else
            script << line
          end
        end # end of while

        puts "Finish child process/thread"
        reader.close()
        puts "Reader pipe closed"
        StatSailr.build_exec( " ", initR_beforeExec: false, endR_afterExec: true ) # stop R
        $service_started = false
        puts "R program finished"
      } # end of lambda

      case fork_or_thread
      when "fork"
        child_pid = fork &child_exec
        reader.close() # close parent's reader
        return child_pid
      when "thread"
        child_thread = Thread.start &child_exec
        return child_thread
      end
    end
  end
end


