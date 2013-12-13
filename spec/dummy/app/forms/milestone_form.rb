class MilestoneForm < FreeForm::Form
  form_models :milestone
  property :name, :on => :milestone
end