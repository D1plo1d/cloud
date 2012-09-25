class PrintQueue < ActiveRecord::Base
  resourcify

  has_many :print_jobs, :dependent => :destroy
  has_many :g_codes, :through => :print_jobs
  has_many :printers, :dependent => :destroy
  has_many :g_code_profiles, :dependent => :destroy

  # Can belong to either a user or a group (TODO: groups)
  belongs_to :owner, :polymorphic => true

  attr_accessible :name, :glob

  # public printers are accessible on the Local Area Network to all users
  attr_accessible :public

  validates_uniqueness_of :name, :scope => [:owner_id, :owner_type], :message => "A printer with this url already exists"
  validates_uniqueness_of :glob, :scope => [:owner_id, :owner_type], :message => "^A printer with this name already exists"
  validates :name, :presence => true, :length => { :in => 1..35 }

  def self.find_by_path!(user_glob, glob)
    # TODO: reduce this down to 1 sql call
    owner = User.find_by_username!( user_glob )
    print_queue = PrintQueue.where( :glob => glob, :owner_id => owner.id, :owner_type => owner.class.to_s ).first
    raise "Print queue does not exist" if print_queue.blank?
    print_queue
  end

  def self.find_by_printer_id(id)
    Printer.find_by_id(id).print_queue
  end

  before_save do
    self.glob = name.urlize
  end

  after_save :on => :create do
    # Create a printer token with each new print queue
    self.printers.create() if self.printers.empty?
    self.g_code_profiles.create(:name => "Default") if self.g_code_profiles.empty?
  end

  # owner roles

  attr_accessor :old_owner

  def owner=(new_owner)
    self.old_owner = self.owner
    self.owner = new_owner
  end

  after_save do
    role = self.owner.configure_with_role(:owner, self, :validate_role => false) if self.owner.present?
    self.old_owner.remove_role(:owner, self) if self.old_owner.present?
  end


  def to_s
    name
  end

  def to_param
    glob
  end

  def pub_sub_channel
    File.join "/", self.owner.username, self.glob
  end

  def user_roles
    [:member, :admin]
  end
end