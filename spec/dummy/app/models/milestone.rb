class Milestone < ActiveRecord::Base
  belongs_to :task

  validates :task, :presence => true
  validates :name, :presence => true
end
