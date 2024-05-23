class AddUserNameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :user_name, :string
  end
end
