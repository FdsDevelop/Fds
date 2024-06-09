class CreateFdssApiKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :fdss_api_keys do |t|
      t.string :serial, null: false
      t.string :secret, null: false
      t.text :sign, null: false

      t.timestamps
    end
  end

end
