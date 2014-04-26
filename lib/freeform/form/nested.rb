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
      end
      alias_method :has_many, :nested_form
      alias_method :has_one, :nested_form

    protected
      def register_nested_form(klass)
        @nested_forms ||= []
        @nested_forms << klass
      end

      def parent_class
        self
      end

      def attribute_to_form_class(attribute)
        attribute.to_s.singularize.camelize
      end
    end

    # Instance Methods
    #--------------------------------------------------------------------------
  protected
  end
end
