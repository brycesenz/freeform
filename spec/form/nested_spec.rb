require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'

describe FreeForm::Nested do
  describe "class methods", :class_methods => true do
    describe "has_many", :has_many => true do
      let(:form_class) do
        klass = Class.new(Module) do
          include FreeForm::Property
          include FreeForm::Nested

          has_many :mailing_addresses do
            declared_model :address
            
            property :street, :on => :address
          end
          
          def mailing_address_form_initializer
            {:address => OpenStruct.new}
          end
          
          def initialize(h={})
            h.each {|k,v| send("#{k}=",v)}
          end  
        end
        # This wrapper just avoids CONST warnings
        v, $VERBOSE = $VERBOSE, nil
          Module.const_set("DummyForm", klass)
        $VERBOSE = v
        klass
      end
  
      let(:form) do
        form_class.new
#        form_class.new(:build_mailing_address_form => {  })
=begin
        form_class.new(
          :customer => Customer.new,
          :user_account => UserAccount.new
          :addresses_form_initializer => {:address => }) 
=end
      end

      describe "form class" do
        it "sets nested_form in models" do
          form_class.models.should eq([:mailing_addresses])
        end
      end
      
      describe "building nested models" do
        it "initializes with no nested models prebuilt" do
          form.mailing_addresses.should eq([])
        end
        
        it "allows new models to be built" do
          form.build_mailing_address
          form.mailing_addresses.should be_an(Array)
          form.mailing_addresses.should_not be_empty
          form.mailing_addresses.first.should be_a(Module::DummyForm::MailingAddressesForm)
        end

        it "reflects on association" do
          reflection = form_class.reflect_on_association(:mailing_addresses)
          reflection.klass.should eq(Module::DummyForm::MailingAddressesForm)
        end
      end
      
      describe "setting attributes" do
        describe "nested attribute assignment" do
          let(:attributes) do
            { :mailing_addresses_attributes => { "0" => { :street => "123 Main St." } } }
          end
  
          it "assigns nested attributes" do
            form.fill(attributes)
            form.mailing_addresses.first.street.should eq("123 Main St.")
          end
        end
      end      
    end
  end
end