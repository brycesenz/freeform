require 'spec_helper'

describe FreeForm::Validation do
  let(:user) do
    model = Class.new(Module) do
      include ActiveModel::Validations
      def self.model_name; ActiveModel::Name.new(self, nil, "user") end

      attr_accessor :username
      validates :username, :presence => true

      def save; return valid? end
      alias_method :save!, :save
    end.new
    model
  end

  let(:address) do
    model = Class.new(Module) do
      include ActiveModel::Validations
      def self.model_name; ActiveModel::Name.new(self, nil, "address") end

      attr_accessor :street
      attr_accessor :city
      validates :street, :presence => true

      def save; return valid? end
      alias_method :save!, :save
    end.new
    model
  end

  context "without model validation", :without_validation => true do
    let(:form_class) do
      klass = Class.new(Module) do
        include ActiveModel::Validations
        include FreeForm::Property
        include FreeForm::Nested
        include FreeForm::Validation
        form_model :user
        property :username, :on => :user
        validates :username, :presence => true
        
        nested_form :addresses do
          declared_model :address          
          property :street, :on => :address
        end
        
        def address_initializer
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
      form_class.new(:user => user).tap do |f|
        f.build_address
      end
    end

    it "is not valid initially" do
      form.should_not be_valid
    end

    it "has error on :username" do
      form.valid?
      form.errors[:username].should eq(["can't be blank"])
    end

    it "does not have errors on address" do
      form.valid?
      form.addresses.first.errors.should be_empty
    end
  end

  context "with model validation", :model_validation => true do
    let(:form_class) do
      klass = Class.new(Module) do
        include ActiveModel::Validations
        include FreeForm::Property
        include FreeForm::Nested
        include FreeForm::Validation
        form_model :user
        validate_models
        property :username, :on => :user
        property :form_property

        validates :form_property, :presence => true
        
        nested_form :addresses do
          declared_model :address          
          validate_models
          property :street, :on => :address
        end
        
        def address_initializer
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
      form_class.new( :user => user ).tap do |f|
        f.build_address( :address => address )
      end
    end

    it "is not valid initially" do
      form.should_not be_valid
    end

    it "has error on :username" do
      form.valid?
      form.errors[:username].should eq(["can't be blank"])
    end

    it "has error on :form_property" do
      form.valid?
      form.errors[:form_property].should eq(["can't be blank"])
    end

    it "has error on address street" do
      form.valid?
      form.addresses.first.errors[:street].should eq(["can't be blank"])
    end
  end
end