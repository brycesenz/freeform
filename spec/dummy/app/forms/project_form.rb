class ProjectForm < FreeForm::Form
  form_input_key :project
  form_models :project  
  property :name, :on => :project      

  has_many :tasks, :default_initializer => :task_initializer do
    form_model :task    
    property :name, :on => :task

    has_many :milestones, :default_initializer => :milestone_initializer do
      form_model :milestone
      validate_models
      allow_destroy_on_save
      
      property :name, :on => :milestone
    end
  end
  
  def task_initializer
    { :task => Task.new }
  end

  def milestone_initializer
    { :milestone => Milestone.new }
  end
end
