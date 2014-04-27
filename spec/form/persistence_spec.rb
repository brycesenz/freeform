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

  describe "form initialization", :initialization => true do
    it "initializes with task model" do
      form.task.should eq(task)
    end

    it "initializes with a milestone model" do
      form.milestones.should_not be_empty
    end
  end

  describe "saving and destroying", :saving => true do
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

      it "should return false on 'save'" do
        form.save.should be_false
      end

      it "should raise error on 'save!'" do
        expect{ form.save! }.to raise_error(FreeForm::FormInvalid)
      end
    end
  end
end