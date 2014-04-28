require 'spec_helper'
require 'freeform/form'

describe FreeForm::Form do
  let(:form_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :company
      form_models :company
      child_model :project do
        company.project || company.build_project
      end
      validate_models
      allow_destroy_on_save

      property :name,     :on => :company, :as => :company_name
      property :name,     :on => :project, :as => :project_name
      property :due_date, :on => :project

      has_many :tasks do
        form_input_key :task
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

  let(:company) { Company.create!(:name => "Demo Corporation") }
  let(:project) { Project.create!(:owner => company, :name => "Widget", :due_date => Date.new(2014, 1, 1)) }
  let(:task_1)  { Task.create!(:project => project, :name => "Task 1", :start_date => Date.new(2014, 2, 2), :end_date => Date.new(2014, 3, 3)) }
  let(:task_2)  { Task.create!(:project => project, :name => "Task 2", :start_date => Date.new(2014, 9, 1), :end_date => Date.new(2014, 10, 1)) }

  let(:form) do
    form_class.new( :company => company ).tap do |f|
      company.project.tasks.each do |task|
        f.build_task(:task => task)
      end
    end
  end

  before(:each) do
    company.reload
    project.reload
    task_1.reload
    task_2.reload
  end

  describe "form initialization", :initialization => true do
    it "initializes with Company model" do
      form.company.should eq(company)
    end

    it "initializes with Project model" do
      form.project.should eq(project)
    end

    it "initializes with Task model" do
      form.tasks.first.task.should eq(task_1)
    end

    it "initializes with Task with project parent" do
      task = form.tasks.first.task
      task.project.should eq(form.project)
    end
  end

  describe "building nested models", :nested_models => true do
    it "can build multiple tasks" do
      form.tasks.count.should eq(2)
      form.build_task
      form.tasks.count.should eq(3)
    end

    it "build new models for each task" do
      form.build_task
      task_1 = form.tasks.first.task
      task_2 = form.tasks.last.task
      task_1.should_not eq(task_2)
    end

    it "builds new tasks with project parent" do
      form.build_task
      task_1 = form.tasks.first.task
      task_2 = form.tasks.last.task
      task_1.project.should eq(task_2.project)
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

      it "should not have errors on last tasks's start_date" do
        form.tasks.last.errors[:start_date].should be_empty
      end
    end

    context "with invalid nested model only" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "rails app",
        "due_date(1i)" => "2014",
        "due_date(2i)" => "10",
        "due_date(3i)" => "30",
        :tasks_attributes => {
          "0" => {
            :name => "task_1",
            "start_date(1i)" => nil,
            "start_date(2i)" => nil,
            "start_date(3i)" => nil,
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

      it "should have errors on first tasks's start_date" do
        form.tasks.first.errors[:start_date].should eq(["can't be blank"])
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

      describe "#save" do
        it "should return false on 'save'" do
          form.save.should be_false
        end

        it "does not update company model" do
          form.save
          company.reload.name.should_not eq("dummycorp")
        end

        it "does not update project model" do
          form.save
          project.reload.due_date.should_not eq(Date.new(2014, 10, 30))
        end

        it "does not update the first task model" do
          form.save
          task_1.reload.name.should_not eq("task_1")
          task_1.reload.start_date.should_not eq(Date.new(2012, 1, 2))
        end

        it "does not update the second task model" do
          form.save
          task_2.reload.name.should_not eq("task_2")
          task_2.reload.end_date.should_not eq(Date.new(2011, 12, 15))
        end
      end

      describe "#save!" do
        it "should raise error on 'save!'" do
          expect{ form.save! }.to raise_error(FreeForm::FormInvalid)
        end
      end
    end

    context "with invalid, marked for destruction attributes" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "my_project",
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
            :name => nil,
            "end_date(1i)" => "2011",
            "end_date(2i)" => "12",
            "end_date(3i)" => "15",
            :_destroy => "1"
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      describe "#save" do
        it "should return true on 'save'" do
          form.save.should be_true
        end

        it "updates company model" do
          form.save
          company.reload.name.should eq("dummycorp")
        end

        it "updates project model" do
          form.save
          project.reload.name.should eq("my_project")
          project.reload.due_date.should eq(Date.new(2014, 10, 30))
        end

        it "updates the first task model" do
          form.save
          task_1.reload.name.should eq("task_1")
          task_1.reload.start_date.should eq(Date.new(2012, 1, 2))
        end

        it "destroys the second task model" do
          form.save
          task_2.should_not exist_in_database
        end
      end

      describe "#save!" do
        it "should not raise error on 'save!'" do
          expect{ form.save! }.to_not raise_error
        end
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
            :name => "new_task_1",
            "start_date(1i)" => "2012",
            "start_date(2i)" => "1",
            "start_date(3i)" => "2",
          },
          "1" => {
            :name => "new_task_2",
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

      describe "#save" do
        it "should return true on 'save'" do
          form.save.should be_true
        end

        it "updates company model" do
          form.save
          company.reload.name.should eq("dummycorp")
        end

        it "updates project model" do
          form.save
          project.reload.name.should eq("railsapp")
          project.reload.due_date.should eq(Date.new(2014, 10, 30))
        end

        it "updates the first task model" do
          form.save
          task_1.reload.name.should eq("new_task_1")
          task_1.reload.start_date.should eq(Date.new(2012, 1, 2))
        end

        it "updates the second task model" do
          form.save
          task_2.reload.name.should eq("new_task_2")
          task_2.reload.start_date.should eq(Date.new(2011, 8, 15))
          task_2.reload.end_date.should eq(Date.new(2011, 12, 15))
        end
      end

      describe "#save!" do
        it "should not raise error on 'save!'" do
          expect{ form.save! }.to_not raise_error
        end
      end
    end
  end
end