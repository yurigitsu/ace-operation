require "ace_cmd"
require "ace_config"

module AceOperation
  class Base
    include AceCommand

    # Monkey patch AceConfig::Setting to alias step to config
    module ::AceConfig
      class Setting
        alias step config
      end
    end

    attr_accessor :operation_params

    configure :operation_steps

    class << self
      alias operation command

      def steps(&block)
        return operation_steps unless block_given?

        operation_steps(&block)
        load_steps!
      end

      def load_steps!
        operation_steps.to_h.each do |step_name, step_klass|
          break unless step_name

          config_step_name = "configured_#{step_name}_step"

          # sets step with config or returns already set step
          define_method(config_step_name) do
            raise "Invalid configured step" if step_klass && !step_klass.respond_to?(:call)

            step_klass
          end

          # sets step with DI or returns already set step
          define_method(step_name) do |di_klass = nil|
            defined_step = instance_variable_get("@#{step_name}")
            return defined_step if defined_step

            command = di_klass || __send__(config_step_name)
            return unless command
            raise "Invalid step" unless command.respond_to?(:call)

            instance_variable_set("@#{step_name}", command)
          end

          # [TODO:] check how positioanal and keyword args works when proxing
          define_method("#{step_name}!") do |*args|
            init_command = __send__(step_name)
            config_command = __send__(config_step_name)

            command = init_command || config_command
            # raise unless step

            step command.call(*args)
          end
        end
      end

      def call(operation_params = {})
        raise "Invalid operation params" unless operation_params.is_a?(Hash)

        super(operation_params) do |operation|
          operation.operation_params = operation_params

          yield operation if block_given?
        end
      end
    end

    def ctx
      @ctx ||= {}
    end

    def step(result_or_hash_or_symbol)
      name = nil
      result = nil
      command = nil

      step_params = ctx[:result].respond_to?(:success?) ? ctx[:result].value : operation_params

      if result_or_hash_or_symbol.is_a?(Hash)
        name, command_or_result = result_or_hash_or_symbol.to_a.first
        raise "Invalid step name result" unless name.is_a?(Symbol)

        # [TODO:] DI has higher priority than step name
        # step validation: MyCmd
        # step command_step: custom_method(_params_)
        command = __send__(name) || command_or_result

        if command.respond_to?(:call)
          result = command.call(step_params)
        else
          raise "Invalid step result" unless command.respond_to?(:success?)

          result = command
        end
      end

      if result_or_hash_or_symbol.is_a?(Symbol)
        name = result_or_hash_or_symbol
        init_command = __send__(name)
        config_command = __send__("configured_#{name}_step")

        command = init_command || config_command
        raise "Invalid custom command step" unless command.respond_to?(:call)

        result = command.call(step_params)
      end

      result ||= result_or_hash_or_symbol if result_or_hash_or_symbol.respond_to?(:success?)

      step_result = result || Failure!(result)

      ctx[name] = step_result if name
      ctx[:result] = step_result

      step_result
    end
  end
end
