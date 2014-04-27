class Task < ActiveRecord::Base
  belongs_to :project
  has_many :milestones, :as => :trackable, :inverse_of => :trackable
  
  validates :project, :presence => true
  validates :start_date, :presence => true
end