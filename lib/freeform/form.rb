require 'forwardable'
require 'ostruct'
require 'active_model'
require 'freeform/form/form_input_key'
require 'freeform/form/nested'
require 'freeform/form/persistence'
require 'freeform/form/property'

module FreeForm
  class Form
    extend Forwardable
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include FreeForm::FormInputKey
    include FreeForm::Nested
    include FreeForm::Persistence
    include FreeForm::Property

    # Instance Methods
    #----------------------------------------------------------------------------
    # Required for ActiveModel
    def persisted?
      false
    end

    def initialize(h={})
      h.each {|k,v| send("#{k}=",v)}
    end  
  end
end