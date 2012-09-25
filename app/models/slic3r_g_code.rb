require "fileutils"
require "open3"

class Slic3rGCode < GCode

  def self.perform(id)
    find_by_id(id).perform
  end

  def perform
    # Running Slic3r on cached local copies of each file
    results = Slic3r.current_version.slice(cad_file.file.to_file.path, config_file.file.to_file.path)
    results.each {|k,v| self.send(:"#{k}=", v)}
    self.save!
  end

end