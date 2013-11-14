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
      if valid?
        success = true
        self.class.models.each do |form_model|
          if send(form_model).is_a?(Array)
            send(form_model).each do |model|
              success = success && send(model).save
            end
          else
            success = success && send(form_model).save
          end
        end
        return success
      else
        false
      end
    end
  
    def save!
      if valid?
        self.class.models.each do |form_model|
          if send(form_model).is_a?(Array)
            send(form_model).each do |model|
              model.save!
            end
          else
            send(form_model).save!
          end
        end
      else
        raise ActiveRecord::RecordInvalid, self
      end
    end
  
    protected
    def model_validity
      model_validity = true
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each do |model|
            model_validity = validate_and_append_errors(model) && model_validity          
          end
        else
          model_validity = validate_and_append_errors(send(form_model)) && model_validity
        end
      end
      return model_validity
    end
  
    def validate_and_append_errors(model)
      return true unless model.respond_to?(:valid?)
      unless model.valid?
        model.errors.each do |error, message|
          self.errors.add(error, message)
        end
        return false
      end
      return true
    end
  end
end