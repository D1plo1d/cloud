class ApplicationController < ActionController::Base
  protect_from_forgery

  def self.authorize_inherited_resource
    before_filter do
      action_roles = {:update => :edit, :destroy => :destroy}
      action_sym = action_name.to_sym

      if action_roles.include?(action_sym)
        authorize! action_roles[action_sym], resource
      end
    end
  end

  def authenticate_admin_user! #use predefined method name
    if ( user_signed_in? && !current_user.has_role?(:admin) )
      raise ActionController::RoutingError.new('Not Found')
    end
    authenticate_user!
  end 

  def current_admin_user #use predefined method name
    return nil if user_signed_in? && !current_user.has_role?(:admin)
    current_user
  end

end
