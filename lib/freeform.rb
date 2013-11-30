require 'freeform/version'
require 'freeform/form'

if defined?(Rails) # Where to include Rails specific modules...
  require 'freeform/builder/builder_mixin'
  require 'freeform/builder/builders'
  require 'freeform/builder/view_helper'
  require 'freeform/builder/engine'
end