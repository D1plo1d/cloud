class AddingGlobsToGCodeProfiles < ActiveRecord::Migration
  def change
    add_column :g_code_profiles, :glob, :string
    GCodeProfile.all.each {|g| g.save!} # automatically adds a glob to each gcode profile
  end
end
