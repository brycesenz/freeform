class MilestoneForm < FreeForm::Form
  form_input_key :milestone
  form_model :milestone
  validate_models
  allow_destroy_on_save
  
  property :name, :on => :milestone
end
