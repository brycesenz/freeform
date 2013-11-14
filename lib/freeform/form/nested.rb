require 'freeform/form/property'

module FreeForm
  module Nested
    def self.included(base)
      base.extend(ClassMethods)
    end
        
    module ClassMethods
      attr_accessor :nested_forms      
      def nested_form(attribute, options={}, &block)
        # Define an attr_accessor for the parent class to hold this attribute
        declared_model(attribute)
        define_accessor_methods(attribute)

        # Define the new class, and set it up with a new name
        nested_form_class = Class.new(FreeForm::Form) do
          include FreeForm::Property
          self.instance_eval(&block)
        end
        self.const_set("#{attribute.to_s.camelize}Form", nested_form_class)

        @nested_forms ||= {}
        @nested_forms.merge!({:"#{attribute}" => nested_form_class})

        # Define host nested attribute handling works
        create_nested_attribute_methods(attribute, nested_form_class)

        # Define form class method
        create_form_class_method(attribute, nested_form_class)        
      end
      alias_method :has_many, :nested_form
      alias_method :has_one, :nested_form

      def reflect_on_association(key, *args)
        reflection = OpenStruct.new
        reflection.klass = self.nested_forms[key]
        reflection
      end

      protected
      def define_accessor_methods(attribute)
        define_method(:"#{attribute}") do
          @nested_attributes ||= []
        end
        
        define_method(:"build_#{attribute.to_s.singularize}") do
          form_class = self.class.nested_forms[:"#{attribute}"]
          form_model = form_class.new(send("build_mailing_address_attributes"))
          @nested_attributes ||= []
          @nested_attributes << form_model
          form_model
        end
      end

      def create_nested_attribute_methods(attribute, nested_form_class)
        # Equivalent of "address_attributes=" for "address" attribute
        define_method(:"#{attribute}_attributes=") do |params|
          # Get the difference between sets of params passed and current form objects
          num_param_models = params.length
          num_built_models = self.send(:"#{attribute}").nil? ? 0 : self.send(:"#{attribute}").length          
          additional_models_needed = num_param_models - num_built_models

          # Make up the difference by building new nested form models
          additional_models_needed.times do
            send("build_#{attribute.to_s.singularize}")
          end

          self.send(:"#{attribute}").zip(params).each do |model, params_array|
            identifier = params_array[0]
            attributes = params_array[1]
            #TODO: Check the key against id?
            model.fill(attributes)
          end
        end
      end
      
      #FIXME: Why do I need this??
      def create_form_class_method(attribute, form_class)
        define_method(:"#{attribute}_form_class") do
          self.class.nested_forms[:"#{attribute}"]
        end        
      end
    end
  end
end