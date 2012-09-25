class AddingProfileConfigs < ActiveRecord::Migration
  def change
    add_column :g_code_profiles, :config, :text
    remove_column :g_code_profiles, :config_file
  end
end
