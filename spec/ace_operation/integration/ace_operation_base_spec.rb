# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AceOperation::Base" do
  before do
    stub_const(
      "BaseOperation", Class.new(AceOperation::Base) do
        steps do
          config :validation
          config :custom_step
          config :serialization
        end
      end
    )

    stub_const(
      "MyCmd", Class.new do
        include AceCommand

        def call(input)
          Success(input)
        end
      end
    )

    stub_const(
      "UltraTrailblazerDummy", Class.new(BaseOperation) do
        steps do
          validation MyCmd
          custom_step MyCmd
          serialization MyCmd
        end

        def call(_params)
          step :validation
          step :custom_step
          step :serialization
        end
      end
    )

    stub_const(
      "TrailblazerDummy", Class.new(BaseOperation) do
        def call(_params_)
          step validation: MyCmd
          step custom_step: MyCmd
          step serialization: MyCmd
        end
      end
    )

    stub_const(
      "DIDummy", Class.new(BaseOperation) do
        def call(_params_)
          step :validation
          # step :custom_step
          # step :serialization
        end
      end
    )

    stub_const(
      "DITrailblazerDummy", Class.new(BaseOperation) do
        def call(_params_)
          step validation: "MyCmd"
          step custom_step: "MyCmd"
          step serialization: "MyCmd"
        end
      end
    )

    stub_const(
      "DICustomTrailblazerDummy", Class.new(BaseOperation) do
        def call(_params_)
          step validation: "MyCmd"
          step custom_step: custom_step
          step serialization: "MyCmd"
        end

        def custom_step
          Success("Result")
        end
      end
    )
  end

  context "WIP Ultra Traiblazer" do
    it "is defined" do
      a = UltraTrailblazerDummy.call({})

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq({})
      end
    end
  end

  context "WIP Traiblazer" do
    it "is defined" do
      a = TrailblazerDummy.call({})

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq({})
      end
    end
  end

  context "WIP DI" do
    it "is defined" do
      a = DIDummy.call({}) do |operation|
        operation.validation MyCmd
        operation.custom_step MyCmd
        operation.serialization MyCmd
      end

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq({})
      end
    end
  end

  context "WIP DI Trailblazer" do
    it "is defined" do
      a = DITrailblazerDummy.call({}) do |operation|
        operation.validation MyCmd
        operation.custom_step MyCmd
        operation.serialization MyCmd
      end

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq({})
      end
    end
  end

  context "WIP DI Custom Trailblazer" do
    it "is defined" do
      a = DICustomTrailblazerDummy.call({}) do |operation|
        operation.validation MyCmd
        operation.serialization MyCmd
      end

      aggregate_failures do
        expect(a.success?).to be(true)
        expect(a.value).to eq("Result")
      end
    end
  end
end
