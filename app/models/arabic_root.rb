class ArabicRoot < ActiveRecord::Base
  belongs_to :book
  
  # belongs_to :page
  # (Only one since we only care about the page the root starts on!)

  def page
    Page.find(self.book, self.start_page)
  end
end
