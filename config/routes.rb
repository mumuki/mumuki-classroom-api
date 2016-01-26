Rails.application.routes.draw do
  get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  root to: 'home#index'

  namespace :events do
    resources :submissions, only: :create
  end

  get 'api/guide_progress/:org/:repo', :to => 'api/guide_progress#show'

end
