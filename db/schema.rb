# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120918053650) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "cad_files", :force => true do |t|
    t.binary "file_hash", :limit => 255
    t.string "file"
    t.string "ext_name"
  end

  add_index "cad_files", ["file_hash"], :name => "index_cad_files_on_file_hash", :unique => true, :length => {"file_hash"=>64}

  create_table "config_files", :force => true do |t|
    t.binary "file_hash", :limit => 255
    t.string "file"
  end

  add_index "config_files", ["file_hash"], :name => "index_config_files_on_file_hash", :unique => true, :length => {"file_hash"=>64}

  create_table "g_code_profiles", :force => true do |t|
    t.integer "print_queue_id"
    t.string  "name"
    t.string  "github_user"
    t.string  "github_repo"
    t.string  "github_path"
    t.text    "config"
    t.integer "config_file_id"
    t.string  "glob"
  end

  create_table "g_codes", :force => true do |t|
    t.integer "config_file_id"
    t.integer "cad_file_id"
    t.string  "file"
    t.string  "type"
    t.string  "status"
    t.text    "std_io"
  end

  create_table "print_jobs", :force => true do |t|
    t.integer "print_queue_id"
    t.integer "g_code_profile_id"
    t.integer "print_order"
    t.integer "copies_total",      :default => 1
    t.integer "copies_printed",    :default => 0
    t.string  "status",            :default => "queued"
    t.integer "cad_file_id"
    t.integer "g_code_id"
  end

  create_table "print_queues", :force => true do |t|
    t.integer "owner_id"
    t.string  "owner_type", :default => "User"
    t.string  "name"
    t.string  "glob"
    t.boolean "public"
  end

  create_table "printers", :id => false, :force => true do |t|
    t.binary  "id",             :limit => 255
    t.integer "print_queue_id"
    t.string  "status",                        :default => "idle"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "email",                                :default => "", :null => false
    t.string   "encrypted_password",                   :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invitation_token",       :limit => 60
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

end
