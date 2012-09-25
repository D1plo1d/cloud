# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'rubygems'
require 'factory_girl_rails'

FactoryGirl.create(:user, :username => "d1plo1d", :email => "d1plo1d@d1plo1d.com", :password => "test123", :password_confirmation => "test123")
#FactoryGirl.create(:user, :confirmed, :username => "d1plo1d", :email => "d1plo1d@d1plo1d.com", :password => "test123", :password_confirmation => "test123")
#FactoryGirl.create(:user, :with_queues, :confirmed, :username => "d1plo1d", :email => "d1plo1d@d1plo1d.com", :password => "test123", :password_confirmation => "test123")

FactoryGirl.create_list(:user, 3, :confirmed)
#FactoryGirl.create_list(:user, 3, :with_queues, :confirmed)

