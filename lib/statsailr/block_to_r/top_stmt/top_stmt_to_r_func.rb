module TopStmtToR
      def self.read_rds(data_path, opts)
        if as_name = opts["as"]
          opts.delete("as")
          puts "Read #{data_path} using readRDS(), which uses #{as_name} for dataset name."
          read_func = RBridge.create_function_call( "readRDS" , {"file" => RBridge.create_strvec([data_path])} )
          r_func = RBridge.create_assign_function( as_name.to_s , read_func )
        else
          basename = File.basename(data_path, File.extname(data_path))
          as_name = basename.gsub(/\s/, '_').downcase
          puts "Read #{data_path} using readRDS(), which uses #{as_name} for dataset name (created from filename)."
          read_func = RBridge.create_function_call( "readRDS" , {"file" => RBridge.create_strvec([data_path])} )
          r_func = RBridge.create_assign_function( as_name , read_func )
        end
        return(r_func)
      end

      def self.read_rda(data_path, opts)
        if as_name = opts["as"]
          opts.delete("as")
          puts "Read #{data_path} using laod(), which does not rename object when importing. 'as' option is ignored."
        end

        r_func = RBridge.create_function_call( "load" , {"file" => RBridge.create_strvec([data_path])} )
        return(r_func)
      end

      def self.read_csv(data_path, opts)
        opt_hash = {}
        if header = opts["header"]
          opts.delete("header")
          opt_hash = {"header" => RBridge.create_lglvec([header]) }
        else
          opt_hash = {"header" => RBridge.create_lglvec([true]) }
        end

        available_opts = ["sep","na.strings","skip"]

        opts.filter!(){|k,v|
          if available_opts.include?(k)
            opt_hash[k] = RBridge.create_vec( [v] )
          end
          ! available_opts.include?(k)
        }

        if as_name = opts["as"]
          opts.delete("as")
          puts "Read #{data_path} using read.csv(), which uses #{as_name} for dataset name."
          read_func = RBridge.create_function_call( "read.csv" , {"file" => RBridge.create_strvec([data_path])}.merge(opt_hash) )
          r_func = RBridge.create_assign_function( as_name.to_s , read_func )
        else
          basename = File.basename(data_path, File.extname(data_path))
          as_name = basename.gsub(/\s/, '_').downcase
          puts "Read #{data_path} using read.csv(), which uses #{as_name} for dataset name (created from filename)."
          read_func = RBridge.create_function_call( "read.csv" , {"file" => RBridge.create_strvec([data_path])}.merge(opt_hash) )
          r_func = RBridge.create_assign_function( as_name , read_func )
        end
      end

  def self.create_r_func_for_read(opts)
    case
    when builtin_data_name = opts["builtin"] # builtin
      opts.delete("builtin"); opts.delete("file")
      puts "Built-in dataset becomes available using data(): #{builtin_data_name.to_s}"
      r_func = RBridge.create_function_call( "data" , {"" => RBridge.create_strvec([ builtin_data_name.to_s ])} )
    when file_path = opts["file"] # csv
      opts.delete("builtin"); opts.delete("file")
      if type = opts["type"]
        opts.delete("type")
        case type.downcase
        when "rds"
          r_func = read_rds(file_path, opts)
        when "rdata"
          r_func = read_rda(file_path, opts)
        when "csv"
          r_func = read_csv(file_path, opts)
        else
          raise "TOPLEVEL READ statement currently supports rds(single r object), rdata or csv for type option. #{type} is specified."
        end
      else
        case file_path
        when /\.(rds)$/i  # i is option to ignore cases
          r_func = read_rds(file_path, opts)
        when /\.(rdata|rda)$/i
          r_func = read_rda(file_path, opts)
        when /\.csv$/i
          r_func = read_csv(file_path, opts)
        else
          raise "TOP level READ statement tried to idenfity file type from 'file=' option, but failed. File name preferably ends with .rds, .RData(.rdata) or .csv, or specify file type."
        end
      end
    else
      raise "TOPLEVEL READ statement requires 'builtin=' or 'file=' option."
    end
  end

    def self.save_rds(r_var, data_path)
      puts "SAVE #{data_path} using saveRDS()"
      if(r_var.size != 1)
        puts "Only one dataset can be specified. Others are ignored."
      end
      r_var = r_var[0]
      save_rds_func = RBridge.create_function_call( "saveRDS" , {"object" => RBridge::SymbolR.new(r_var).to_r_symbol, "file" => RBridge.create_strvec([data_path])} )
      return save_rds_func
    end
    def self.save_rda(r_var, data_path)
      puts "SAVE #{data_path} using save()"
      save_rds_func = RBridge.create_function_call( "save" , {"" => RBridge::create_strvec(r_var), "file" => RBridge.create_strvec([data_path])} )
      return save_rds_func
    end
    def self.save_csv(r_var, data_path)
      puts "SAVE #{data_path} using write.csv()"
      if(r_var.size != 1)
        puts "Only one dataset can be specified. Others are ignored."
      end
      r_var = r_var[0]
      save_csv_func = RBridge.create_function_call( "write.csv" , {"x" => RBridge::SymbolR.new(r_var).to_r_symbol, "file" => RBridge.create_strvec([data_path])} )
      return save_csv_func
    end

  def self.create_r_func_for_save(opts)
    if opts["file"]
      file_path = opts["file"]
    else
      raise "TOPLEVEL SAVE statement require 'file=' option. 'type=' option is optional when file extension matches file type."
    end
    if opts["type"]
      type = opts["type"].downcase
    end
    opts.delete("file"); opts.delete("type")

    if ! opts.empty?
      dataset_to_save = opts.filter(){|k,v| v.nil? }.keys
      dataset_to_save.each{|elem|
        opts.delete(elem)
      }
    else
      raise "Dataset should be specified"
    end

    case type
    when "rds"
      r_func = save_rds(dataset_to_save, file_path)
    when "rdata"
      r_func = save_rda(dataset_to_save, file_path)
    when "csv"
      r_func = save_csv(dataset_to_save, file_path)
    else
      case file_path
      when /\.rds$/i
        r_func = save_rds(dataset_to_save, file_path)
      when /\.(rda|rdata)$/i
        r_func = save_rda(dataset_to_save, file_path)
      when /\.csv$/i
        r_func = save_csv(dataset_to_save, file_path)
      else
        raise "TOP level SAVE statement tried to idenfity file type from file option, but failed. File name preferably ends with .rds, .rda (.rdata) or .csv, or specify file type."
      end
    end
    return r_func
  end

  def self.create_r_func_for_getwd(opts)
    puts "Current working directory"
    r_func = RBridge.create_function_call( "print", {"x" => RBridge.create_function_call( "getwd" , {} )})
    return r_func
  end

  def self.create_r_func_for_setwd(opts)
    opts.select!(){|k,v| v.nil? }
    if opts.empty?
      raise "SETWD requires String keyword that specifies directory to which working diretory moves."
    end

    puts "Setting new working directory"
    dir_path = opts.keys[0]
    opts.delete(dir_path)
    r_func = RBridge.create_function_call( "setwd" , {"dir" => RBridge.create_strvec([dir_path])} )
    return r_func
  end

end
