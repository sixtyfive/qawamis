class AddLanguageColumnToBooks < ActiveRecord::Migration
  def change
    add_column :books, :language, :string, limit: 2
  end
end
