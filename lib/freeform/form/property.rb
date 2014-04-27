module FreeForm
  module Property
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Forwardable

      # Models
      #------------------------------------------------------------------------
      def models
        @models ||= []
      end

      def child_models
        @child_models ||= []
      end

      def declared_model(name, opts={})
        @models ||= []
        @models << name
        attr_accessor name
      end
      alias_method :form_model, :declared_model

      def declared_models(*names)
        names.each do |name|
          declared_model(name)
        end
      end
      alias_method :form_models, :declared_models

      def child_model(name, opts={}, &block)
        @models ||= []
        @models << name
        @child_models ||= []
        @child_models << name
        attr_accessor name
        define_method("initialize_#{name}") do
          instance_variable_set("@#{name}", instance_eval(&block))
        end
      end

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

    #TODO: DO I even use this??
    attr_accessor :parent_form

    class DateParamsFilter
      def call(params)
        date_attributes = {}

        params.each do |attribute, value|
          if value.is_a?(Hash)
            call(value) # TODO: #validate should only handle local form params.
          elsif matches = attribute.match(/^(\w+)\(.i\)$/)
            date_attribute = matches[1]
            date_attributes[date_attribute] = params_to_date(
              params.delete("#{date_attribute}(1i)"),
              params.delete("#{date_attribute}(2i)"),
              params.delete("#{date_attribute}(3i)")
            )
          end
        end
        params.merge!(date_attributes)
      end

    private
      def params_to_date(year, month, day)
        day ||= 1 # FIXME: is that really what we want? test.
        begin # TODO: test fails.
          return Date.new(year.to_i, month.to_i, day.to_i)
        rescue ArgumentError => e
          return nil
        end
      end
    end

    def assign_params(params)
      DateParamsFilter.new.call(params)
      params.each_pair do |attribute, value|
        assign_attribute(attribute, value)
      end
      self
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
