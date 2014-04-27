class InitialTables < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
    end

    create_table :projects do |t|
      t.references :owner, :polymorphic => true, :null => false
      t.string :name
      t.date :due_date
    end

    create_table :tasks do |t|
      t.references :project, :null => false
      t.string :name
      t.date :start_date
      t.date :end_date
    end

    create_table :milestones do |t|
      t.references :trackable, :polymorphic => true, :null => false
      t.string :name
    end

    create_table :project_tasks do |t|
      t.references :project, :null => false
      t.string :name
    end
  end

  def self.down
    drop_table :companies
    drop_table :projects
    drop_table :tasks
    drop_table :milestones
    drop_table :project_tasks
  end
end