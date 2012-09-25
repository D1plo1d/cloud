class GCodeProfilesController < ApplicationController
  inherit_resources
  authorize_inherited_resource

  belongs_to :user, :finder => :find_by_username!
  belongs_to :print_queue, :finder => :find_by_glob!
  respond_to :json

  def create
    authorize! :manage_profiles, print_queue
    create! :notice => "Profile created successfully" do |success, failure|
      failure.html do
        flash[:error] = resource.errors.full_messages.join("<br/>").html_safe
        redirect_to user_print_queue_path(@print_queue.owner, @print_queue)
      end
      success.html do
        redirect_to user_print_queue_path(@print_queue.owner, @print_queue)
      end
    end

  end

  def update
    authorize! :manage_profiles, print_queue
    if resource.update_attributes(params["g_code_profile_#{resource.id}"]) then
      render :nothing => true
    else
      render :status => 500, :json => { :errors => resource.errors }
    end
  end

  def destroy
    authorize! :manage_profiles, print_queue
    resource.destroy
    redirect_to user_print_queue_path(@print_queue.owner, @print_queue)
  end

  def download
    redirect_to resource.config_file.file.url.gsub(/\?.*/, "")
  end

  private

    def print_queue
      @print_queue ||= PrintQueue.find_by_path!(params[:user_id], params[:print_queue_id])
    end

    def resource
      @g_code_profile ||= print_queue.g_code_profiles.where(:id => params[:id]).first
    end

end
