require 'forwardable'
require 'ostruct'
require 'active_model'
require 'freeform/form/form_input_key'
require 'freeform/form/nested'
require 'freeform/form/property'
require 'freeform/form/validation'

module FreeForm
  class Form
    extend Forwardable
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include FreeForm::FormInputKey
    include FreeForm::Nested
    include FreeForm::Property
    include FreeForm::Validation

    # Instance Methods
    #----------------------------------------------------------------------------
    # Required for ActiveModel
    def persisted?
      false
    end

    # Define _destroy method for marked-for-destruction handling
    attr_accessor :_destroy
    alias_method :marked_for_destruction, :_destroy

    def initialize(h={})
      h.each {|k,v| send("#{k}=",v)}
    end  
    
    def save
      return false unless valid?
      return nested_save
    end
  
    def save!
      raise StandardError, "form invalid." unless valid?
      return nested_save!
    end    
    
    private
    def nested_save
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each { |model| return model.save }
        else
          if marked_for_destruction
            send(form_model).destroy
          else
            return false unless send(form_model).save
          end
        end
      end
      return true
    end
    
    def nested_save!
      self.class.models.each do |form_model|
        if send(form_model).is_a?(Array)
          send(form_model).each { |model| model.save! }
        else
          if marked_for_destruction
            send(form_model).destroy
          else
            send(form_model).save!
          end
        end
      end
    end
  end
end