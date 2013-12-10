require "spec_helper"

[FreeForm::Builder, FreeForm::SimpleBuilder, defined?(FreeForm::FormtasticBuilder) ? FreeForm::FormtasticBuilder : nil].compact.each do |builder|
  describe builder do
    #FIXME: This should actually be based off of a FreeForm Object
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
    
    let(:test_form) { form_class.new(:project => Project.new) }

    let(:project) do
      Project.new
    end

    let(:template) do
      template = ActionView::Base.new
      template.output_buffer = ""
      template
    end

    context "with no options", :no_options => true do
      subject do
        builder.new(:item, project, template, {}, proc {})
      end

      describe '#link_to_add', :link_to_add => true do
        it "behaves similar to a Rails link_to" do
          subject.link_to_add("Add", :tasks).should eq('<a href="javascript:void(0)" class="add_nested_fields" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
          subject.link_to_add("Add", :tasks, :class => "foo", :href => "url").should eq('<a href="url" class="foo add_nested_fields" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
          subject.link_to_add(:tasks) { "Add" }.should eq('<a href="javascript:void(0)" class="add_nested_fields" data-association="tasks" data-blueprint-id="tasks_fields_blueprint">Add</a>')
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
          subject.link_to_remove("Remove").should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="javascript:void(0)" class="remove_nested_fields">Remove</a>')
          subject.link_to_remove("Remove", :class => "foo", :href => "url").should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="url" class="foo remove_nested_fields">Remove</a>')
          subject.link_to_remove { "Remove" }.should eq('<input id="item__destroy" name="item[_destroy]" type="hidden" value="false" /><a href="javascript:void(0)" class="remove_nested_fields">Remove</a>')
        end

        it 'has data-association attribute' do
          project.tasks.build
          subject.fields_for(:tasks, :builder => builder) do |tf|
            tf.link_to_remove 'Remove'
          end.should match '<a.+data-association="tasks">Remove</a>'
        end

        context 'when association is declared in a model by the class_name' do
          it 'properly detects association name' do
            project.assignments.build
            subject.fields_for(:assignments, :builder => builder) do |tf|
              tf.link_to_remove 'Remove'
            end.should match '<a.+data-association="assignments">Remove</a>'
          end
        end

        context 'when there is more than one nested level' do
          it 'properly detects association name' do
            task = project.tasks.build
            task.milestones.build
            subject.fields_for(:tasks, :builder => builder) do |tf|
              tf.fields_for(:milestones, :builder => builder) do |mf|
                mf.link_to_remove 'Remove'
              end
            end.should match '<a.+data-association="milestones">Remove</a>'
          end
        end

        context 'has_one association' do
          let(:company) { Company.new }
          subject { builder.new(:item, company, template, {}, proc {}) }

          it 'properly detects association name' do
            subject.fields_for(:project, :builder => builder) do |f|
              f.link_to_remove 'Remove'
            end.should match '<a.+data-association="project">Remove</a>'
          end
        end
      end

      describe '#fields_for' do
        it "wraps nested fields each in a div with class" do
          2.times { project.tasks.build }

          fields = if subject.is_a?(FreeForm::SimpleBuilder)
            subject.simple_fields_for(:tasks) { "Task" }
          else
            subject.fields_for(:tasks) { "Task" }
          end

          fields.should == '<div class="fields">Task</div><div class="fields">Task</div>'
        end
      end

      it "wraps nested fields marked for destruction with an additional class" do
        task = project.tasks.build
        task.mark_for_destruction
        fields = subject.fields_for(:tasks) { 'Task' }
        fields.should eq('<div class="fields marked_for_destruction">Task</div>')
      end

      it "puts blueprint into data-blueprint attribute" do
        task = project.tasks.build
        task.mark_for_destruction
        subject.fields_for(:tasks) { 'Task' }
        subject.link_to_add('Add', :tasks)
        output   = template.send(:after_nested_form_callbacks)
        expected = ERB::Util.html_escape '<div class="fields">Task</div>'
        output.should match(/div.+data-blueprint="#{expected}"/)
      end

      it "adds parent association name to the blueprint div id" do
        task = project.tasks.build
        task.milestones.build
        subject.fields_for(:tasks, :builder => builder) do |tf|
          tf.fields_for(:milestones, :builder => builder) { 'Milestone' }
          tf.link_to_add('Add', :milestones)
        end
        output = template.send(:after_nested_form_callbacks)
        output.should match(/div.+id="tasks_milestones_fields_blueprint"/)
      end

      it "doesn't render wrapper div" do
        task = project.tasks.build
        fields = subject.fields_for(:tasks, :wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_nested_form_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end

      it "doesn't render wrapper div when collection is passed" do
        task = project.tasks.build
        fields = subject.fields_for(:tasks, project.tasks, :wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_nested_form_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end

      it "doesn't render wrapper with nested_wrapper option" do
        task = project.tasks.build
        fields = subject.fields_for(:tasks, :nested_wrapper => false) { 'Task' }

        fields.should eq('Task')

        subject.link_to_add 'Add', :tasks
        output = template.send(:after_nested_form_callbacks)

        output.should match(/div.+data-blueprint="Task"/)
      end
    end

    context "with options", :with_options => true do
      subject { builder.new(:item, project, template, {}, proc {}) }

      context "when model_object given" do
        it "should use it instead of new generated" do
          subject.fields_for(:tasks) {|f| f.object.name }
          subject.link_to_add("Add", :tasks, :model_object => Task.new(:name => 'for check'))
          output   = template.send(:after_nested_form_callbacks)
          expected = ERB::Util.html_escape '<div class="fields">for check</div>'
          output.should match(/div.+data-blueprint="#{expected}"/)
        end
      end
    end
  end
end