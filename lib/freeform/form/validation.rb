module FreeForm
  module Validation
    def self.included(base)
      base.extend(ClassMethods)
      extend FreeForm::Property
    end

    module ClassMethods
      def validate_nested_forms
        validate :validate_nested_forms
      end

      def validate_models
        validate :validate_component_models
      end
    end

  protected
    def validate_nested_forms
      models.each do |model|
        # Validate nested form models
        if model.is_a?(FreeForm::Form)
          errors.add(:base, "has invalid nested forms") unless validate_nested_form(model)
        end
      end
    end

    def validate_component_models
      models.each do |model|
        # Validate non-nested models
        unless model.is_a?(FreeForm::Form)
          validate_model(model)
        end
      end
    end

  private
    def validate_nested_form(nested_form_model)
      (form_marked_for_destruction?(nested_form_model) || nested_form_model.valid?)
    end

    def form_marked_for_destruction?(form)
      form.respond_to?(:marked_for_destruction?) ? form.marked_for_destruction? : false
    end

    def validate_model(model)
      model.valid?

      model.errors.each do |error, message|
        field = find_form_field_from_model_field(model, error)
        if field
          errors.add(field, message)
        end
      end
    end

    def find_form_field_from_model_field(model, error_field)
      model_property_mappings.each_pair do |property, attributes|
        model_sym = model_symbol_from_model(model)
        field_sym = error_field.to_sym

        if (attributes[:model] == model_sym) && (attributes[:field] == field_sym)
          return property
        end
      end
      nil
    end

    def model_symbol_from_model(model)
      self.class.models.each do |model_sym|
        if send(model_sym.to_sym) == model
          return model_sym.to_sym
        end
      end
      nil
    end

    #TODO: This should be a part of the property module.
    def model_property_mappings
      self.class.property_mappings
    end
  end
end
