require "fileutils"
require 'digest/sha1'
#require_dependency "/vagrant/rankedmodel/lib/ranked-model.rb"

class PrintJob < ActiveRecord::Base

  belongs_to :print_queue
  belongs_to :g_code
  belongs_to :g_code_profile
  belongs_to :cad_file

  attr_accessible :status, :print_order_position, :print_order, :copies_printed, :copies_total, :g_code_profile_id, :cad_file_attributes

  accepts_nested_attributes_for :cad_file

  after_initialize :on => :create do
    self.cad_file ||= CadFile.new
  end

  def cad_file_attributes=(cad_file_attrs)
    self.cad_file = CadFile.find_or_create_by_file(cad_file_attrs[:file])
  end

  validates_numericality_of :copies_printed, :equal_to_or_greater_than => 0, :only_integer => true
  validates_numericality_of :copies_total, :greater_than => 0, :only_integer => true

  # Sort Order
  include RankedModel
  ranks :print_order, :with_same => :print_queue_id, :trigger_callbacks => true
  default_scope :order => 'print_order ASC'#, :conditions => ["status != ?", :printed]

  after_initialize :on => :create do
    self.print_order_position = :last #RankedModel::MAX_RANK_VALUE
  end

  #validates :status, :inclusion => { :in => %w(processing ready_to_print printing printed errored) }

  before_validation :on => :create do
    # Set the g_code_profile to the print queue's default profile if none is set
    self.g_code_profile ||= print_queue.g_code_profiles.first
  end

  before_validation do
    # If the g_code_profile changes, swap in the corresponding g_code model
    file_changed if g_code_profile_id_changed? or cad_file_id_changed?
  end

  def file_changed
    self.g_code = GCode.find_or_create_by_config_file_id_and_cad_file_id(g_code_profile.config_file_id, cad_file_id)
    self.status = g_code.status
  end


  # Send out a notification to the subscribed listeners when updating the model

  after_save do
    require File.join Rails.root, "app", "controllers", "push", "print_jobs_push_controller.rb"
    PrintJobsPushController.new(self).update()
  end

  before_destroy do
    require File.join Rails.root, "app", "controllers", "push", "print_jobs_push_controller.rb"
    PrintJobsPushController.new(self).destroy()
  end


  # API
  def as_row
    row_attrs = [:id, :name, :status_html, :copies_total, :print_order]
    row_data = Hash.send :"[]", row_attrs.collect { |sym| [sym, self.send(sym).to_s] }
    if g_code_profile
      row_data.merge :g_code_profile => {:id => g_code_profile.id, :name => g_code_profile.name}
    else
      row_data.merge :g_code_profile => {:id => g_code_profile_id, :name => "Profile Deleted"}
    end
  end


  # Helper methods

  def name
    (cad_file.file.url || cad_file.file.current_path).split("/").last.split("?").first
  end

  def status
    (read_attribute :status).to_sym
  end

  def status_html
    badge_types = {:printed => "badge-success", :printing => "badge-success", :ready_to_print => "badge-warning", :printing_error => "badge-danger", :error => "badge-danger", :processing => ""}

    html = status.to_s.gsub("_", " ").titleize
    html = "#{html} #{copies}" if [:printing, :printed].include? status
    html = "#{copies} printed, errored on #{copies_printed+1} print" if status == :printing_error
    html = "<span class='badge #{badge_types[status]}' data-status='#{status}'>#{html}</span>"
    return html
  end

  def copies
    "#{copies_printed+((self.status == :printed) ? 0 : 1)}/#{copies_total}"
  end
end