class AddCategoryIdToDruginfos < ActiveRecord::Migration
  def change
    add_column :druginfos, :category_id, :integer
  end
end
