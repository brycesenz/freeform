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
      self.class.models.each do |form_model|
        model = send(form_model)
        if model.is_a?(Array)
          model.each { |m| m.save }
        else
          persist_or_destroy(model)
        end
      end
    end

    def save!
      raise FreeForm::FormInvalid, "form invalid." unless valid?
      save
    end

    def destroy
      self.class.models.each do |form_model|
        model = send(form_model)
        if model.is_a?(Array)
          model.each { |m| m.destroy }
        else
          model.destroy
        end
      end
    end

  private
    def initialize_child_models
      self.class.child_models.each do |c|
        send("initialize_#{c}")
      end
    end

    def marked_for_destruction?
      respond_to?(:_destroy) ? _destroy : false
    end

    def persist_or_destroy(model)
      # if model.marked_for_destruction?
      #   model.destroy
      # else
      #   model.save
      # end
    end
  end
end
