class ReAddFirstNumberedPageToBooks < ActiveRecord::Migration
  def change
    add_column :books, :first_numbered_page, :integer
  end
end
