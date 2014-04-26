require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'

describe FreeForm::Nested do
  describe "has_many", :has_many => true do
    let!(:nested_class) do
      klass = Class.new(Module) do
        include FreeForm::Property
        include FreeForm::Nested
        declared_model :address
        
        property :street, :on => :address            
        
        def initialize(h={})
          h.each {|k,v| send("#{k}=",v)}
        end  
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("MailingAddressForm", klass)
      $VERBOSE = v
      klass
    end

    let!(:second_nested_class) do
      klass = Class.new(Module) do
        include FreeForm::Property
        include FreeForm::Nested
        declared_model :phone
        
        property :number, :on => :phone
        
        def initialize(h={})
          h.each {|k,v| send("#{k}=",v)}
        end  
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("PhoneNumberForm", klass)
      $VERBOSE = v
      klass
    end

    let(:form_class) do
      klass = Class.new(Module) do
        include FreeForm::Property
        include FreeForm::Nested
        
        def initialize(h={})
          h.each {|k,v| send("#{k}=",v)}
        end  
        
        has_many :mailing_addresses, :class => Module::MailingAddressForm, :default_initializer => :mailing_address_initializer
        def mailing_address_initializer
          { :address => OpenStruct.new(:id => Random.new.rand(1000000)) }
        end

        has_many :phone_numbers, :class => Module::PhoneNumberForm, :default_initializer => :phone_number_initializer
        def phone_number_initializer
          { :phone => OpenStruct.new(:id => Random.new.rand(1000000)) }
        end
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("DummyForm", klass)
      $VERBOSE = v
      klass
    end

    let(:form) do
      form_model = form_class.new
    end

    describe "form class" do
      it "sets nested_form in models" do
        form_class.models.should eq([:mailing_addresses, :phone_numbers])
      end
    end
    
    describe "building nested models" do
      it "initializes with no nested models prebuilt" do
        form.mailing_addresses.should eq([])
        form.phone_numbers.should eq([])
      end
      
      context "with default initializer" do
        context "for mailing addresses" do
          it "allows nested_forms to be built" do
            form.build_mailing_addresses
            form.mailing_addresses.should be_an(Array)
            form.mailing_addresses.should_not be_empty
            form.mailing_addresses.first.should be_a(Module::MailingAddressForm)
          end
    
          it "does not add to other has_many array" do
            form.build_mailing_addresses
            form.phone_numbers.should eq([])
          end

          it "builds unique models" do
            form = form_class.new
            form.build_mailing_address
            form.build_mailing_address
            address_1 = form.mailing_addresses.first.address
            address_2 = form.mailing_addresses.last.address
            address_1.should_not eq(address_2)
          end
        end

        context "for phone numbers" do
          it "allows nested_forms to be built" do
            form.build_phone_number
            form.phone_numbers.should be_an(Array)
            form.phone_numbers.should_not be_empty
            form.phone_numbers.first.should be_a(Module::PhoneNumberForm)
          end
    
          it "does not add to other has_many array" do
            form.build_phone_numbers
            form.mailing_addresses.should eq([])
          end

          it "builds unique models" do
            form = form_class.new
            form.build_phone_number
            form.build_phone_number
            phone_1 = form.phone_numbers.first.phone
            phone_2 = form.phone_numbers.last.phone
            phone_1.should_not eq(phone_2)
          end
        end
      end
      
      context "with custom initializer" do
        it "allows nested_forms to be built" do
          form.build_mailing_addresses(:address => OpenStruct.new)
          form.mailing_addresses.should be_an(Array)
          form.mailing_addresses.should_not be_empty
          form.mailing_addresses.first.should be_a(Module::MailingAddressForm)
        end
        
        it "allows nested_forms to be built with custom initializers" do
          form.build_mailing_address(:address => OpenStruct.new(:street => "1600 Pennsylvania Ave."))
          form.mailing_addresses.first.street.should eq("1600 Pennsylvania Ave.")
        end
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