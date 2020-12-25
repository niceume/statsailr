require "pathname"

class ProcSettingManager
  def initialize
    @proc_settings = {} # "command(downcase)" => { "path" => Pathname(abslute path) , "loaded" => boolean }
  end
  
  def add_proc_settings_from_dir( dir )
    raise "add_proc_settings_from_directory() requires String" unless dir.is_a? String
    dir_pathname = Pathname.new(dir)
    if ! dir_pathname.absolute?
      raise "dir should be specified in absolute path."
    end

    dir_pathname.opendir{|d|
      d.each(){|f|
        if((dir_pathname + f).file?)
          if( f =~ /proc_([a-zA-Z0-9]+)\.rb/ )
            command_name = $1
            proc_setting_path = dir_pathname + f
            @proc_settings[command_name.downcase] = { "path" => proc_setting_path, "loaded" => false }
          end
        end
      }
    }
  end

  def is_loaded?( command )
    command = command.downcase
    if @proc_settings.has_key? command 
      return @proc_settings[command]["loaded"]
    else
      return false
    end
  end

  def load_setting( command )
    command = command.downcase
    if @proc_settings.has_key? command 
      load( @proc_settings[command]["path"].to_s )
      @proc_settings[command]["loaded"] = true
    else
      raise "specified #{command} proc command cannot be found. Loaded proc settings: #{@proc_settings.keys} "
    end
  end
end



