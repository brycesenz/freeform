class Project < ActiveRecord::Base
  has_many :tasks
  has_many :assignments, :class_name => 'ProjectTask' 
  
  validates :name, :presence => true
  validates :due_date, :presence => true
end
