require "devise_invitable/model"

class User < ActiveRecord::Base

  # Roles and Permissions
  # ---------------------------------------------------------------------

  rolify

  def configure_with_role(role_sym, resource, opts = {:validate_role => true})
    if resource.present? and opts[:validate_role]
      raise "Invalid Role" unless resource.user_roles.include?(role_sym)
    end

    # Add the new role
    role = self.add_role role_sym, resource

    # Remove any other roles this user has for the resource
    if resource.present?
      resource.user_roles.reject{|r| r == role_sym}.each do |other_role_sym|
        self.remove_role other_role_sym, resource
      end
    end

    return role
  end


  # Devise Authentication
  # ---------------------------------------------------------------------

  attr_accessible :email, :password, :password_confirmation, :username

  devise :invitable, :database_authenticatable, :registerable, :lockable, :recoverable,
           :rememberable, :trackable, :validatable,
           #:confirmable, :allow_unconfirmed_access_for => 1.day,
           :authentication_keys => [:login]


  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login
  attr_accessible :login
  validates_uniqueness_of :username, :allow_blank => true
  validates_uniqueness_of :email

  has_many :print_queues, :as => "owner", :dependent => :destroy

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end


  # Instance Methods
  # ---------------------------------------------------------------------

  # show the gravatar image for a profile - based on their email
  def gravatar_url(size = 100)
    email_md5 = Digest::MD5.hexdigest(email).to_s
    "http://www.gravatar.com/avatar/#{email_md5}?s=#{size}&d=mm"
  end

  def to_s
    username
  end

  def to_param
    username
  end

end
