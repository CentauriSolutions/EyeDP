# frozen_string_literal: true

module ApplicationHelper
  def nav_link(link_text, link_path, base_class = '')
    # if link_path == admin_groups_path
    # binding.pry
    # end
    current_page = current_page?(link_path)
    class_name = 'nav-item'
    class_name = [base_class, class_name].join(' ')
    content_tag(:li, class: class_name) do
      link_to link_text, link_path, class: current_page ? 'nav-link active' : 'nav-link'
    end
  end
end
