class TaskForm < FreeForm::Form
  form_models :task
  property :name, :on => :task
  allow_destroy_on_save

  has_many :milestones, :initializer => :milestone_initializer do
    form_models :milestone
	property :name, :on => :milestone  	
    allow_destroy_on_save
    
  end

  def milestone_initializer
    { :milestone => Milestone.new }
  end
end
