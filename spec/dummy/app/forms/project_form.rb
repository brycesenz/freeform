class ProjectForm < FreeForm::Form
  form_input_key :project
  form_models :project  
  property :name, :on => :project      

#  has_many :tasks, :class => ::TaskForm, :default_initializer => :task_initializer

#  def task_initializer
#    { :task => Task.new }
#  end
end
