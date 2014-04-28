require 'freeform/form/date_params_filter'

module FreeForm
  module Property
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Forwardable

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

    def assign_params(params)
      self.tap do |s|
        FreeForm::DateParamsFilter.new.call(params)
        before_assign_params(params)
        params.each_pair do |attribute, value|
          assign_attribute(attribute, value)
        end
        after_assign_params(params)
      end
    end
    alias_method :assign_attributes, :assign_params
    alias_method :populate, :assign_params
    alias_method :fill, :assign_params

    def before_assign_params(params)
    end
    alias_method :before_assign_attributes, :before_assign_params
    alias_method :before_populate, :before_assign_params
    alias_method :before_fill, :before_assign_params

    def after_assign_params(params)
    end
    alias_method :after_assign_attributes, :after_assign_params
    alias_method :after_populate, :after_assign_params
    alias_method :after_fill, :after_assign_params

    def model_property_mappings
      self.class.property_mappings
    end

  private
    def assign_attribute(attribute, value)
      self.send :"#{attribute}=", value unless ignore?(attribute, value)
    end

    def ignore?(attribute, value)
      mapping = model_property_mappings[attribute.to_sym]
      if mapping.present?
        mapping[:ignore_blank] && value.blank?
      else
        false
      end
    end
  end
end
