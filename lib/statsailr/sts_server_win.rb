require_relative "sts_build_exec.rb"

module StatSailr
  module Service
    def self.start_win_thread( reader , writer )
      if $service_started
        puts "StatSailr::Service has already started"
        return false
      else
        $service_started = true
      end

      server_thread = Thread.start do
# Thread does not need this line.        writer.close()  # close child's writer
        script = ""
        block_idx = 1

        StatSailr.build_exec( "", initR_beforeExec: true, endR_afterExec: false )  # start R
        puts "Ready to input"
        print "(^0^): "
        while line = reader.gets() do  # !exit is dealt by REPL.
          if line[0] == "!"
            if line =~ /^!exec/ || line =~ /^!!$/
                begin
                  num_executed = StatSailr.build_exec( script, initR_beforeExec: false, endR_afterExec: false , block_idx_start: block_idx )
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
                  script = "" ;  puts()
                end
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

        puts "Finish forked (child) process"
        reader.close()
        puts "Reader pipe closed"
        StatSailr.build_exec( " ", initR_beforeExec: false, endR_afterExec: true ) # stop R
        $service_started = false
        puts "R program finished"
      end # end of fork

# Thread does not need this line.      reader.close() # close parent's reader
      return server_thread
    end
  end
end


