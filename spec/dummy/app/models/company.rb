class Company < ActiveRecord::Base
  has_one :project
end
