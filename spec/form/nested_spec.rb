require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'

describe FreeForm::Nested do
  let(:form_class) do
    klass = Class.new(Module) do
      include FreeForm::Property
      include FreeForm::Nested
      
      def initialize(h={})
        h.each {|k,v| send("#{k}=",v)}
      end  
      
      has_many :mailing_addresses, :default_initializer => :mailing_address_initializer do
        declared_model :address
      
        def initialize(h={})
          h.each {|k,v| send("#{k}=",v)}
        end  

        property :street, :on => :address            
      end

      def mailing_address_initializer
        { :address => OpenStruct.new(:id => Random.new.rand(1000000)) }
      end

      has_many :phone_numbers, :default_initializer => :phone_number_initializer do
        declared_model :phone
        
        def initialize(h={})
          h.each {|k,v| send("#{k}=",v)}
        end  

        property :number, :on => :phone        
      end

      def phone_number_initializer
        { :phone => OpenStruct.new(:id => Random.new.rand(1000000)) }
      end
    end
    # This wrapper just avoids CONST warnings
    v, $VERBOSE = $VERBOSE, nil
      Module.const_set("ParentForm", klass)
    $VERBOSE = v
    klass
  end

  let(:form) do
    form_model = form_class.new
  end

  describe "form class" do
    it "has correct class" do
      form.should be_a(Module::ParentForm)
    end

    it "has nested forms" do
      form_class.nested_forms.should eq([Module::ParentForm::MailingAddress, Module::ParentForm::PhoneNumber])
    end

    describe "mailing address nested form class" do
      let(:nested_form) { form_class.nested_forms.first.new }

      it "should be a MailingAddress object" do
        nested_form.should be_a(Module::ParentForm::MailingAddress)
      end

      it "should respond to property methods" do
        nested_form.should respond_to(:street)
      end
    end

    describe "phone number nested form class" do
      let(:nested_form) { form_class.nested_forms.last.new }

      it "should be a PhoneNumber object" do
        nested_form.should be_a(Module::ParentForm::PhoneNumber)
      end

      it "should respond to property methods" do
        nested_form.should respond_to(:number)
      end
    end
  end
  
  describe "building nested models" do
    # it "initializes with no nested models prebuilt" do
    #   form.mailing_addresses.should eq([])
    #   form.phone_numbers.should eq([])
    # end
    
    # context "with default initializer" do
    #   context "for mailing addresses" do
    #     it "allows nested_forms to be built" do
    #       form.build_mailing_addresses
    #       form.mailing_addresses.should be_an(Array)
    #       form.mailing_addresses.should_not be_empty
    #       form.mailing_addresses.first.should be_a(Module::MailingAddressForm)
    #     end
  
    #     it "does not add to other has_many array" do
    #       form.build_mailing_addresses
    #       form.phone_numbers.should eq([])
    #     end

    #     it "builds unique models" do
    #       form = form_class.new
    #       form.build_mailing_address
    #       form.build_mailing_address
    #       address_1 = form.mailing_addresses.first.address
    #       address_2 = form.mailing_addresses.last.address
    #       address_1.should_not eq(address_2)
    #     end
    #   end

    #   context "for phone numbers" do
    #     it "allows nested_forms to be built" do
    #       form.build_phone_number
    #       form.phone_numbers.should be_an(Array)
    #       form.phone_numbers.should_not be_empty
    #       form.phone_numbers.first.should be_a(Module::PhoneNumberForm)
    #     end
  
    #     it "does not add to other has_many array" do
    #       form.build_phone_numbers
    #       form.mailing_addresses.should eq([])
    #     end

    #     it "builds unique models" do
    #       form = form_class.new
    #       form.build_phone_number
    #       form.build_phone_number
    #       phone_1 = form.phone_numbers.first.phone
    #       phone_2 = form.phone_numbers.last.phone
    #       phone_1.should_not eq(phone_2)
    #     end
    #   end
    # end
  end
  
  describe "setting attributes" do
    # describe "nested attribute assignment" do
    #   let(:attributes) do
    #     { :mailing_addresses_attributes => { "0" => { :street => "123 Main St." } } }
    #   end

    #   it "assigns nested attributes" do
    #     form.fill(attributes)
    #     form.mailing_addresses.first.street.should eq("123 Main St.")
    #   end
    # end
  end      
end