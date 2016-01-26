Rails.application.routes.draw do
  get 'home/index'

  root to: 'home#index'

  match "*all" => "application#cors_preflight_check", via: 'options'

  namespace :events do
    resources :submissions, only: :create
  end

  get 'api/guide_progress/:org/:repo', :to => 'api/guide_progress#show'

end
