devise_for :admin_users, skip: :all
devise_scope :admin_user do
  get 'admin/login' => 'admin/admin_users/sessions#new', as: :new_admin_user_session
  post 'admin/login' => 'admin/admin_users/sessions#create', as: :admin_user_session
  delete 'admin/logout' => 'admin/admin_users/sessions#destroy', as: :destroy_admin_user_session
  get 'admin_users/edit' => 'admin/admin_users/registrations#edit', as: :edit_admin_user_registration
  put 'admin_users' => 'admin/admin_users/registrations#update', as: :admin_user_registration
end

namespace 'admin' do
  resources :admin_users
  devise_scope  :admin_user do root :to => 'admin_users/sessions#new', as: :unauthenticated_root end
end
