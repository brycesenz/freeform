require "spec_helper"

describe FreeForm::ViewHelper do
  include RSpec::Rails::HelperExampleGroup
  
  before(:each) do
    _routes.draw do
      resources :projects
    end
  end

  let(:form_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :project
      form_models :project
      allow_destroy_on_save
      
      property :name, :on => :project

      has_many :tasks, :class_initializer => :task_initializer do
        form_model :task
        allow_destroy_on_save
        
        property :name,    :on => :task
      end
    end
    # This wrapper just avoids CONST warnings
    v, $VERBOSE = $VERBOSE, nil
      Module.const_set("ViewForm", klass)
    $VERBOSE = v
    klass
  end
  
  let(:project) { Project.new }

  let(:test_form) { form_class.new(:project => project) }

  it "should pass instance of FreeForm::Builder to freeform_for block" do
    _view.freeform_for(test_form) do |f|
      f.should be_instance_of(FreeForm::Builder)
    end
  end

  it "should pass instance of FreeForm::SimpleBuilder to simple_freeform_for block" do
    _view.simple_freeform_for(test_form) do |f|
      f.should be_instance_of(FreeForm::SimpleBuilder)
    end
  end

  if defined?(FreeForm::FormtasticBuilder)
    it "should pass instance of FreeForm::FormtasticBuilder to semantic_freeform_for block" do
      _view.semantic_freeform_for(test_form) do |f|
        f.should be_instance_of(FreeForm::FormtasticBuilder)
      end
    end
  end

  if defined?(FreeForm::FormtasticBootstrapBuilder)
    it "should pass instance of FreeForm::FormtasticBootstrapBuilder to semantic_bootstrap_freeform_for block" do
      _view.semantic_bootstrap_freeform_for(test_form) do |f|
        f.should be_instance_of(FreeForm::FormtasticBootstrapBuilder)
      end
    end
  end

  it "should append content to end of freeform" do
    _view.after_freeform(:tasks) { _view.concat("123") }
    _view.after_freeform(:milestones) { _view.concat("456") }
    result = _view.freeform_for(test_form) {}
    result.should include("123456")
  end

  if Rails.version >= "3.1.0"
    it "should set multipart when there's a file field" do
      _view.freeform_for(test_form) do |f|
        f.fields_for(:tasks) do |t|
          t.file_field :file
        end
        f.link_to_add "Add", :tasks
      end.should include(" enctype=\"multipart/form-data\" ")
    end
  end
end