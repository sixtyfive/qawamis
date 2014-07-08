class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.integer    :number
      t.string     :last_root
      t.references :book
    end
  end
end
