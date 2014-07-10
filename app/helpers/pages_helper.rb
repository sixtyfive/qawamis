module PagesHelper
  def arrow_left_options
    title = [t(:page), @page.previous.number].join(' ')
    {class: 'arrow page left', alt: t(:previous_page), title: title}
  end

  def arrow_right_options
    title = [t(:page), @page.next.number].join(' ')
    {class: 'arrow page right', alt: t(:next_page), title: title}
  end

  def page_options
    title = [t(:page), @page.number].join(' ')
  {class: 'page', alt: nil, title: title}
  end
end
