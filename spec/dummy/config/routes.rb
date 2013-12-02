Dummy::Application.routes.draw do
  resources :companies, :only => %w(new create)
  resources :projects, :only => %w(new create)
  get '/:controller/:action'
end
