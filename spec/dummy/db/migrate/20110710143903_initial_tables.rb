class InitialTables < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
    end

    create_table :projects do |t|
      t.integer :company_id
      t.string :name
    end

    create_table :tasks do |t|
      t.integer :project_id
      t.string :name
    end

    create_table :milestones do |t|
      t.integer :task_id
      t.string :name
    end

    create_table :project_tasks do |t|
      t.integer :project_id
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
