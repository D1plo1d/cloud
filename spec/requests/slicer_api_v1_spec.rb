require "spec_helper"
require 'rack/test'

describe "SlicerApiV1Controller" do
  include Rack::Test::Methods
  include ActionDispatch::TestProcess

  def app
    SlicerApiV1Controller
  end

  #describe "GET render" do

    def post_job
      @input = fixture_file_upload "/stlBase1.stl"
      @config = fixture_file_upload "/config.ini"
      post "/slicer/", :input => @input, :config => @config
      #puts last_response.inspect
    end

    it "should post a slicer job" do
      post_job
      #puts last_response.inspect
      #puts JSON.parse(last_response.body).inspect
      last_response.status.should == 202
    end


    it "should respond with 202 while running a slicer job" do
      post_job
      last_response.status.should == 202
      puts last_response.body
      uuid = JSON.parse(last_response.body)["uuid"]

      puts "uuuiidddsss: #{uuid}"
      puts "/slicer/#{uuid}"
      get "/slicer/#{uuid}"

      puts last_response.inspect
      puts JSON.parse(last_response.body).inspect

      last_response.status.should == 202
      json = JSON.parse(last_response.body)
      json.include?("std_io").should eq(true)
    end


    it "should respond with 201 and gcode when a slicer job is complete" do
      post_job
      last_response.status.should == 202
      uuid = JSON.parse(last_response.body)["uuid"]

      while (last_response.status == 202 ) do
        sleep 1.0
        get "/slicer/#{uuid}"
        puts JSON.parse(last_response.body)["std_io"]
      end

      #puts last_response.inspect
      #puts JSON.parse(last_response.body).inspect

      last_response.status.should == 201
      json = JSON.parse(last_response.body)
      json.include?("std_io").should eq(true)
      json.include?("gcode").should eq(true)
      json.include?("filament_required").should eq(true)
      puts json["gcode"]
    end

  #end
end