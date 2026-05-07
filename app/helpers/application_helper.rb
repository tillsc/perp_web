module ApplicationHelper

  def participant_state_classes(p)
    return nil unless p

    [].tap do |res|
      res << 'changed' if p.entry_changed?
      res << 'withdrawn' if p.withdrawn?
      res << 'late_entry' if p.late_entry?
      res << 'disqualified' if p.disqualified?
    end.compact.join(' ')
  end
  def success_message_for(action, record)
    t(action, scope: 'helpers.success', model: record.class.model_name.human)
  end

  def error_message_for(action, record)
    s = if action == :destroy
          t(action, scope: 'helpers.failed', model: record.class.model_name.human)
        else
          t('errors.template.header', model: record.class.model_name.human, count: record.errors.count)
        end
    s << '<br><br>'
    s << t('errors.template.body')
    s << '<ul>'
    s << record.errors.map { |err| content_tag(:li, err.full_message) }.join("\n")
    s << '</ul>'
    s.html_safe
  end

  def dl_entry(record, attribute, sub_method: nil, unit: nil, precision: nil, &block)
    val = record.send(attribute)
    val = val.send(sub_method) if sub_method.present?
    if val.is_a?(Numeric)
      val = number_with_precision(val, precision: precision) if precision
      val = "#{val}&thinsp;#{unit}".html_safe if unit
    elsif val === true
      val = I18n.t("helpers.yes")
    elsif val === false
      val = I18n.t("helpers.no")
    elsif val.is_a?(String)
      val = highlight_nobr(val)
    end
    val = block.call(val, record) if block.present?
    content_tag(:dt, record.class.human_attribute_name(attribute)) +
      content_tag(:dd, val&.to_s&.presence || '-')
  end

  def highlight_nobr(s)
    return s unless current_user&.highlight_nobr

    str = s.to_s
    was_html_safe = str.html_safe?

    breakables = '[ \t\n​  ]'
    nobr_tokens = /(?<!#{breakables})( | |&thinsp;|&nbsp;)(?!#{breakables})/

    result = str.gsub(nobr_tokens, '␣')

    was_html_safe ? result.html_safe : result
  end

  def rower_link_proc(link_to_options: {}, rower_url_options: {}, rower_name_options: {})
    -> (rower) do
      link_to(rower.name(no_year_of_birth: true, **rower_name_options), rower_path(@regatta, rower, **rower_url_options), **link_to_options).tap do |s|
        s << "\u202F(#{rower.year_of_birth})" if rower.year_of_birth.present?
      end
    end
  end

  def internal_rower_link_proc(link_to_options: {}, rower_url_options: {}, rower_name_options: { no_nobr: true })
    -> (rower) do
      link_to(highlight_nobr(rower.name(no_year_of_birth: true, **rower_name_options)), internal_rower_path(@regatta, rower, **rower_url_options), **link_to_options).tap do |s|
        s << "\u202F(#{rower.year_of_birth})" if rower.year_of_birth.present?
      end
    end
  end

  def current_url_with_anchor(o)
    if o.is_a?(ActiveRecord::Base)
      o = ActionView::RecordIdentifier.dom_id(o)
    end
    u = URI.parse(current_url.to_s)
    u.fragment = o
    u.to_s
  end

  def summarize_ranges(numbers)
    numbers.sort
           .slice_when { |a, b| b != a + 1 }
           .map { |range| range.size > 1 ? "#{range.first}–#{range.last}" : range.first.to_s }
           .join(', ')
  end
  module_function :summarize_ranges

  MEDALS = ['🥇', '🥈', '🥉'].freeze

  def medal_for(rank)
    MEDALS[rank - 1] if rank
  end
end
