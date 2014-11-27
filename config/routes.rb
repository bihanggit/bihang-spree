Spree::Core::Engine.routes.draw do
  get '/spree_oklink/redirect', :to => "oklink#redirect", :as => :spree_oklink_redirect
  post '/spree_oklink/callback', :to => "oklink#callback", :as => :spree_oklink_callback
  get '/spree_oklink/cancel', :to => "oklink#cancel", :as => :spree_oklink_cancel
  get '/spree_oklink/success', :to => "oklink#success", :as => :spree_oklink_success
end
