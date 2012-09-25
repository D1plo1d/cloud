class AddingCadFilesAndGCodeProfileFiles < ActiveRecord::Migration
  def change
    create_table :cad_files do |t|
      t.binary :file_hash, :limit => 512/8
      t.string :file
      t.string :ext_name
    end

    add_index :cad_files, :file_hash, :unique => true, :length => {:file_hash => 512/8}

    create_table :config_files do |t|
      t.binary :file_hash, :limit => 512/8
      t.string :file
    end

    add_index :config_files, :file_hash, :unique => true, :length => {:file_hash => 512/8}

    remove_column :print_jobs, :g_code_id
    change_table :print_jobs do |t|
      t.belongs_to :cad_file
      t.belongs_to :g_code
    end

    change_table :g_code_profiles do |t|
      t.belongs_to :config_file
    end

    drop_table :g_codes

    create_table :g_codes do |t|
      t.belongs_to :config_file
      t.belongs_to :cad_file

      t.string :file

      t.string  :type
      t.string  :status

      t.text    :std_io
    end

    PrintJob.delete_all
    GCode.delete_all
    GCodeProfile.delete_all

  end
end
