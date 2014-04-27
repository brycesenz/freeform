class Milestone < ActiveRecord::Base
  belongs_to :trackable, :polymorphic => true

  validates :trackable, :presence => true
  validates :name, :presence => true
end