class HomeController < ApplicationController
  respond_to :html

  def index
    if user_signed_in?
      @user = current_user
      render "users/show"
    else
      @container = false
    end
  end

end
