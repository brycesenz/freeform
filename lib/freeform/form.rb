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

    # def save
    #   return false unless valid?

    #   self.class.models.each do |form_model|
    #     model = send(form_model)
    #     model.is_a?(Array) ? model.each { |m| m.save } : save_or_destroy(model)
    #   end
    # end

    # def save!
    #   raise FreeForm::FormInvalid, "form invalid." unless valid?

    #   self.class.models.each do |form_model|
    #     model = send(form_model)
    #     model.is_a?(Array) ? model.each { |m| m.save! } : save_or_destroy!(model)
    #   end
    # end


    def save
      return false unless valid? || marked_for_destruction?

      # Loop through nested models first, sending them the save call
      self.class.models.each do |form_model|
        model = send(form_model)
        # This is for nested models.
        if model.is_a?(Array)
          model.each { |m| m.save }
        end
      end

#      puts "Saving... #{self}"

      # After nested models are handled, save or destroy myself.
      self.class.models.each do |form_model|
        model = send(form_model)
        # This is for form models.
        unless model.is_a?(Array)
#          puts "Saving model...#{model}"
          if model.is_a?(Project)
            # puts "All Tasks = #{Task.all}"
            # puts "Tasks = #{model.tasks.inspect}"
          end
          if marked_for_destruction?
            # puts "destroying model...#{model}"
            model.destroy
          else
            model.save
          end
        end
      end
    end

    def save!
      raise FreeForm::FormInvalid, "form invalid." unless valid?

      # Destroy all marked-for-destruction models

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
