require 'forwardable'
require 'ostruct'
require 'active_model'
require 'freeform/form/form_input_key'
require 'freeform/form/nested'
require 'freeform/form/property'
require 'freeform/form/validation'

module FreeForm
  class FormInvalid < StandardError; end
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
    def persisted?; false end

    def initialize(h={})
      h.each {|k,v| send("#{k}=",v)}
    end  
    
    def save
      return false unless valid?

      self.class.models.each do |form_model|
        model = send(form_model)
        model.is_a?(Array) ? model.each { |m| m.save } : save_or_destroy(model)
      end
    end
  
    def save!
      raise FreeForm::FormInvalid, "form invalid." unless valid?

      self.class.models.each do |form_model|
        model = send(form_model)
        model.is_a?(Array) ? model.each { |m| m.save! } : save_or_destroy!(model)
      end
    end    
    
  private
    def save_or_destroy(model)
      marked_for_destruction? ? model.destroy : model.save
    end
    
    def save_or_destroy!(model)
      marked_for_destruction? ? model.destroy : model.save!
    end

    def marked_for_destruction?
      respond_to?(:_destroy) ? _destroy : false
    end
  end
end