class Book < ActiveRecord::Base
  has_many :pages
  validates :name, :language, :first_numbered_page, presence: true
  validates :name, uniqueness: {scope: :language}
  
  def cover_page
    pages.first
  end

  def first_page
    pages.first_numbered
  end

  def last_page
    pages.last
  end

  def full_name
    "#{name}_#{language}"
  end

  def human_name
    I18n.t("books.#{full_name}")
  end
end
