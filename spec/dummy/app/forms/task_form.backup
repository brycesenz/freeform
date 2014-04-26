class TaskForm < FreeForm::Form
  form_models :task
  property :name, :on => :task
  allow_destroy_on_save

  has_many :milestones, :class => MilestoneForm, :default_initializer => :milestone_initializer

  def milestone_initializer
    { :milestone => Milestone.new }
  end
end
