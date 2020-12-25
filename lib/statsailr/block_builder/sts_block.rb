require "r_bridge"
require_relative "./sts_block_parse_proc_opts.rb"

module BlockSupport
  def type_adjust(obj , type)
    case type
    when :ident
      if obj.is_a?(String)
        result = RBridge::SymbolR.new( obj )
      else
        raise "GramNode should have string value for type(#{type.to_s})"
      end
    when :num
      if obj.is_a?(Integer) || obj.is_a?(Float)
        result = obj 
      else
        raise "GramNode with inconsistent type(#{type.to_s}) and object(#{obj.class})"
      end
    when :string
      if obj.is_a?(String)
        result = obj
      else
        raise "GramNode with inconsistent type(#{type.to_s}) and object(#{obj.class})"
      end
    when :sign
      if obj.is_a?(String)
        result = RBridge::SignR.new(obj)
      else
        raise "GramNode with inconsistent type(#{type.to_s}) and object(#{obj.class})"
      end
    end
    return result
  end
end

class TopStmt
  extend BlockSupport
  attr :command, :opts

  def initialize( str, hash )
    @command = str
    @opts = hash
  end

  def self.new_from_gram_node( node )
    command_name = node.e1
    top_opts = node.e2
    if (! top_opts.nil? ) && (top_opts.size != 0 )
      hash = {}
      top_opts.each(){|nd|
        top_opt_key = nd.e1
        if(!nd.e2.nil?)
          top_opt_val = type_adjust( nd.e2.e1 , nd.e2.type )
        else
          top_opt_val = nil
        end
        hash[top_opt_key] = top_opt_val
      }
    else
      hash = {}
    end
    return TopStmt.new( command_name, hash)
  end
end

class DataBlock
  extend BlockSupport
  attr :out, :opts, :script

  def initialize( str, hash, script)
    @out = str
    @opts = hash
    @script = script
  end

  def self.new_from_gram_node( node )
    out_df = type_adjust( node.e1.e1, node.e1.type )
    data_hash = {}
    data_opts = node.e2

    if ! data_opts.nil?
      data_opts.each(){|nd|
        data_opt_key = nd.e1
        if(!nd.e2.nil?)
          data_opt_val = type_adjust( nd.e2.e1 , nd.e2.type )
        else
          data_opt_val = nil
        end
        data_hash[data_opt_key] = data_opt_val
      }
    else
      data_opts = {}
    end

    data_script = type_adjust( node.e3.e1, node.e3.type )

    return DataBlock.new( out_df , data_hash , data_script)
  end
end

class ProcBlock
  extend BlockSupport
  attr :command, :opts, :stmts

  def initialize( command, opts, stmts )
    @command = command
    @opts = opts
    @stmts = stmts
  end

  def self.new_from_gram_node( node )
    proc_command = type_adjust( node.e1.e1, :string )

    proc_opt_hash = {}
    proc_opts = node.e2
    if(! proc_opts.nil?)
      proc_opts.each(){|nd|
        proc_opt_key = nd.e1
        proc_opt_val = type_adjust( nd.e2.e1 , nd.e2.type )
        proc_opt_hash[proc_opt_key] = proc_opt_val
      }
    else
      proc_opt_hash = {}
    end

    proc_stmts = []

    proc_stmts_ori = node.e3
    proc_stmts_ori.each(){|proc_stmt_ori|
        proc_stmt_inst = ""
        proc_stmt_arg = []
        proc_stmt_opt_hash = {}

        proc_stmt_inst = type_adjust( proc_stmt_ori.e1.e1, :string) # String
        proc_stmt_arg_ori = proc_stmt_ori.e2
        if ! proc_stmt_arg_ori.nil? then
          idx = 0
          while idx < proc_stmt_arg_ori.size() do
            elem = proc_stmt_arg_ori[idx]
            if( elem.type == :sign && elem.e1 == "/" )
              break
            else
              x = type_adjust( elem.e1, elem.type )
              proc_stmt_arg << x
              idx = idx + 1
            end
          end
          idx = idx + 1
          if idx < proc_stmt_arg_ori.size()

            proc_stmt_opt_hash = STSBlockParseProcOpts.include(BlockSupport).new(proc_stmt_arg_ori, idx).parse()
          else
            proc_stmt_opt_hash = {}
          end
        else  # When no arguments (even )
          prc_stmt_arg = []
        end

        proc_stmts.push( [proc_stmt_inst, proc_stmt_arg, proc_stmt_opt_hash ] )
    }

    return ProcBlock.new( proc_command , proc_opt_hash, proc_stmts)
  end

end


