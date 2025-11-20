Rails.application.routes.draw do
  root 'story_generator#new'
  
  # Story generation
  get '/generate', to: 'story_generator#new', as: 'new_story_generator'
  post '/generate', to: 'story_generator#create', as: 'create_story'
  
  # Game play
  get '/game', to: 'game#show', as: 'game'
  post '/game/choose', to: 'game#choose', as: 'choose_game'
  post '/game/restart', to: 'game#restart', as: 'restart_game'
end
