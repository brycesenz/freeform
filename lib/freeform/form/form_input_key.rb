module FreeForm
  module FormInputKey
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def form_input_key(name)
        constant = name.to_s.camelize
        define_singleton_method(:model_name) do
          ActiveModel::Name.new(self, nil, constant)
        end
      end
    end
  end
end
