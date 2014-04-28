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

    # Default Validations
    #----------------------------------------------------------------------------
    validate_nested_forms

    # Instance Methods
    #----------------------------------------------------------------------------
    # Required for ActiveModel
    def persisted?; false end

    def initialize(h={})
      h.each {|k,v| send("#{k}=",v)}
      initialize_child_models
    end


    def save
      if valid?
        models.each { |m| m.destroy if m.marked_for_destruction? }
        models.each { |m| m.save unless m.marked_for_destruction? }
        true
      else
        false
      end
    end

    def save!
      if valid?
        save
      else
        raise FreeForm::FormInvalid, "form invalid." 
      end
    end

    def destroy
      models.each { |m| m.destroy }
    end

    def marked_for_destruction?
      respond_to?(:_destroy) ? _destroy : false
    end

  private
    def initialize_child_models
      self.class.child_models.each do |c|
        send("initialize_#{c}")
      end
    end
  end
end
