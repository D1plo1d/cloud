class Api::V1::PrintJobsController < ApplicationController
  inherit_resources

  belongs_to :print_queue, :finder => :find_by_printer_id
  respond_to :json

=begin
  def show
    # GCode Formatted Output
    if params[:format] == "raw" and resource.present?
      send_file resource.g_code.gcode_file.path()
    # JSON Formatted Output
    else
      show!
    end
  end
=end

  def resource_class
    PrintJob
  end

end
