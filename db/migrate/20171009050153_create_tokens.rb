class CreateTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :tokens do |t|
      t.string :name
      t.string :symbol
      t.decimal :totalTokens
      t.decimal :balanceTokens
      t.string :owner_id
      t.timestamps
    end
  end
end