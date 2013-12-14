class Task < ActiveRecord::Base
  belongs_to :project
  has_many :milestones
  
  validates :project, :presence => true
  validates :start_date, :presence => true
end
