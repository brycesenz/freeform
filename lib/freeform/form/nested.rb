require 'freeform/form/property'

module FreeForm
  module Nested
    def self.included(base)
      base.extend(ClassMethods)
    end
        
    module ClassMethods
      attr_accessor :nested_models
      attr_accessor :has_many_forms
      
      def has_many(attribute, options={}, &block)
        # Define an attr_accessor for the parent class to hold this attribute
        declared_model(attribute)
        define_accessor_methods(attribute)

        # Define the new class, and set it up with a new name
        nested_form_class = Class.new(FreeForm::Form) do
          include FreeForm::Property
          self.instance_eval(&block)
        end
        self.const_set("#{attribute.to_s.camelize}Form", nested_form_class)

        # Add this new form to our has_many_forms attribute
        register_form(attribute, nested_form_class)

        # Define host nested attribute handling works
        create_nested_attribute_methods(attribute, nested_form_class)

        # Define form class method
        create_form_class_method(attribute, nested_form_class)        
      end

      def reflect_on_association(key, *args)
        reflection = OpenStruct.new
        reflection.klass = self.has_many_forms[key]
        reflection
      end

      protected
      def register_form(attribute, form_class)
        @has_many_forms ||= {}
        @has_many_forms.merge!({:"#{attribute}" => form_class})       
      end

      def define_accessor_methods(attribute)
        define_method(:"#{attribute}") do
          @nested_attributes
        end
        
        define_method(:"add_#{attribute.to_s.singularize}") do |model|
          @nested_attributes ||= []
          @nested_attributes << model
        end
      end

      def create_nested_attribute_methods(attribute, nested_form_class)
        # Equivalent of "address_attributes" for "address" attribute
        define_method(:"#{attribute}_attributes") do
        end

        # Equivalent of "address_attributes=" for "address" attribute
        define_method(:"#{attribute}_attributes=") do |params|
          # Get the difference between sets of params passed and current form objects
          additional_models_needed = params.length - self.send(:"#{attribute}").length

          # Make up the difference by building new nested form models
          additional_models_needed.times do
            send(:"add_#{attribute.to_s.singularize}", send(:"build_#{attribute.to_s.singularize}"))
          end

          self.send(:"#{attribute}").zip(params).each do |model, params_array|
            identifier = params_array[0]
            attributes = params_array[1]
            #TODO: Check the key against id?
            model.fill(attributes)
          end
        end
      end
      
      def create_form_class_method(attribute, form_class)
        define_method(:"#{attribute}_form_class") do
          self.class.has_many_forms[:"#{attribute}"]
        end        
      end
    end
  end
end