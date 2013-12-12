require 'spec_helper'

describe FreeForm::Form do
  let(:form_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :company
      form_models :company
      child_model :project do
        company.project.present? ? company.project : company.build_project
      end
      validate_models
      allow_destroy_on_save
      
      property :name,     :on => :company, :as => :company_name
      property :name,     :on => :project, :as => :project_name
      property :due_date, :on => :project

      has_many :tasks, :class_initializer => :task_initializer do
        form_model :task
        validate_models
        allow_destroy_on_save
        
        property :name,          :on => :task
        property :start_date,    :on => :task
        property :end_date,      :on => :task
      end
      
      def task_initializer
        { :task => project.tasks.build }
      end
    end
    # This wrapper just avoids CONST warnings
    v, $VERBOSE = $VERBOSE, nil
      Module.const_set("AcceptanceForm", klass)
    $VERBOSE = v
    klass
  end

  let(:form) do
    form_class.task_initializer = lambda { {:task => Task.new} }
    f = form_class.new( :company => Company.new )
    f.build_task
    f
  end
  
  describe "form initialization", :initialization => true do
    it "initializes with Company model" do
      form.company.should be_a(Company)
    end

    it "initializes with Project model" do
      form.project.should be_a(Project)
    end

    it "initializes with Task model" do
      form.tasks.first.task.should be_a(Task)
    end
  end

  describe "building nested models", :nested_models => true do
    it "can build multiple tasks" do
      form.tasks.count.should eq(1)
      form.build_task
      form.build_task
      form.tasks.count.should eq(3)
    end

    it "build new models for each task" do
      form.build_task
      task_1 = form.tasks.first.task
      task_2 = form.tasks.last.task
      task_1.should_not eq(task_2)
    end
  end

  describe "assigning parameters", :assign_params => true do
    let(:attributes) do {
      :company_name => "dummycorp",
      :project_name => "railsapp",
      "due_date(1i)" => "2014",
      "due_date(2i)" => "10",
      "due_date(3i)" => "30",
      :tasks_attributes => {
        "0" => {
          :name => "task_1",
          "start_date(1i)" => "2012",
          "start_date(2i)" => "1",
          "start_date(3i)" => "2",
        },
        "1" => {
          :name => "task_2",
          "end_date(1i)" => "2011",
          "end_date(2i)" => "12",
          "end_date(3i)" => "15",
        }
      } }
    end
    
    before(:each) do
      form.fill(attributes)
    end
    
    it "assigns company name" do
      form.company_name.should eq("dummycorp")
      form.company.name.should eq("dummycorp")
    end

    it "assigns project name" do
      form.project_name.should eq("railsapp")
      form.project.name.should eq("railsapp")
    end

    it "assigns project due date" do
      form.due_date.should eq(Date.new(2014, 10, 30))
      form.project.due_date.should eq(Date.new(2014, 10, 30))
    end

    it "builds new task automatically" do
      form.tasks.count.should eq(2)
    end

    it "assigns first task name" do
      form.tasks.first.task.name.should eq("task_1")
    end

    it "assigns first task start_date" do
      form.tasks.first.task.start_date.should eq(Date.new(2012, 1, 2))
    end

    it "assigns second task name" do
      form.tasks.last.task.name.should eq("task_2")
    end

    it "assigns second task end_date" do
      form.tasks.last.task.end_date.should eq(Date.new(2011, 12, 15))
    end
  end

  describe "validations", :validations => true do
    context "with invalid attributes" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => nil,
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "task_2",
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
            "end_date(3i)" => "15",
          }
        } }
      end
      
      before(:each) do
        form.fill(attributes)
        form.valid?
      end
      
      it "should be invalid" do
        form.should_not be_valid
      end

      it "should have errors on project name" do
        form.errors[:project_name].should eq(["can't be blank"])
      end

      it "should have errors on last tasks's start_date" do
        form.tasks.last.errors[:start_date].should eq(["can't be blank"])
      end
    end

    context "with valid attributes" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "railsapp",
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "task_2",
            "start_date(1i)" => "2011",
            "start_date(2i)" => "8",
            "start_date(3i)" => "15",
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
            "end_date(3i)" => "15",
          }
        } }
      end
      
      before(:each) do
        form.fill(attributes)
      end
      
      it "should be valid" do
        form.should be_valid
      end
    end
  end

  describe "saving and destroying", :saving => true do
    context "with invalid attributes" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => nil,
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "task_2",
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
            "end_date(3i)" => "15",
          }
        } }
      end
      
      before(:each) do
        form.fill(attributes)
      end
      
      it "should return false on 'save'" do
        form.save.should be_false
      end

      it "should raise error on 'save!'" do
        expect{ form.save!.should be_false }.to raise_error(FreeForm::FormInvalid)
      end
    end

    context "with valid attributes" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "railsapp",
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "task_2",
            "start_date(1i)" => "2011",
            "start_date(2i)" => "8",
            "start_date(3i)" => "15",
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
            "end_date(3i)" => "15",
          }
        } }
      end
      
      before(:each) do
        form.fill(attributes)
      end
      
      it "should return true on 'save', and call save on other models" do
        form.company.should_receive(:save).and_return(true)
        form.project.should_receive(:save).and_return(true)
        form.tasks.first.task.should_receive(:save).and_return(true)
        form.tasks.last.task.should_receive(:save).and_return(true)
        form.save
      end

      it "should return true on 'save!', and call save! on other models" do
        form.company.should_receive(:save!).and_return(true)
        form.project.should_receive(:save!).and_return(true)
        form.tasks.first.task.should_receive(:save!).and_return(true)
        form.tasks.last.task.should_receive(:save!).and_return(true)
        form.save!
      end

      describe "destroying on save", :destroy_on_save => true do
        describe "save" do
          it "destroys models on save if set" do
            form._destroy = true
            form.company.should_receive(:destroy).and_return(true)
            form.project.should_receive(:destroy).and_return(true)
            form.tasks.first.task.should_receive(:save).and_return(true)
            form.tasks.last.task.should_receive(:save).and_return(true)
            form.save
          end
    
          it "destroys models on save if set through attribute" do
            form.fill({:_destroy => "1"})
            form.company.should_receive(:destroy).and_return(true)
            form.project.should_receive(:destroy).and_return(true)
            form.tasks.first.task.should_receive(:save).and_return(true)
            form.tasks.last.task.should_receive(:save).and_return(true)
            form.save
          end

          it "destroys nested models on save if set" do
            form.tasks.first._destroy = true
            form.company.should_receive(:save).and_return(true)
            form.project.should_receive(:save).and_return(true)
            form.tasks.first.task.should_receive(:destroy).and_return(true)
            form.tasks.last.task.should_receive(:save).and_return(true)
            form.save
          end
        end
        
        describe "save!" do
          it "destroys models on save! if set" do
            form._destroy = true
            form.company.should_receive(:destroy).and_return(true)
            form.project.should_receive(:destroy).and_return(true)
            form.tasks.first.task.should_receive(:save!).and_return(true)
            form.tasks.last.task.should_receive(:save!).and_return(true)
            form.save!
          end
  
          it "destroys models on save! if set" do
            form.fill({:_destroy => "1"})
            form.company.should_receive(:destroy).and_return(true)
            form.project.should_receive(:destroy).and_return(true)
            form.tasks.first.task.should_receive(:save!).and_return(true)
            form.tasks.last.task.should_receive(:save!).and_return(true)
            form.save!
          end

          it "destroys nested models on save! if set" do
            form.tasks.last._destroy = true
            form.company.should_receive(:save!).and_return(true)
            form.project.should_receive(:save!).and_return(true)
            form.tasks.first.task.should_receive(:save!).and_return(true)
            form.tasks.last.task.should_receive(:destroy).and_return(true)
            form.save!
          end
        end
      end
    end
  end
end