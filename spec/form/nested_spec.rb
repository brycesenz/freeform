require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'

describe FreeForm::Nested do
  describe "class methods", :class_methods => true do
    describe "models", :models => true do
      describe "declared model", :declared_model => true do
        let(:form_class) do
          klass = Class.new(Module) do
            include FreeForm::Property
            include FreeForm::Nested

            has_many :mailing_addresses do
              declared_model :address
              
              property :street, :on => :address
            end
          end
          Module.const_set("DummyForm", klass)
          klass
        end
    
        let(:form) do
          form_class.new
        end
    
        it "sets nested_form in models" do
          form_class.models.should eq([:mailing_addresses])
        end
        
        it "reflects on association" do
          reflection = form_class.reflect_on_association(:mailing_addresses)
          reflection.klass.should eq(Module::DummyForm::MailingAddressesForm)
        end
      end
    end
  end
end