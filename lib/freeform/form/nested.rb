require 'freeform/form/property'

module FreeForm
  module Nested
    def self.included(base)
      base.extend(ClassMethods)
    end
        
    module ClassMethods
      # Nested Forms
      #------------------------------------------------------------------------
      attr_accessor :nested_forms

      def nested_form(attribute, options={}, &block)
        # Specify the class method on which we're defining the initializer for this form.
        parent_class = self

        # Define an attr_accessor for the parent class to hold this attribute
        declared_model(attribute)

        # Define the new class, and set it up with a new name
        nested_form_class = Class.new(parent_class) do
          self.instance_eval(&block)
        end
        self.const_set("#{attribute.to_s.camelize}Form", nested_form_class)

        @nested_forms ||= {}
        @nested_forms.merge!({:"#{attribute}" => nested_form_class})

        # Defined other methods
        define_nested_model_methods(attribute, nested_form_class, options)

        # Setup Handling for nested attributes
        define_nested_attribute_methods(attribute, nested_form_class)
      end
      alias_method :has_many, :nested_form
      alias_method :has_one, :nested_form

      protected
      # Defining Helper Methods For Models
      #------------------------------------------------------------------------
      def define_nested_model_methods(attribute, form_class, options={})
        singularized_attribute = attribute.to_s.singularize.to_s

        # Example: form.addresses will return all nested address forms 
        define_method(:"#{attribute}") do
          @nested_attributes ||= []
        end
        
        # Example: form.build_addresses (optional custom initializer)
        define_method(:"build_#{attribute}") do |initializer=nil|
          # Builder object
          parent_object = self
          
          # Get correct class
          form_class = self.class.nested_forms[:"#{attribute}"]
          
          # Initializer
          initializer ||= instance_eval(&options[:default_initializer])

          # Build new model
          form_model = form_class.new(initializer)
          @nested_attributes ||= []
          @nested_attributes << form_model
          form_model
        end
        alias_method :"build_#{singularized_attribute}", :"build_#{attribute}"
      end

      # Defining Helper Methods For Nested Attributes
      #------------------------------------------------------------------------
      def define_nested_attribute_methods(attribute, nested_form_class)
        # Equivalent of "address_attributes=" for "address" attribute
        define_method(:"#{attribute}_attributes=") do |params|
          build_models_from_param_count(attribute, params)

          self.send(:"#{attribute}").zip(params).each do |model, params_array|
            identifier = params_array[0]
            attributes = params_array[1]
            #TODO: Check the key against id?
            model.fill(attributes)
          end
        end
      end
    end

    # Instance Methods
    #--------------------------------------------------------------------------
    protected
    def build_models_from_param_count(attribute, params)
      # Get the difference between sets of params passed and current form objects
      num_param_models = params.length
      num_built_models = self.send(:"#{attribute}").nil? ? 0 : self.send(:"#{attribute}").length          
      additional_models_needed = num_param_models - num_built_models

      # Make up the difference by building new nested form models
      additional_models_needed.times do
        send("build_#{attribute.to_s}")
      end
    end
  end
end