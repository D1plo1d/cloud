FactoryGirl.define do

  factory :cad_file do
    sequence(:file) do |n|
      basename = ["40mmcube", "5mm_Calibration_Steps", "stlBase1"][n%3-1]
      File.open(File.join Rails.root, "spec", "fixtures", "#{basename}.stl")
    end
  end

end