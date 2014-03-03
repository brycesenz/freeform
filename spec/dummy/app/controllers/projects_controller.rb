class ProjectsController < ApplicationController
  def new
    @project = Project.new
    @form = project_form(@project)
  end

  def create
    @project = Project.new
    @form = project_form(@project).fill(params[:project])
    render :action => :new
  end

private
  def project_form(project)
    ProjectForm.new(:project => project)
  end
end
