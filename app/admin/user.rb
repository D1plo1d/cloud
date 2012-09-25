ActiveAdmin.register User do
  index do
    column :username
    column :email
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    column :invitation_sent_at
    column :invitation_accepted_at
    #default_actions
  end

  filter :email
  filter :username

  form do |f|
    f.inputs "User Details" do
      f.input :email
      f.input :username
      f.input :password
      f.input :password_confirmation
    end 
    f.buttons
  end

  action_item  do
    link_to "Invite New Users", new_invitation_admin_users_path
  end

  collection_action :new_invitation do
    @user = User.new
  end

  collection_action :send_invitation, :method => :post do
    flash[:success] = "User has been successfully invited." if User.invite!(params[:user])
    redirect_to admin_users_path
  end

end
