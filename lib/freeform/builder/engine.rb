require 'rails'

module FreeForm
  class Engine < ::Rails::Engine
    initializer 'freeform' do |app|
      puts "BRYCE IS TOTALLY HERE"
      ActiveSupport.on_load(:action_view) do
        require "freeform/view_helper"
        class ActionView::Base
          include FreeForm::ViewHelper
        end
      end
    end
  end
end