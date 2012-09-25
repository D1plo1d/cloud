class AddInitialSlicerModels < ActiveRecord::Migration
  def change

    create_table :g_codes, :id => false do |t|
      t.binary  :id, :limit => 16, :unique => true

      t.binary  :cad_file_hash, :limit => 512/8
      t.binary  :config_file_hash, :limit => 512/8

      t.string  :type
      t.string  :status

      t.text    :std_io

      t.string  :cad_file
      t.string  :config_file
      t.string  :gcode_file
    end


    create_table :g_code_profiles do |t|
      t.belongs_to :print_queue

      t.string :name

      t.string  :config_file

      t.string :github_user
      t.string :github_repo
      t.string :github_path
    end


    create_table :print_jobs do |t|
      t.binary  :g_code_id, :limit => 16
      t.belongs_to :print_queue
      t.belongs_to :g_code_profile
      t.integer :print_order
      t.integer :copies_total, :default => 1
      t.integer :copies_printed, :default => 0

      t.string :status, :default => :queued
    end


    create_table :print_queues do |t|
      t.belongs_to :owner, :polymorphic => {:default => 'User'}

      t.string :name
      t.string :glob
      t.boolean :public
    end


    create_table :printers, :id => false do |t|
      t.binary :id, :limit => 16, :unique => true
      t.belongs_to :print_queue
      t.string :status, :default => :idle
    end


    create_table :users do |t|
      t.string :username
    end

  end
end
