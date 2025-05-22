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

    breakables = '[ \t\n\u200B\u2028\u2029]'
    nobr_tokens = /(?<!#{breakables})(\u00A0|\u2009|&thinsp;|&nbsp;)(?!#{breakables})/

    result = str.gsub(nobr_tokens, '␣')

    was_html_safe ? result.html_safe : result
  end

  def current_url_with_anchor(o)
    if o.respond_to?(:to_anchor)
      o = o.to_anchor
    end
    u = URI.parse(current_url.to_s)
    u.fragment = o
    u.to_s
  end
end
