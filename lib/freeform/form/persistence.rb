module FreeForm
  module Persistence
    def self.included(base)
      base.extend(ClassMethods)
    end
        
    module ClassMethods
      def validate_models
        validate :model_validity
      end
    end
    
    def save
      return false unless valid?
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each { |model| return model.save }
        else
          return false unless send(form_model).save
        end
      end
      return true
    end
  
    def save!
      raise StandardError, "form invalid." unless valid?
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each { |model| model.save! }
        else
          send(form_model).save!
        end
      end
    end
  
    protected
    def model_validity
      model_validity = true
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each { |model| model_validity = validate_and_append_errors(model) && model_validity }
        else
          model_validity = validate_and_append_errors(send(form_model)) && model_validity
        end
      end
      return model_validity
    end
  
    def validate_and_append_errors(model)
      unless model.valid?
        model.errors.each { |error, message| self.errors.add(error, message) }
        return false
      end
      return true
    end
  end
end