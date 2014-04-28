require 'spec_helper'

describe FreeForm::Form do
  let(:form_class) do
    klass = Class.new(FreeForm::Form) do
      form_input_key :task
      form_models :task
      validate_models
      allow_destroy_on_save

      property :name,        :on => :task
      property :start_date,  :on => :task
      property :end_date,    :on => :task
      validates :name, :presence => true

      has_many :milestones do
        form_input_key :milestone
        form_model :milestone
        validate_models
        allow_destroy_on_save

        property :name,          :on => :milestone
      end

      def milestone_initializer
        { :milestone => task.milestones.build }
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
  let(:task)  { Task.new(:project => project) }

  let(:form) do
    form_class.new( :task => task ).tap do |f|
      f.build_milestone
    end
  end

  before(:each) { Milestone.destroy_all }

  describe "form initialization", :initialization => true do
    it "initializes with task model" do
      form.task.should eq(task)
    end

    it "initializes with a milestone model" do
      form.milestones.should_not be_empty
    end
  end

  describe "saving", :saving => true do
    context "with invalid attributes on primary form" do
      let(:attributes) do {
        :name => nil,
        "start_date(1i)" => "2012",
        "start_date(2i)" => "1",
        "start_date(3i)" => "2",
        "end_date(1i)" => "2011",
        "end_date(2i)" => "12",
        "end_date(3i)" => "15",
        :milestones_attributes => {
          "0" => {
            :name => "milestone_1",
          },
          "1310201" => {
            :name => "milestone_2",
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      it "should not be valid" do
        form.should_not be_valid
      end

      describe "#save" do
        it "should return false on 'save'" do
          form.save.should be_false
        end

        it "should not persist task" do
          form.save
          task.should_not exist_in_database
        end

        it "should not save any Milestone objects" do
          form.save
          Milestone.all.size.should eq(0)
        end
      end

      describe "#save!" do
        it "should raise error on 'save!'" do
          expect{ form.save! }.to raise_error(FreeForm::FormInvalid)
        end
      end
    end

    context "with invalid attributes on nested form" do
      let(:attributes) do {
        :name => "newtask",
        "start_date(1i)" => "2012",
        "start_date(2i)" => "1",
        "start_date(3i)" => "2",
        "end_date(1i)" => "2011",
        "end_date(2i)" => "12",
        "end_date(3i)" => "15",
        :milestones_attributes => {
          "0" => {
            :name => "milestone_1",
          },
          "1310201" => {
            :name => nil,
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      it "should not be valid" do
        form.should_not be_valid
      end

      describe "#save" do
        it "should return false on 'save'" do
          form.save.should be_false
        end

        it "should not persist task" do
          form.save
          task.should_not exist_in_database
        end

        it "should not save any Milestone objects" do
          form.save
          Milestone.all.size.should eq(0)
        end
      end

      describe "#save!" do
        it "should raise error on 'save!'" do
          expect{ form.save! }.to raise_error(FreeForm::FormInvalid)
        end
      end
    end

    context "with invalid attributes on destroyed nested form" do
      let(:attributes) do {
        :name => "newtask",
        "start_date(1i)" => "2012",
        "start_date(2i)" => "1",
        "start_date(3i)" => "2",
        "end_date(1i)" => "2011",
        "end_date(2i)" => "12",
        "end_date(3i)" => "15",
        :milestones_attributes => {
          "0" => {
            :name => "milestone_1",
          },
          "1310201" => {
            :name => nil,
            :_destroy => "1",
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      it "should not be valid" do
        form.should be_valid
      end

      describe "#save" do
        it "should return true on 'save'" do
          form.save.should be_true
        end

        it "should persist task" do
          form.save
          task.should exist_in_database
        end

        it "should save one Milestone object" do
          form.save
          Milestone.all.size.should eq(1)
        end
      end

      describe "#save!" do
        it "should not raise error on 'save!'" do
          expect{ form.save! }.to_not raise_error
        end
      end
    end

    context "with valid attributes and multiple nested forms" do
      let(:attributes) do {
        :name => "newtask",
        "start_date(1i)" => "2012",
        "start_date(2i)" => "1",
        "start_date(3i)" => "2",
        "end_date(1i)" => "2011",
        "end_date(2i)" => "12",
        "end_date(3i)" => "15",
        :milestones_attributes => {
          "0" => {
            :name => "milestone_1",
          },
          "1310201" => {
            :name => "milestone_2",
          },
          "9837373" => {
            :name => "milestone_3",
          }
        } }
      end

      before(:each) do
        form.fill(attributes)
      end

      it "should not be valid" do
        form.should be_valid
      end

      describe "#save" do
        it "should return true on 'save'" do
          form.save.should be_true
        end

        it "should persist task" do
          form.save
          task.should exist_in_database
        end

        it "should save three Milestone objects" do
          form.save
          Milestone.all.size.should eq(3)
        end
      end

      describe "#save!" do
        it "should not raise error on 'save!'" do
          expect{ form.save! }.to_not raise_error
        end
      end
    end
  end

  describe "destroying", :destroying => true do
    context "without nested forms" do
      let(:task) { Task.create!(:project => project, :name => "mytask", :start_date => Date.new(2011, 1, 1), :end_date => Date.new(2012, 1, 1)) }

      let(:form) do
        form_class.new( :task => task )
      end

      it "destroys all models in form" do
        form.destroy
        task.should_not exist_in_database
      end
    end

    context "with nested forms" do
      let(:task) { Task.create!(:project => project, :name => "mytask", :start_date => Date.new(2011, 1, 1), :end_date => Date.new(2012, 1, 1)) }
      let(:milestone) do
        task.milestones.build do |m|
          m.name = "dummy_milestone"
          m.save!
        end
      end 

      let(:form) do
        form_class.new( :task => task ).tap do |f|
          f.build_milestone(:milestone => milestone)
        end
      end

      it "destroys all models in form" do
        form.destroy
        task.should_not exist_in_database
      end

      it "destroys all nested models" do
        form.destroy
        milestone.should_not exist_in_database
      end
    end
  end
end