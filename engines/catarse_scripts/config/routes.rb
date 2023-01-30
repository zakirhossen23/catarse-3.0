# frozen_string_literal: true

CatarseScripts::Engine.routes.draw do
  resources :scripts do
    post :execute, on: :member
  end
end
