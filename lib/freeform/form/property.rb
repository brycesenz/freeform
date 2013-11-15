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

      # Properties
      #------------------------------------------------------------------------
      def ignored_blank_params
        @ignored_blank_params ||= []
      end

      def allow_destroy_on_save
        # Define _destroy method for marked-for-destruction handling
        attr_accessor :_destroy
        alias_method :marked_for_destruction, :_destroy
      end

      def property(attribute, options={})
        if options[:on]
          def_delegator options[:on], attribute
          def_delegator options[:on], "#{attribute}=".to_sym
        else
          attr_accessor attribute
        end
        @ignored_blank_params ||= []
        @ignored_blank_params << attribute if options[:ignore_blank]
      end
    end

    def assign_params(params)
      filter_dates(params)
      params.each_pair do |attribute, value|
        self.send :"#{attribute}=", value unless ignore?(attribute, value)
      end
      self
    end
    alias_method :assign_attributes, :assign_params
    alias_method :populate, :assign_params
    alias_method :fill, :assign_params
    
    def ignore?(attribute, value)
      ignored_if_blank = self.class.ignored_blank_params
      return (ignored_if_blank.include?(attribute.to_sym) && value.blank?)
    end

    private
    #TODO: This should be its own model
    def filter_dates(params)
      date_attributes = {}
      params.each do |attribute, value|
        if attribute.to_s.include?("(1i)") || attribute.to_s.include?("(2i)") || attribute.to_s.include?("(3i)")
          date_attribute = attribute.to_s.gsub(/(\(.*\))/, "")
          date_attributes[date_attribute.to_sym] = params_to_date(
            params.delete("#{date_attribute}(1i)"),
            params.delete("#{date_attribute}(2i)"),
            params.delete("#{date_attribute}(3i)")
          )        
        end
      end
      params.merge!(date_attributes)
    end
    
    def params_to_date(year, month, day)
      day ||= 1
      begin
        return Date.new(year.to_i, month.to_i, day.to_i)
      rescue => e
        return nil
      end
    end
  end
end