module FreeForm
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def self.source_root
        File.expand_path('../../../../vendor/assets/javascripts', __FILE__)
      end

      def copy_jquery_file
        if File.exists?('public/javascripts/prototype.js')
          copy_file 'prototype_freeform.js', 'public/javascripts/freeform.js'
        else
          copy_file 'jquery_freeform.js', 'public/javascripts/freeform.js'
        end
      end
    end
  end
end
