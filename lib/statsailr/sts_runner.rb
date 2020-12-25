require_relative "sts_build_exec.rb"

module StatSailr
  def self.run()

    if FileTest.exist?( $script_file_path )
      script_file = File.open( $script_file_path, "r")
      script = script_file.read()
      script_file.close()
    else
      raise( $script_file_path + ":StatSailr source file does not exit")
    end

    StatSailr.build_exec(script, initR_beforeExec: true, endR_afterExec: true, block_idx_start: 1, set_working_dir: File.dirname( $script_file_path ) )
  end
end
