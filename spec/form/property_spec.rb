require 'spec_helper'
require 'freeform/form/property'

describe FreeForm::Property do
  describe "class methods", :class_methods => true do
    describe "models", :models => true do
      describe "declared model", :declared_model => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            declared_model :test_model_1
            declared_model :test_model_2
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model_1 => OpenStruct.new(:dummy => "yes"),
            :test_model_2 => OpenStruct.new(:test => "clearly")
          )
        end
    
        it "sets declared models as accessor" do
          form.test_model_1.should eq(OpenStruct.new(:dummy => "yes"))
          form.test_model_2.should eq(OpenStruct.new(:test => "clearly"))
        end
    
        it "has writable set accessors" do
          form.test_model_1 = "Something New"
          form.test_model_1.should eq("Something New")
        end
    
        it "sets @models in class to declared models" do
          form_class.models.should eq([:test_model_1, :test_model_2])
        end
      end
    
      describe "form model", :form_model => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            form_model :test_model_1
            form_model :test_model_2
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model_1 => OpenStruct.new(:dummy => "yes"),
            :test_model_2 => OpenStruct.new(:test => "clearly")
          )
        end
    
        it "sets declared models as accessor" do
          form.test_model_1.should eq(OpenStruct.new(:dummy => "yes"))
          form.test_model_2.should eq(OpenStruct.new(:test => "clearly"))
        end
    
        it "has writable set accessors" do
          form.test_model_1 = "Something New"
          form.test_model_1.should eq("Something New")
        end
    
        it "sets @models in class to declared models" do
          form_class.models.should eq([:test_model_1, :test_model_2])
        end
      end
    
      describe "declared models", :declared_models => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            declared_models :test_model_1, :test_model_2
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model_1 => OpenStruct.new(:dummy => "yes"),
            :test_model_2 => OpenStruct.new(:test => "clearly")
          )
        end
    
        it "sets declared models as accessor" do
          form.test_model_1.should eq(OpenStruct.new(:dummy => "yes"))
          form.test_model_2.should eq(OpenStruct.new(:test => "clearly"))
        end
    
        it "has writable set accessors" do
          form.test_model_1 = "Something New"
          form.test_model_1.should eq("Something New")
        end
    
        it "sets @models in class to declared models" do
          form_class.models.should eq([:test_model_1, :test_model_2])
        end
      end
    
      describe "form models", :form_models => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            form_models :test_model_1, :test_model_2
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model_1 => OpenStruct.new(:dummy => "yes"),
            :test_model_2 => OpenStruct.new(:test => "clearly")
          )
        end
    
        it "sets declared models as accessor" do
          form.test_model_1.should eq(OpenStruct.new(:dummy => "yes"))
          form.test_model_2.should eq(OpenStruct.new(:test => "clearly"))
        end
    
        it "has writable set accessors" do
          form.test_model_1 = "Something New"
          form.test_model_1.should eq("Something New")
        end
    
        it "sets @models in class to declared models" do
          form_class.models.should eq([:test_model_1, :test_model_2])
        end
      end

      describe "child models", :child_models => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            form_model :test_model_1
            child_model :test_model_2 do
              test_model_1.build_child
            end
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
              initialize_test_model_2
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model_1 => OpenStruct.new(:dummy => "yes", 
              :build_child => OpenStruct.new(:field => "child model"))
          )
        end
    
        it "sets declared models as accessor" do
          form.test_model_1.should eq(OpenStruct.new(:dummy => "yes", :build_child => OpenStruct.new(:field => "child model")))
          form.test_model_2.should eq(OpenStruct.new(:field => "child model"))
        end
    
        it "sets @models in class to declared models" do
          form_class.models.should eq([:test_model_1, :test_model_2])
        end
      end
    end
    
    describe "properties", :properties => true do
      describe "property", :property => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            declared_model :test_model
            
            property :attribute_1, :on => :test_model
            property :attribute_2, :on => :test_model, :ignore_blank => true
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(
            :test_model => OpenStruct.new(:attribute_1 => "yes"),
          )
        end
    
        it "delegates properties to models" do
          form.attribute_1.should eq("yes")
          form.attribute_2.should be_nil
        end  
  
        it "allows properties to be written, and delegates the values" do
          form.attribute_1 = "changed"
          form.attribute_1.should eq("changed")
          form.test_model.attribute_1.should eq("changed")
        end  
  
        it "tracks ignored blank fields" do
          form_class.ignored_blank_params.should eq([:attribute_2])
        end  
      end

      describe "allow_destroy_on_save", :allow_destroy_on_save => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Property
            declared_model :test_model
            allow_destroy_on_save
            
            property :attribute_1, :on => :test_model
            property :attribute_2, :on => :test_model, :ignore_blank => true
    
            def initialize(h={})
              h.each {|k,v| send("#{k}=",v)}
            end  
          end
        end
    
        let(:form) do
          form_class.new(:test_model => OpenStruct.new)
        end
    
        it "has _destroy accessor" do
          form.should respond_to(:_destroy)
        end

        it "has marked_for_destruction? accessor" do
          form.should respond_to(:marked_for_destruction?)
        end

        it "has destroy as false by default" do
          form._destroy.should be_false
        end

        it "has marked_for_destruction? as false by default" do
          form.marked_for_destruction?.should be_false
        end
        
        it "can be marked for destruction" do
          form.marked_for_destruction?.should be_false
          form.mark_for_destruction
          form.marked_for_destruction?.should be_true          
        end
      end
    end
  end

  describe "instance methods", :instance_methods => true do
    describe "assign_attributes", :assign_attributes => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Property
          declared_model :first_model
          declared_model :second_model
          
          property :attribute_1, :on => :first_model
          property :attribute_2, :on => :first_model, :ignore_blank => true
          property :attribute_3, :on => :second_model, :ignore_blank => true
          property :attribute_4, :on => :second_model
  
          def initialize(h)
            h.each {|k,v| send("#{k}=",v)}
          end
        end
      end
  
      let(:form) do
        form_class.new(
          :first_model  => OpenStruct.new(:attribute_1 => "first", :attribute_2 => "second"),
          :second_model => OpenStruct.new(:attribute_3 => "third", :attribute_4 => "fourth"),
        )
      end
      
      it "delegates properties to models" do
        form.assign_attributes({ 
          :attribute_1 => "changed", :attribute_2 => 182.34, 
          :attribute_3 => 45, :attribute_4 => Date.new(2013, 10, 10) })
 
        form.attribute_1.should eq("changed")
        form.attribute_2.should eq(182.34)
        form.attribute_3.should eq(45)
        form.attribute_4.should eq(Date.new(2013, 10, 10))
      end

      it "ignores blank params when set" do
        form.assign_attributes({ 
          :attribute_1 => "", :attribute_2 => "", 
          :attribute_3 => nil, :attribute_4 => nil })
 
        form.attribute_1.should eq("")
        form.attribute_2.should eq("second")
        form.attribute_3.should eq("third")
        form.attribute_4.should eq(nil)
      end

      it "handles individiual date components" do
        #TODO: should pass with symbols too!!
        form.assign_attributes({  
          "attribute_1(3i)" => 5, 
          "attribute_1(2i)" => 6, 
          "attribute_1(1i)" => 2013 })
 
        form.attribute_1.should eq(Date.new(2013, 6, 5))
      end
    end
  end
end