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
      initialize_child_models
    end

    def save
      return false unless valid? || marked_for_destruction?

      # Save or destroy myself.
      self.class.models.each do |form_model|
        model = send(form_model)
        # This is for form models.
        unless model.is_a?(Array)
          if marked_for_destruction?
            model.destroy
          else
            model.save
          end
        end
      end

      # Loop through nested models sending them the save call
      self.class.models.each do |form_model|
        model = send(form_model)
        # This is for nested models.
        if model.is_a?(Array)
          model.each { |m| m.save }
        end
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
    def initialize_child_models
      self.class.child_models.each do |c|
        send("initialize_#{c}")
      end
    end

    def save_or_destroy(model)
      marked_for_destruction? ? model.destroy : model.save
    end

    def save_or_destroy!(model)
      if marked_for_destruction?
        model.destroy
      else
        model.save!
      end
    end

    def marked_for_destruction?
      respond_to?(:_destroy) ? _destroy : false
    end
  end
end
