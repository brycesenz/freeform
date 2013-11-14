require 'spec_helper'
require 'freeform/form/form_input_key'

describe FreeForm::FormInputKey do
  describe "form input key", :form_input_key => true do
    let(:form_class) do
      Class.new(Module) do
        include FreeForm::FormInputKey
        form_input_key :test_key
        
        attr_accessor :my_accessor
      end
    end

    it "sets form_input_key" do
      form_class.model_name.should eq("TestKey")
    end
  end
end