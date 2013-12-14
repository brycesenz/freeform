class Project < ActiveRecord::Base
  belongs_to :company
  has_many :tasks
  has_many :assignments, :class_name => 'ProjectTask' 
  
  validates :company, :presence => true
  validates :name, :presence => true
  validates :due_date, :presence => true
end
