Spree::Core::Engine.routes.draw do
  get '/spree_bihang/redirect', :to => "bihang#redirect", :as => :spree_bihang_redirect
  post '/spree_bihang/callback', :to => "bihang#callback", :as => :spree_bihang_callback
  get '/spree_bihang/cancel', :to => "bihang#cancel", :as => :spree_bihang_cancel
  get '/spree_bihang/success', :to => "bihang#success", :as => :spree_bihang_success
end
