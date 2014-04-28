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
      models.each { |m| validate_nested_form(m) if m.is_a?(FreeForm::Form) }
    end

    def validate_component_models
      models.each { |m| validate_model(m) unless m.is_a?(FreeForm::Form) }
    end

  private
    def validate_nested_form(form)
      errors.add(:base, "has invalid nested forms") unless marked_for_destruction_or_valid?(form)
    end

    def validate_model(model)
      model.valid?
      add_model_errors_to_form(model)
    end

    def marked_for_destruction_or_valid?(form)
      form_marked_for_destruction?(form) || form.valid?
    end

    def form_marked_for_destruction?(form)
      form.respond_to?(:marked_for_destruction?) ? form.marked_for_destruction? : false
    end

    def add_model_errors_to_form(model)
      model.errors.each do |error, message|
        add_error_to_form(model, error, message)
      end
    end

    def add_error_to_form(model, error, message)
      field = find_form_field_from_model_field(model, error)
      if field
        errors.add(field, message)
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
      models_as_symbols.find { |sym| return sym if send(sym) == model }
    end

    def models_as_symbols
      self.class.models.map { |x| x.to_sym }
    end
  end
end
