require 'forwardable'
require 'ostruct'
require 'active_model'

module FreeForm
  class Form
    extend Forwardable
=begin
    extend ActiveModel::Naming
    extend ActiveModel::Callbacks
    include ActiveModel::Conversion
    include ActiveModel::Validations
=end
    # Class Meta-Methods #TODO: NOT HERE!!
    #----------------------------------------------------------------------------
    attr_accessor :initialization_params
#TODO: Reimplement this
#    validate_models
  
    # Instance Methods  #TODO: NOT HERE!!
    #----------------------------------------------------------------------------
    def initialize(params={})
      self.initialization_params = params
      # Initialize Models???
    end
  end
end