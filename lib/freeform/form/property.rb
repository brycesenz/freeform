module FreeForm
  module Property
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Forwardable

      # Models
      #------------------------------------------------------------------------
      attr_accessor :models
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
      attr_accessor :ignored_blank_params
      def property(attribute, options={})
        def_delegator options[:on], attribute
        def_delegator options[:on], "#{attribute}=".to_sym
        @ignored_blank_params ||= []
        @ignored_blank_params << attribute if options[:ignore_blank]
      end
    end

    def assign_params(params)
      #TODO: Add this method back in
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
      if (self.class.ignored_blank_params.include?(attribute.to_sym) && value.blank?)
        return true
      end
      return false
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