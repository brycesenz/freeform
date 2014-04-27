class Project < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  has_many :tasks
  has_many :assignments, :class_name => 'ProjectTask' 
  
  validates :owner, :presence => true
  validates :name, :presence => true
  validates :due_date, :presence => true
end