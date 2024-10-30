# typed: true
# frozen_string_literal: true

module OperationHelper
  # Creates a helper XXXXX
  #
  # This method XXXXX
  #
  # @example XXXXX
  def operation_helper_stub(cmd_name)
    stub_const(
      cmd_name, Class.new do
        include AceCommand

        def call(input)
          Success(input)
        end
      end
    )
  end
end
