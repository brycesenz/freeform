require 'spec_helper'
require 'freeform/form/property'

describe FreeForm::Property do
  describe "declared model", :declared_model => true do
    let(:form) do
      Class.new(Module) do
        include FreeForm::Property
        declared_model :test_model_1
        declared_model :test_model_2

        def initialize(h)
          h.each {|k,v| send("#{k}=",v)}
        end  
      end
    end

    it "sets declared model as accessor" do
      dummy_model = OpenStruct.new(:dummy => "yes")
      form.new(:test_model_1 => dummy_model).test_model_1.should eq(dummy_model)
    end
  end
end