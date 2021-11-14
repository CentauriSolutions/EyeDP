# frozen_string_literal: true

module ApplicationHelper
  def asset_available?(logical_path)
    if Rails.configuration.assets.compile
      Rails.application.precompiled_assets.include? logical_path
    else
      Rails.application.assets_manifest.assets[logical_path].present?
    end
  end

  def current_page_params
    # Modify this list to whitelist url params for linking to the current page
    request.params.slice('sort_dir', 'sort_by', 'filter_by', 'filter')
  end

  def nav_link(link_text, link_path, base_class = '')
    # if link_path == admin_groups_path
    # binding.pry
    # end
    current_page = current_page?(link_path)
    class_name = 'nav-item'
    class_name = [base_class, class_name].join(' ')
    tag.li(class: class_name) do
      link_to link_text, link_path, class: current_page ? 'nav-link active' : 'nav-link'
    end
  end

  def dropdown_nav_link(link_text, link_path, base_class = '')
    # if link_path == admin_groups_path
    # binding.pry
    # end
    current_page = current_page?(link_path)
    class_name = 'dropdown-item'
    class_name_parts = [base_class, class_name]
    class_name_parts << 'active' if current_page
    class_name = class_name_parts.join(' ')
    # tag.li(class: class_name) do
    link_to link_text, link_path, class: class_name
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def settings_row(head, subline, options = {}, &block)
    options.reverse_merge!(width: 9)

    heading = if options.key?(:decorate)
                tag.h3(head, class: (options[:decorate]).to_s)
              else
                tag.h3(head)
              end
    heading_subline = if options.key?(:decorate)
                        tag.p(subline, class: "text-muted #{options[:decorate]}")
                      else
                        tag.p(subline, class: 'text-muted')
                      end
    content = if options.key?(:id)
                tag.div(class: "col-lg-#{options[:width]}", id: options[:id], &block)
              else
                tag.div(class: "col-lg-#{options[:width]}", &block)
              end

    tag.div(class: 'row') do
      tag.div(class: 'col-lg-3') do
        heading + heading_subline
      end +
        content
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
