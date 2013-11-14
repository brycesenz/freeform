require 'spec_helper'
require 'freeform/form/property'
require 'freeform/form/nested'
require 'freeform/form/persistence'

describe FreeForm::Persistence do
  describe "validation", :validation => true do    
    context "without model validation" do
      let(:form_class) do
        klass = Class.new(Module) do
          include ActiveModel::Validations
          include FreeForm::Property
          include FreeForm::Nested
          include FreeForm::Persistence

          form_model :user
          property :username, :on => :user
          validates :username, :presence => true
          
          nested_form :addresses do
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
        test_form = form_class.new( :user => OpenStruct.new, :address_form_initializer => { :address => OpenStruct.new } )
        test_form.build_address
        test_form
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

    context "with model validation" do
      let(:user) do
        model = Class.new(Module) do
          include ActiveModel::Validations
          def self.model_name; ActiveModel::Name.new(self, nil, "user") end

          attr_accessor :username
          validates :username, :presence => true
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
        end.new
        model
      end

      let(:form_class) do
        klass = Class.new(Module) do
          include ActiveModel::Validations
          include FreeForm::Property
          include FreeForm::Nested
          include FreeForm::Persistence
          validate_models

          form_model :user
          property :username, :on => :user
          property :form_property
          validates :form_property, :presence => true
          
          nested_form :addresses do
            include ActiveModel::Validations
            include FreeForm::Property
            include FreeForm::Nested
            include FreeForm::Persistence
            validate_models
            declared_model :address
            
            property :street, :on => :address
            property :city, :on => :address
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
        test_form = form_class.new( :user => user, :address_form_initializer => { :address => address } )
        test_form.build_address
        test_form
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
end