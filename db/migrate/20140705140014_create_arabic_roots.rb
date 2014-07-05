class CreateArabicRoots < ActiveRecord::Migration
  def change
    create_table :arabic_roots do |t|
      t.string :name
      t.belongs_to :book, index: true
      t.integer :start_page

      t.timestamps
    end
  end
end
