require 'freeform/form/date_params_filter'

module FreeForm
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Forwardable

      def models
        @models ||= []
      end

      def child_models
        @child_models ||= []
      end

      def declared_models(*names)
        names.each do |name|
          declared_model(name)
        end
      end
      alias_method :form_models, :declared_models

      def declared_model(name, opts={})
        attr_accessor name
        @models = (@models || []) << name
      end
      alias_method :form_model, :declared_model

      def child_model(name, opts={}, &block)
        declared_model(name)
        @child_models = (@child_models || []) << name

        # Defines an initializer method, such as 'initialize_address' 
        #  that can be called on form initialization to build the model
        define_method("initialize_#{name}") do
          instance_variable_set("@#{name}", instance_eval(&block))
        end
      end
    end

    def models
      Array.new.tap do |a|
        self.class.models.each do |form_model|
          a << send(form_model)
        end
        a.flatten!
      end
    end

  private
  end
end
