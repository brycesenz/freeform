require 'freeform/form/date_params_filter'

module FreeForm
  module Property
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Forwardable

      # Models
      #------------------------------------------------------------------------
      # def models
      #   @models ||= []
      # end

      # def child_models
      #   @child_models ||= []
      # end

      # def declared_models(*names)
      #   names.each do |name|
      #     declared_model(name)
      #   end
      # end
      # alias_method :form_models, :declared_models

      # def declared_model(name, opts={})
      #   attr_accessor name
      #   @models = (@models || []) << name
      # end
      # alias_method :form_model, :declared_model

      # def child_model(name, opts={}, &block)
      #   declared_model(name)
      #   @child_models = (@child_models || []) << name

      #   # Defines an initializer method, such as 'initialize_address' 
      #   #  that can be called on form initialization to build the model
      #   define_method("initialize_#{name}") do
      #     instance_variable_set("@#{name}", instance_eval(&block))
      #   end
      # end

      # Properties
      #------------------------------------------------------------------------
      def property_mappings
        # Take the form of {:property => {:model => model, :field => field, :ignore_blank => false}}
        @property_mappings ||= Hash.new
      end

      def allow_destroy_on_save
        # Define _destroy method for marked-for-destruction handling
        attr_accessor :_destroy
        define_method(:_destroy=) do |value|
          false_values  = [nil, 0 , false, "0", "false"]
          true_values  = [1 , true, "1", "true"]

          #TODO: Test this!!
          @_destroy = !false_values.include?(value)  # Mark initially
          # if (@_destroy == false) # Can only switch if false
          #   @_destroy = true if true_values.include?(value)
          # end
        end
        alias_method :marked_for_destruction?, :_destroy
        define_method(:mark_for_destruction) do
          @_destroy = true
        end
      end

      def property(attribute, options={})
        @property_mappings ||= Hash.new
        model = options[:on] ? options [:on] : :self
        field = options[:as] ? options[:as] : attribute.to_sym
        ignore_blank = options[:ignore_blank] ? options[:ignore_blank] : false
        @property_mappings.merge!({field => {:model => model, :field => attribute.to_sym, :ignore_blank => ignore_blank}})

        if model == :self
          attr_accessor attribute
        else
          define_method("#{field}") do
            send("#{model}").send("#{attribute}")
          end

          define_method("#{field}=") do |value|
            send("#{model}").send("#{attribute}=", value)
          end
        end
      end
    end

    # Instance Methods
    # def models
    #   Array.new.tap do |a|
    #     self.class.models.each do |form_model|
    #       a << send(form_model)
    #     end
    #     a.flatten!
    #   end
    # end

    def assign_params(params)
      self.tap do |s|
        FreeForm::DateParamsFilter.new.call(params)
        params.each_pair do |attribute, value|
          assign_attribute(attribute, value)
        end
      end
    end
    alias_method :assign_attributes, :assign_params
    alias_method :populate, :assign_params
    alias_method :fill, :assign_params

  private
    def assign_attribute(attribute, value)
      self.send :"#{attribute}=", value unless ignore?(attribute, value)
    end

    def ignore?(attribute, value)
      mapping = self.class.property_mappings[attribute.to_sym]
      return (mapping[:ignore_blank] && value.blank?) unless mapping.nil?
    end
  end
end
