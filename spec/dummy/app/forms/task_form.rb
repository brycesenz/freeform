class TaskForm < FreeForm::Form
  form_input_key :task
  form_model :task    
  property :name, :on => :task

#  has_many :milestones, :class => ::MilestoneForm, :default_initializer => :milestone_initializer
  
#  def milestone_initializer
#    { :milestone => Milestone.new }
#  end
end
