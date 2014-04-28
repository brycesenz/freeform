require 'spec_helper'
require 'freeform/form/model'

describe FreeForm::Model do
  describe "class methods", :class_methods => true do
    describe "declared model", :declared_model => true do
      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
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
          include FreeForm::Model
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
          include FreeForm::Model
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
          include FreeForm::Model
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
          include FreeForm::Model
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

  describe "instance methods", :instance_methods => true do
    describe "models", :models => true do
      let(:model_1) { OpenStruct.new(:name => "first") }
      let(:model_2) { OpenStruct.new(:name => "second") }
      let(:address_1) { OpenStruct.new(:name => "main st.") }
      let(:address_2) { OpenStruct.new(:name => "oak ave.") }

      let(:form_class) do
        Class.new(Module) do
          include FreeForm::Model
          include FreeForm::Nested
          declared_model :first_model
          declared_model :second_model
          
          has_many :addresses do
            declared_model :address
          end
  
          def initialize(h)
            h.each {|k,v| send("#{k}=",v)}
          end

          def address_initializer
            { :address => OpenStruct.new }
          end
        end
      end
  
      let(:form) do
        form_class.new(:first_model  => model_1, :second_model => model_2)
      end

      context "without nested models" do
        it "returns array of models " do
          form.models.should eq([model_1, model_2])
        end
      end

      context "without nested models" do
        before(:each) do
          form.build_address(:address => address_1)
          form.build_address(:address => address_2)
        end

        it "returns array of models" do
          form.models.should be_a(Array)
        end

        it "has model_1 as its first model" do
          form.models[0].should eq(model_1)
        end

        it "has model_2 as its second model" do
          form.models[1].should eq(model_2)
        end

        it "has nested model form for address_1 as its third model" do
          form.models[2].address.should eq(address_1)
        end

        it "has nested model form for address_2 as its fourth model" do
          form.models[3].address.should eq(address_2)
        end
      end
    end
  end
end