class AddUsernameToHashedUser < ActiveRecord::Migration[5.0]
  def change
    add_column :hashedusers, :username, :string
  end
end
