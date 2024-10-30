# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Explicit::DSL" do
  before do
    operation_helper_stub("MyCmd")

    stub_const(
      "BaseOperation", Class.new(AceOperation::Base) do
        steps do
          config :service
          config :normalizer
        end
      end
    )

    stub_const(
      "ExplicitConfigDummy", Class.new(BaseOperation) do
        steps do
          service MyCmd
          normalizer MyCmd
        end

        def call(params)
          # implicit unpacking: rez = MyService.call(params); rez.success? ? rez.value : Failure!(rez.failure)
          rez = service!(params)
          run_normalizer(rez.value)
          # ...
        end

        # explicit unpacking
        def run_normalizer(data)
          normalizer.call(data).tap { |rez| rez.success? ? rez.value : Failure!(rez.failure) }
        end
      end
    )
  end

  context "Explicit steps" do
    let(:result) { { data: "Result" } }

    it "is defined" do
      a = ExplicitConfigDummy.call(result)

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq(result)
      end
    end
  end
end
