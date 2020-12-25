class ProcOptValidator
  attr :validator_rules

  def initialize( )
    @validator_rules = {}
  end

  def rule( option_name , is_a: nil, as: nil , required: false)
    @validator_rules[option_name] = {"is_a" => is_a , "as" => as, "required" => required }
  end

  def check_and_modify( param_manager )
    if ( ! @validator_rules.nil? ) && (! @validator_rules.empty?)
      @validator_rules.each{| opt_name, validator |
        class_name_in_param_manager = param_manager.param_hash[opt_name].class.name.split('::').last
        if validator["required"] == true
          if ! param_manager.param_hash.has_key?(opt_name)
            raise "#{opt_name} is required for this PROC option"
          end
        end
        if ! validator["is_a"].nil?
          if validator["is_a"].is_a?(Array)
            if ! validator["is_a"].include? class_name_in_param_manager
              raise "#{opt_name} needs to be one of #{validator["is_a"].join("|")}, but #{class_name_in_param_manager} is assigned"
            end
          else
            if validator["is_a"] != class_name_in_param_manager
              raise "#{opt_name} needs to be #{validator["is_a"]}, but #{class_name_in_param_manager} is assigned"
            end
          end

        end
        if ! validator["as"].nil?
          if validator["as"] != class_name_in_param_manager
            case validator["as"]
            when "SymbolR"
              param_manager.param_hash[opt_name] = RBridge::SymbolR.new(param_manager.param_hash[opt_name])
            when "String"
              param_manager.param_hash[opt_name] = param_manager.param_hash[opt_name].to_s
            when "Integer"
              param_manager.param_hash[opt_name] = param_manager.param_hash[opt_name].to_i
            when "Float"
              param_manager.param_hash[opt_name] = param_manager.param_hash[opt_name].to_f
            else
              raise "We need to convert type but do not know how to do it. #{class_name_in_param_manager} => #{validator["as"]}"
            end
          end
        end
      }
    end
  end
end
