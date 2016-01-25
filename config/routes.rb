Rails.application.routes.draw do
  get 'home/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'

  root to: 'home#index'

  namespace :events do
    resources :submissions, only: :create
  end

  namespace :api do
    resources :guide_progress, only: :show
  end
end
