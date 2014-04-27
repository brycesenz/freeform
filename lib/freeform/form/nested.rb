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
        # Initialize the instance variables on the parent class
        initialize_instance_variables(attribute)

        # Define new nested class
        klass = define_nested_class(attribute, options, &block)

        # Define methods for working with nested models
        define_nested_model_methods(attribute, klass)
      end
      alias_method :has_many, :nested_form
      alias_method :has_one, :nested_form

    protected
      def initialize_instance_variables(attribute)
        declared_model attribute

        define_method(:"#{attribute}") do
          value = instance_variable_get("@nested_#{attribute}")
          value ||= []
          instance_variable_set("@nested_#{attribute}", value)
        end
      end

      def register_nested_form(klass)
        @nested_forms ||= []
        @nested_forms << klass
      end

      def parent_class
        self
      end

      def attribute_to_form_class(attribute)
        singularized_attribute(attribute).camelize
      end

      def define_nested_class(attribute, options={}, &block)
        # Define new nested class
        klass = Class.new(FreeForm::Form) do
        end

        # Add whatever passed in methods, properties, etc. to the class
        if block_given?
          klass.class_eval(&block)
        end

        # Set the class name
        form_class = attribute_to_form_class(attribute)
        parent_class.const_set(form_class, klass)

        # Register the class as being nested under the current class
        register_nested_form(klass)
        klass
      end

      def define_nested_model_methods(attribute, form_class, options={})
        singular = singularized_attribute(attribute)

        # Example: form.build_addresses (optional custom initializer)
        define_method(:"build_#{attribute}") do |initializer=nil|
          initializer ||= self.send("#{singular}_initializer")

          form_class.new(initializer).tap do |obj|
            # Add new object to parent model collection (e.g. the new address is in parent.addresses)
            current_models = self.send(attribute)
            current_models ||= []
            current_models << obj
            self.send("#{attribute}=", current_models)
          end
        end
        alias_method :"build_#{singular}", :"build_#{attribute}"

        # Define methods for working with nested models
        define_nested_attribute_methods(attribute, form_class)
      end

      def singularized_attribute(attribute)
        attribute.to_s.singularize
      end

      #TODO: Clean up this method!
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
    #TODO: Clean up this method!
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
