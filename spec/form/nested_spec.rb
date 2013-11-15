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
        form_model = form_class.new( 
          :mailing_address_form_initializer => lambda { { :address => OpenStruct.new } } 
        )
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
        
        it "allows nested_forms to be built" do
          form.build_mailing_addresses
          form.mailing_addresses.should be_an(Array)
          form.mailing_addresses.should_not be_empty
          form.mailing_addresses.first.should be_a(Module::DummyForm::MailingAddressesForm)
        end

        it "builds unique models" do
          # Using module here, since they initialize uniquely
          form.mailing_address_form_initializer = lambda { { :address => Module.new } } 
          form.build_mailing_address
          form.build_mailing_address
          address_1 = form.mailing_addresses.first.address
          address_2 = form.mailing_addresses.last.address
          address_1.should_not eq(address_2)
        end

        it "allows nested_forms to be built with custom initializers" do
          form.build_mailing_address(:address => OpenStruct.new(:street => "1600 Pennsylvania Ave."))
          form.mailing_addresses.first.street.should eq("1600 Pennsylvania Ave.")
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