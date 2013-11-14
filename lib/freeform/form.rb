require 'forwardable'
require 'ostruct'
require 'active_model'

module FreeForm
  class Form
    extend Forwardable
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations

    # Instance Methods
    #----------------------------------------------------------------------------
    # Required for ActiveModel
    def persisted?
      false
    end

    def initialize(h)
      h.each {|k,v| send("#{k}=",v)}
    end  
  end
end