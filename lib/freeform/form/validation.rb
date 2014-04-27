module FreeForm
  module Validation
    def self.included(base)
      base.extend(ClassMethods)
      extend FreeForm::Property
    end

    module ClassMethods
      def validate_models
        validate :model_validity
      end
    end

  protected
    def model_validity
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          # If it's an array, we're dealing with nested forms
          errors.add(:base, "has invalid nested forms") unless validate_nested_forms(send(form_model))
        else
          # Otherwise, validate the form object
          validate_form_model(form_model)
        end
      end
    end

  private
    def validate_nested_forms(form_array)
      form_validity = true
      form_array.each do |model|
        destroyed = model.respond_to?(:marked_for_destruction?) ? model.marked_for_destruction? : false
        unless model.valid? || destroyed
          form_validity = false
        end
      end
      form_validity
    end

    def validate_form_model(form_model)
      model = send(form_model)
      append_errors(form_model)
      model.valid?
    end

    def append_errors(form_model)
      model = send(form_model)
      model.valid?
      model.errors.each do |error, message|
        if find_form_field_from_model_field(form_model, error)
          self.errors.add(find_form_field_from_model_field(form_model, error), message)
        end
      end
    end

    def find_form_field_from_model_field(model, field)
      self.class.property_mappings.each_pair do |property, attributes|
        if (attributes[:model] == model.to_sym) && (attributes[:field] == field.to_sym)
          return property
        end
      end
      false
    end
  end
end
