class PrintQueuesController < ApplicationController
  inherit_resources
  authorize_inherited_resource

  belongs_to :user, :finder => :find_by_username!
  respond_to :html, :xml, :json


  def create
    authorize! :create_print_queues, parent
    create! do |success, failure|
      failure.html do
        flash[:error] = resource.errors.full_messages.join("<br/>").html_safe
        redirect_to @user
      end
    end
  end


  def show
    unless ( can?(:manage_printers, resource) and can?(:manage_profiles, resource) ) or resource.g_code_profiles.present?
      raise ActionController::RoutingError.new('Not Found')
    end

    @tabs = ["Print Queue", "Slic3r Profiles"]
    @tabs.push "Users and Permissions" if can?(:manage_users, resource)

    @tabs = Hash[ @tabs.map{ |t| [t.downcase.gsub(" ", "_"), t] } ]
    @active_tab = "print_queue"

    super
  end


  def add_role
    authorize! :manage_users, resource
    @new_member = User.find_by_username!(params[:role][:user])
    role_sym = (params[:role][:name] || :member).to_sym

    @role = @new_member.configure_with_role(role_sym.to_sym, resource)

    render :nothing => true
  end


  def delete_role
    authorize! :manage_users, resource
    @member = User.find_by_username! params[:role][:user]
    @member.remove_role :member, resource
    @member.remove_role :admin, resource

    render :nothing => true
  end


  protected
    def resource
      begin
        @print_queue ||= PrintQueue.find_by_path!(params[:user_id], params[:id])
      rescue
        raise ActionController::RoutingError.new('Not Found')
      end
    end
end
