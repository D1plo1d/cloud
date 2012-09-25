require 'fileutils'

class SlicerApiV1Controller < Grape::API
  version 'v1', :using => :header, :vendor => 'DreamForge'
  format :json
  default_format :json

  resource :slicer do


    desc "Runs slic3r with a given configuration on the input file"

    params do
      requires :file, :desc => "The input STL file (must have a stl file extension)"
      requires :config_file, :desc => "The slic3r config file"
    end

    post "/" do
      cad_model = CadModel.create_or_find_cached( params.symbolize_keys )

      status 202
      puts cad_model.id
      {:uuid => cad_model.id.to_s}
    end


    desc <<-eos
      Queries the slic3r job to get it's status or results.

      All responses return json containing at least a warnings entry.

      Returns 500 and an "errors" entry in json there was a slicing error, 
      201 and a "gcode" entry in json if the slicing was successful 
      or 202 if the slicer job is still being processed.
    eos

    get "/:uuid" do
      #puts "geeettttt!!!"
      #puts params["uuid"] + "\n"*2

      cad_model = CadModel.find_by_id(params["uuid"])
      puts cad_model.gcode_status

      output = {:std_io => (cad_model.std_io||"")}

      status case cad_model.gcode_status.to_sym
      when :error 
        500
      when :complete
        output = output.merge :gcode => cad_model.gcode.read, :filament_required => "3651.9mm (25.8cm3)"
        201
      else 
        202
      end
      output
    end


  end
end