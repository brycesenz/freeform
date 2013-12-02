require 'rails'

module FreeForm
  class Engine < ::Rails::Engine
    initializer 'freeform' do |app|
      ActiveSupport.on_load(:action_view) do
        require "freeform/builder/view_helper"
        class ActionView::Base
          include FreeForm::ViewHelper
        end
      end
    end
  end
end