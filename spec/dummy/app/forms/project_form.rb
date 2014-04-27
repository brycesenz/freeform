class ProjectForm < FreeForm::Form
  form_input_key :project
  form_models :project  
  property :name, :on => :project      

  has_many :tasks do
    form_models :task
	  property :name, :on => :task
	  allow_destroy_on_save

	  has_many :milestones do
	    form_models :milestone
	  	property :name, :on => :milestone  	
	    allow_destroy_on_save  
	  end

	  def milestone_initializer
	    { :milestone => task.milestones.build }
	  end  	
  end

  def task_initializer
    { :task => project.tasks.build }
  end
end
