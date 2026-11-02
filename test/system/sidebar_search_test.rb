require 'application_system_test_case'

class SidebarSearchTest < ApplicationSystemTestCase
  test 'switching books after a search uses the latest search result' do
    visit '/hw5_de/1084' # كتب
    check 'terms_agreed'
    assert_no_selector '#terms_dialog', visible: true

    fill_in 'search', with: 'br'
    find('#search_form button[type=submit]').click
    assert_selector '#page[data-number="75"]', wait: 10

    find('#sidebar input[type=radio][value=hw4_en]').ancestor('li').click

    assert_selector '#book[data-slug="hw4_en"] #page[data-number="61"]', wait: 10
  end
end
