module FreeForm
  module FormInputKey
    def self.included(base)
      base.extend(ClassMethods)
    end
        
    module ClassMethods
      def form_input_key(name)
        constant = name.to_s.camelize
        Object.const_set(constant, Class.new) unless Object.const_defined?(constant)    
        define_singleton_method(:model_name) do
          ActiveModel::Name.new(constant.constantize)
        end
      end
    end
  end
end