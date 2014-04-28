require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'

describe FreeForm::Nested do
  let(:form_class) do
    klass = Class.new(Module) do
      include FreeForm::Model
      include FreeForm::Property
      include FreeForm::Nested
      
      def initialize(h={})
        h.each {|k,v| send("#{k}=",v)}
      end  
      
      has_many :mailing_addresses, :default_initializer => :mailing_address_initializer do
        declared_model :address
        property :street, :on => :address            
      end

      def mailing_address_initializer
        { :address => OpenStruct.new(:id => Random.new.rand(1000000)) }
      end

      has_many :phone_numbers, :default_initializer => :phone_number_initializer do
        declared_model :phone
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
    it "responds to mailing_addresses" do
      form.should respond_to(:mailing_addresses)
    end

    it "responds to phone_numbers" do
      form.should respond_to(:phone_numbers)
    end

    it "initializes with no nested models prebuilt" do
      form.mailing_addresses.should eq([])
      form.phone_numbers.should eq([])
    end

    describe "building new nested models" do
      it "can build new nested model" do
        form.build_mailing_address
        form.mailing_addresses.should_not be_empty
        form.mailing_addresses.first.should be_a(Module::ParentForm::MailingAddress)
      end

      it "builds unique models" do
        form.build_mailing_address
        form.build_mailing_address
        address_model_1 = form.mailing_addresses.first
        address_model_2 = form.mailing_addresses.last
        address_model_1.should_not eq(address_model_2)
        address_model_1.address.should_not eq(address_model_2.address)
      end

      it "builds with correct default initializer" do
        address_model = form.build_mailing_address
        address_model.address.should be_a(OpenStruct)
      end

      it "builds with custom initializer" do
        address_model = form.build_mailing_address({:address => Date.new})
        address_model.address.should be_a(Date)
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