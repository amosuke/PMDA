class CreateDruginfo < ActiveRecord::Migration
  def change
    create_table :druginfos do |t|
      t.text :url
      t.string :name
      t.timestamps null: false
    end
  end
end
