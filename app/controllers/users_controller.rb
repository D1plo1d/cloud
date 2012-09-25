class UsersController < ApplicationController
  inherit_resources
  respond_to :html, :xml, :json

  autocomplete :user, :username

  protected
    def resource
      @user ||= User.find_by_username! params[:id]
    end
end
