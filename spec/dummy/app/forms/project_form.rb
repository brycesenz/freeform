class ProjectForm < FreeForm::Form
  form_input_key :project
  form_models :project
#  validate_models
#  allow_destroy_on_save
  
  property :name, :on => :project      
#  property :email,    :on => :user
#  property :street, :on => :address      
#  property :city,   :on => :address      
#  property :state,  :on => :address      

  has_many :tasks, :class_initializer => :task_initializer do
    form_model :task
    validate_models
    allow_destroy_on_save
    
    attr_accessor :name
#    property :name, :on => :task


    has_many :milestones, :class_initializer => :milestone_initializer do
      form_model :milestone
      validate_models
      allow_destroy_on_save
      
      attr_accessor :name
    end
  end
end
