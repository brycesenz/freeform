require 'forwardable'
require 'ostruct'
require 'active_model'
require 'freeform/form/form_input_key'
require 'freeform/form/model'
require 'freeform/form/nested'
require 'freeform/form/property'
require 'freeform/form/validation'

module FreeForm
  class FormInvalid < StandardError; end
  class Form
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include FreeForm::FormInputKey
    include FreeForm::Model
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

    def save(*args)
      if valid?
        before_save
        persist_models
        reload_models
        after_save
        true
      else
        false
      end
    end

    def save!(*args)
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

    def before_save
    end

    def after_save
    end

  private
    def initialize_child_models
      self.class.child_models.each do |c|
        send("initialize_#{c}")
      end
    end

    def persist_models
      models.each { |m| m.destroy if m.marked_for_destruction? }
      # We skip validation for underlying models, since we've already run our validation.
      models.each { |m| m.save(:validate => false) unless m.marked_for_destruction? }
    end

    #TODO: Come up with a test that can validate this behavior
    def reload_models
      models.each do |m| 
        unless m.marked_for_destruction?
          m.reload if m.respond_to?(:reload)
        end
      end
    end
  end
end
