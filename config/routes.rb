CloudSlicer::Application.routes.draw do
  ActiveAdmin.routes(self)

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Slicer API
  #require File.join Rails.root, "app", "controllers", "slicer_api_v1_controller.rb"
  #mount SlicerApiV1Controller => "/api/"


  # Resque Admin Interface
  require 'resque/server'
  mount Resque::Server.new, :at => "/admin/resque"

  root :to => "home#index"


  # Devise Authentication
  devise_for :users, :path => '/', :path_names => {:registration => "register"}

  get 'autocomplete/user' => 'users#autocomplete_user_username'


  # Print Client API Routes
  #get "/api/v1/:id" => "api/v1/print_queues#show"
  namespace :api do
    namespace :v1 do # TODO: :constraints => {:subdomain => "admin"}
      resource :print_queues, :path => "/:print_queue_id", :only => [:show, :update] do
        match "load_next_job"
        match "start_printing"
        match "finish_printing"
        get "print_jobs" => "print_jobs#index"
        resource :print_jobs, :path => "print_jobs/:id", :only => [:show, :update]
      end
    end
  end


  # Github style user and print queue routes
  resources :users, :path => "/", :except => :index do

    resources :print_queues, :path => "/", :except => :index do
      match "add_role", :on => :member
      match "delete_role", :on => :member

      resources :print_jobs, :only => [:create, :update, :destroy, :index, :show_modal] do
        member do
          get "show_modal"
          get "download"
        end
      end

      resources :g_code_profiles do
        member do
          get "download"
        end
      end

    end

  end

end
