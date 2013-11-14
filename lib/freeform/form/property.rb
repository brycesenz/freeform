module FreeForm
  module Property
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def declared_model(name, opts={})
        @models ||= []
        @models << name        
        attr_accessor name
#        if opts[:allow_destroy]
#          attr_accessor :"_#{name}_destroy"
#        end
      end
      
      def declared_models(*names)
        names.each do |name|
          declared_model(name)
        end
      end

      def form_model(name, options={}, &block)
        declared_model(name)
      end
    end
  end
end