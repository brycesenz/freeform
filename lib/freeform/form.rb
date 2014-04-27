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
      return false unless valid?

      # Destroy all marked for destruction first
      models.each do |m|
        m.destroy if m.marked_for_destruction?
      end

      # Then, persist all models
      models.each do |m|
        m.save unless m.marked_for_destruction?
      end

      return true
    end

    def save!
      raise FreeForm::FormInvalid, "form invalid." unless valid?
      save
    end

    def destroy
      models.each do |m|
        m.destroy
      end
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
