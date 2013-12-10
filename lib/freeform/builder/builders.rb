require 'action_view'
require 'freeform/builder/builder_mixin'

module FreeForm
  class Builder < ::ActionView::Helpers::FormBuilder
    include ::FreeForm::BuilderMixin
  end

  begin
    require 'simple_form'
    class SimpleBuilder < ::SimpleForm::FormBuilder
      include ::FreeForm::BuilderMixin
    end
  rescue LoadError
  end

  begin
    require 'formtastic'
    class FormtasticBuilder < (defined?(::Formtastic::FormBuilder) ? Formtastic::FormBuilder : ::Formtastic::SemanticFormBuilder)
      include ::FreeForm::BuilderMixin
    end
  rescue LoadError
  end

  begin
    require 'formtastic-bootstrap'
    class FormtasticBootstrapBuilder < ::FormtasticBootstrap::FormBuilder
      include ::FreeForm::BuilderMixin
    end
  rescue LoadError
  end
end