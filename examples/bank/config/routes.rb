Bank::Application.routes.draw do
  get "accounts/:id/withdraw" => "accounts#withdraw_form", :as => :account_withdraw_form
  post "accounts/:id/withdraw" => "accounts#withdraw", :as => :account_withdraw
  
  get "accounts/:id/deposit" => "accounts#deposit_form", :as => :account_deposit_form
  post "accounts/:id/deposit" => "accounts#deposit", :as => :account_deposit

  get "accounts/transfer" => "accounts#transfer_form", :as => :account_transfer_form
  post "accounts/transfer" => "accounts#transfer", :as => :account_transfer
  
  root :to => "accounts#index"
end
