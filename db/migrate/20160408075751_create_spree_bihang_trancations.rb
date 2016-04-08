class CreateSpreeBihangTrancations < ActiveRecord::Migration
  def change
    create_table :spree_bihang_trancations do |t|
    	t.string :button_id
    	t.string :order_id
    	t.string :secret_token
    end
  end
end
