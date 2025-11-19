Rails.application.routes.draw do
  root 'game#show'
  get '/game', to: 'game#show', as: 'game'
  post '/game/choose', to: 'game#choose', as: 'choose_game'
  post '/game/restart', to: 'game#restart', as: 'restart_game'
end
