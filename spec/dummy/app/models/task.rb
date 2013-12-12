class Task < ActiveRecord::Base
  belongs_to :project
  has_many :milestones
  
  validates :start_date, :presence => true
end
