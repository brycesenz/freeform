require 'spec_helper'
require 'freeform/form/model'
require 'freeform/form/property'

describe FreeForm::Property do
  describe "class methods", :class_methods => true do    
    describe "property", :property => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
          include FreeForm::Property
          declared_model :test_model
          
          property :attribute_1, :on => :test_model
          property :attribute_2, :on => :test_model, :ignore_blank => true
          property :attribute_3, :as => :test_attribute_3, :on => :test_model
  
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
  
      describe "delegation" do
        it "delegates properties to models" do
          form.attribute_1.should eq("yes")
          form.attribute_2.should be_nil
        end  
  
        it "allows properties to be written, and delegates the values" do
          form.attribute_1 = "changed"
          form.attribute_1.should eq("changed")
          form.test_model.attribute_1.should eq("changed")
        end  

        it "delegates using :as" do
          form.test_attribute_3.should be_nil
          form.test_attribute_3 = "set_using_as"
          form.test_attribute_3.should eq("set_using_as") 
          form.test_model.attribute_3.should eq("set_using_as")
        end  
      end
      
      describe "property_mappings" do
        it "sets appropriate property mappings" do
          form_class.property_mappings.should eq(
          { :attribute_1 => {:model => :test_model, :field => :attribute_1, :ignore_blank => false},
            :attribute_2 => {:model => :test_model, :field => :attribute_2, :ignore_blank => true},
            :test_attribute_3 => {:model => :test_model, :field => :attribute_3, :ignore_blank => false}
          }
          )
        end  
      end

      describe "allow_destroy_on_save", :allow_destroy_on_save => true do
        let(:form_class) do
          Class.new(Module) do
            include FreeForm::Model
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
        
        it "interprets '0' is not marked for destruction" do
          form.fill({:_destroy => "0"})
          form.marked_for_destruction?.should be_false
        end

        it "interprets 'false' is not marked for destruction" do
          form.fill({:_destroy => "false"})
          form.marked_for_destruction?.should be_false
        end

        it "interprets '1' is marked for destruction" do
          form.fill({:_destroy => "1"})
          form.marked_for_destruction?.should be_true
        end

        it "interprets 'true' is marked for destruction" do
          form.fill({:_destroy => "true"})
          form.marked_for_destruction?.should be_true
        end

        it "interprets '2' is marked for destruction" do
          form.fill({:_destroy => "2"})
          form.marked_for_destruction?.should be_true
        end
      end
    end
  end

  describe "instance methods", :instance_methods => true do
    describe "assign_attributes", :assign_attributes => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
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
        form.assign_attributes({  
          "attribute_1(3i)" => 5, 
          "attribute_1(2i)" => 6, 
          "attribute_1(1i)" => 2013 })
 
        form.attribute_1.should eq(Date.new(2013, 6, 5))
      end
    end

    describe "before_assign_params", :before_assign_params => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
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

          def before_assign_params(params)
            params.delete("attribute_1")
          end
        end
      end
  
      let(:form) do
        form_class.new(
          :first_model  => OpenStruct.new(:attribute_1 => "first", :attribute_2 => "second"),
          :second_model => OpenStruct.new(:attribute_3 => "third", :attribute_4 => "fourth"),
        )
      end
      
      it "deletes attribute_1 from params" do
        form.assign_attributes({ 
          :attribute_1 => "changed", :attribute_2 => 182.34, 
          :attribute_3 => 45, :attribute_4 => Date.new(2013, 10, 10) })
 
        form.attribute_1.should_not eq("changed")
        form.attribute_2.should eq(182.34)
        form.attribute_3.should eq(45)
        form.attribute_4.should eq(Date.new(2013, 10, 10))
      end
    end

    describe "after_assign_params", :after_assign_params => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
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

          def after_assign_params(params)
            params.delete("attribute_1")
            assign_attribute("attribute_3", "overwritten")
          end
        end
      end
  
      let(:form) do
        form_class.new(
          :first_model  => OpenStruct.new(:attribute_1 => "first", :attribute_2 => "second"),
          :second_model => OpenStruct.new(:attribute_3 => "third", :attribute_4 => "fourth"),
        )
      end
      
      it "deletes attribute_1 from params" do
        form.assign_attributes({ 
          :attribute_1 => "changed", :attribute_2 => 182.34, 
          :attribute_3 => 45, :attribute_4 => Date.new(2013, 10, 10) })
 
        form.attribute_1.should eq("changed")
        form.attribute_2.should eq(182.34)
        form.attribute_3.should eq("overwritten")
        form.attribute_4.should eq(Date.new(2013, 10, 10))
      end
    end

    describe "model_property_mappings", :model_property_mappings => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
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
      
      it "has correct model_property_mappings hash" do
        form.model_property_mappings.should eq(
          {
            :attribute_1 => {
              :model => :first_model, 
              :field => :attribute_1, 
              :ignore_blank => false,
            },
            :attribute_2 => {
              :model => :first_model, 
              :field => :attribute_2, 
              :ignore_blank => true,
            },
            :attribute_3 => {
              :model => :second_model, 
              :field => :attribute_3, 
              :ignore_blank => true,
            },
            :attribute_4 => {
              :model => :second_model, 
              :field => :attribute_4, 
              :ignore_blank => false,
            },
          }
        )
      end
    end
  end
end