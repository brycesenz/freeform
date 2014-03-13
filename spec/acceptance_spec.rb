require 'spec_helper'

describe FreeForm::Form do
  let!(:task_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :task
      form_model :task
      validate_models
      allow_destroy_on_save

      property :name,          :on => :task
      property :start_date,    :on => :task
      property :end_date,      :on => :task
    end
    # This wrapper just avoids CONST warnings
    v, $VERBOSE = $VERBOSE, nil
      Module.const_set("TaskForm", klass)
    $VERBOSE = v
    klass
  end

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

      has_many :tasks, :class => Module::TaskForm, :default_initializer => :default_task_initializer

      def default_task_initializer
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
    form_class.new( :company => Company.new ).tap do |f|
      f.build_task
    end
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

    it "initializes with Task with project parent" do
      task = form.tasks.first.task
      task.should eq(form.project.tasks.first)
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

      it "should have errors on last tasks's start_date" do
        form.tasks.last.errors[:start_date].should eq(["can't be blank"])
      end
    end

    context "with invalid form, and invalid marked for destruction nested model" do
      let(:attributes) do {
        :company_name => "",
        :project_name => "rails app",
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
            :_destroy => "1"
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
        form.valid?
      end

      it "should not be valid" do
        form.should_not be_valid
      end

      it "should not have errors" do
        form.errors[:company_name].should eq(["can't be blank"])
      end
    end

    context "with marked for destruction invalid nested model" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "rails app",
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
            :_destroy => "1"
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
        form.valid?
      end

      it "should be valid" do
        form.should be_valid
      end

      it "should not have errors" do
        form.errors.should be_empty
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
        expect{ form.save! }.to raise_error(FreeForm::FormInvalid)
      end
    end

    context "with invalid attributes, and marked for destruction nested model" do
      let(:attributes) do {
        :company_name => "dummycorp",
        :project_name => "",
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
          "3234322345" => {
            :name => "task_2",
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

      it "should not be valid" do
        form.should_not be_valid
      end

      describe "persisting destroy after failed save" do
        before(:each) { form.save }

        it "should have the second form still set to _destroy" do
          form.tasks.second.should be_marked_for_destruction
        end
      end

#       it "should have valid company and project after save", :failing => true do
#         form.save
# #        form.tasks.first.task.destroy
#         form.company.should be_valid
#         form.project.valid?
#         puts "Errors = #{form.project.errors.inspect}"
#         form.project.should be_valid
#       end

#       it "should not raise error on 'save!'" do
#         expect{ form.save! }.to_not raise_error
#       end
     end

    context "with invalid, marked for destruction nested model" do
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
            :_destroy => "1"
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      it { is pending }

#       it "should have valid company and project after save", :failing => true do
#         form.save
# #        form.tasks.last.task.destroy
# #        form.valid?
#         form.company.should be_valid
#         form.project.valid?
#         # puts "Errors = #{form.project.errors.inspect}"

#         # form.project.tasks.each do |task|
#         #   puts "Task = #{task.inspect}"
#         #   puts "Valid = #{task.valid?}"
#         #   puts "Errors = #{task.errors.inspect}"
#         # end
#         form.project.should be_valid
#       end

# #       it "should not raise error on 'save!'" do
# #         expect{ form.save! }.to_not raise_error
# #       end
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
