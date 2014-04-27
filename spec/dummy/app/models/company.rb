class Company < ActiveRecord::Base
  has_one :project, :as => :owner, :inverse_of => :owner
  
  validates :name, :presence => true
end