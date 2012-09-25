class PrintJobsController < ApplicationController
  inherit_resources
  authorize_inherited_resource

  belongs_to :user, :finder => :find_by_username!
  belongs_to :print_queue, :finder => :find_by_glob!
  respond_to :json
  actions :create, :update, :destroy


  def destroy
    resource.destroy
    render :nothing => true, :status => 204
  end

  def create
    authorize! :manage_print_jobs, parent
    #raise params[:print_job].inspect
    #raise params[:print_job][:g_code].inspect

    # Splinning off a print job for each g_code file uploaded
    params["print_job"]["cad_file_attributes"]["file"].each do |f|
      cad_file_attrs = params["print_job"]["cad_file_attributes"].merge "file" => f
      @print_job = parent.print_jobs.create params["print_job"].merge "cad_file_attributes" =>  cad_file_attrs
    end
    render :nothing => true
  end

  def index
    render :json => {:print_jobs => collection.collect(&:as_row)}
  end

  def show_modal
    render :locals => {:print_job => resource}, :partial => "print_jobs/view_print_job_modal"
  end

  def download
    case params[:format]
      when "original" then redirect_to resource.cad_file.file.url.gsub(/\?.*/, "")
      when "gcode" then redirect_to resource.g_code.file.url.gsub(/\?.*/, "")
      else
        raise "bad format"
    end
  end
end
