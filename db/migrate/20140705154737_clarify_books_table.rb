class DeambigouisiseBooksTable < ActiveRecord::Migration
  def change
    rename_column :books, :pages, :number_of_pages
  end
end
