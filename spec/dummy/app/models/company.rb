class Company < ActiveRecord::Base
  has_one :project
  
  validates :name, :presence => true
end
