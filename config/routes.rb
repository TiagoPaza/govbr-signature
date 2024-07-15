require 'sidekiq/web'

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"

TjceSignature::Application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  # ...
end

Rails.application.routes.draw do
  resources :apis
  resources :groups


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "make_file" => "application#make_file"
  get "prepare_file" => "application#prepare_file"
  post "sign" => "application#sign_file"
  post "pdf/generate" => "application#pdf_generator_worker"
  get "pdf/process" => "application#pdf_process_worker"

  # Defines the root path route ("/")
  # root "posts#index"
end
