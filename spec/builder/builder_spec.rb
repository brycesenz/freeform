require "spec_helper"
=begin
[FreeForm::Builder, FreeForm::SimpleBuilder, defined?(FreeForm::FormtasticBuilder) ? FreeForm::FormtasticBuilder : nil].compact.each do |builder|
  describe builder do
    let!(:milestone_form_class) do
      klass = Class.new(FreeForm::Form) do
        form_input_key :milestone
        form_models :milestone
        allow_destroy_on_save
        
        property :name, :on => :milestone  
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("MilestoneForm", klass)
      $VERBOSE = v
      klass
    end

    let!(:task_form_class) do
      klass = Class.new(FreeForm::Form) do
        form_input_key :task
        form_models :task
        allow_destroy_on_save
        
        property :name, :on => :task
  
        has_many :milestones, :class => Module::MilestoneForm, :default_initializer => :milestone_initializer

        def milestone_initializer
          {:milestone => Milestone.new}
        end
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("TaskForm", klass)
      $VERBOSE = v
      klass
    end

    let(:form_class) do
      klass = Class.new(FreeForm::Form) do
        form_input_key :project
        form_models :project
        allow_destroy_on_save
        
        property :name, :on => :project
  
        has_many :tasks, :class => Module::TaskForm, :default_initializer => :task_initializer
        
        def task_initializer
          {:task => Task.new}
        end
      end
      # This wrapper just avoids CONST warnings
      v, $VERBOSE = $VERBOSE, nil
        Module.const_set("ViewForm", klass)
      $VERBOSE = v
      klass
    end
    
    let(:form) { form_class.new(:project => Project.new) }

    let(:template) do
      template = ActionView::Base.new
      template.output_buffer = ""
      template
    end

    context "with no options", :no_options => true do
      subject do
        builder.new(:item, form, template, {}, proc {})
      end

      describe '#link_to_add', :link_to_add => true do
        it "behaves similar to a Rails link_to" do
          subject.link_to_add("Add", :tasks).should eq('<a href="javascript:void(0)" class="add_nested_form" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
          subject.link_to_add("Add", :tasks, :class => "foo", :href => "url").should eq('<a href="url" class="foo add_nested_form" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
          subject.link_to_add(:tasks) { "Add" }.should eq('<a href="javascript:void(0)" class="add_nested_form" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
        end

        it 'raises ArgumentError when missing association is provided' do
          expect {
            subject.link_to_add('Add', :bugs)
          }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError when accepts_nested_attributes_for is missing' do
          expect {
            subject.link_to_add('Add', :not_nested_tasks)
          }.to raise_error(ArgumentError)
        end
      end

      describe '#link_to_remove', :link_to_remove => true do
        it "behaves similar to a Rails link_to" do
          subject.link_to_remove("Remove").should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="javascript:void(0)" class="remove_nested_form">Remove</a>')
          subject.link_to_remove("Remove", :class => "foo", :href => "url").should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="url" class="foo remove_nested_form">Remove</a>')
          subject.link_to_remove { "Remove" }.should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="javascript:void(0)" class="remove_nested_form">Remove</a>')
        end

        it 'has data-association attribute' do
          form.build_task
          subject.fields_for(:tasks, :builder => builder) do |tf|
            tf.link_to_remove 'Remove'
          end.should match '<a.+data-association="tasks">Remove</a>'
        end

        context 'when there is more than one nested level' do
          it 'properly detects association name' do
            task = form.build_task
            task.build_milestone
            subject.fields_for(:tasks, :builder => builder) do |tf|
              tf.fields_for(:milestones, :builder => builder) do |mf|
                mf.link_to_remove 'Remove'
              end
            end.should match '<a.+data-association="milestones">Remove</a>'
          end
        end
      end

      describe '#fields_for' do
        it "wraps nested fields each in a div with class" do
          2.times { form.build_task }

          fields = if subject.is_a?(FreeForm::SimpleBuilder)
            subject.simple_fields_for(:tasks) { "Task" }
          else
            subject.fields_for(:tasks) { "Task" }
          end

          fields.should == '<div class="fields">Task</div><div class="fields">Task</div>'
        end
      end

      it "wraps nested fields marked for destruction with an additional class" do
        task = form.build_task
        task.mark_for_destruction
        fields = subject.fields_for(:tasks) { 'Task' }
        fields.should eq('<div class="fields marked_for_destruction">Task</div>')
      end

      it "puts blueprint into data-blueprint attribute" do
        task = form.build_task
        task.mark_for_destruction
        subject.fields_for(:tasks) { 'Task' }
        subject.link_to_add('Add', :tasks)
        output   = template.send(:after_freeform_callbacks)
        expected = ERB::Util.html_escape '<div class="fields">Task</div>'
        output.should match(/div.+data-blueprint="#{expected}"/)
      end

      it "adds parent association name to the blueprint div id" do
        task = form.build_task
        task.build_milestone
        subject.fields_for(:tasks, :builder => builder) do |tf|
          tf.fields_for(:milestones, :builder => builder) { 'Milestone' }
          tf.link_to_add('Add', :milestones)
        end
        output = template.send(:after_freeform_callbacks)
        output.should match(/div.+id="tasks_milestones_fields_blueprint"/)
      end

      it "doesn't render wrapper div" do
        task = form.build_task
        fields = subject.fields_for(:tasks, :wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_freeform_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end

      it "doesn't render wrapper div when collection is passed" do
        task = form.build_task
        fields = subject.fields_for(:tasks, form.tasks, :wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_freeform_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end

      it "doesn't render wrapper with nested_wrapper option" do
        task = form.build_task
        fields = subject.fields_for(:tasks, :nested_wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_freeform_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end
    end

    context "with options", :with_options => true do
      subject { builder.new(:item, form, template, {}, proc {}) }

      context "when model_object given" do
        it "should use it instead of new generated" do
          subject.fields_for(:tasks) {|f| f.object.name }
          subject.link_to_add("Add", :tasks, :model_object => Task.new(:name => 'for check'))
          output   = template.send(:after_freeform_callbacks)
          expected = ERB::Util.html_escape '<div class="fields">for check</div>'
          output.should match(/div.+data-blueprint="#{expected}"/)
        end
      end
    end
  end
end
=end