class ProjectsController < ApplicationController
  def new
    @project = Project.new
    @form = project_form(@project)
  end
  
private
  def project_form(project)
    ProjectForm.new(:project => project)
  end  
end
