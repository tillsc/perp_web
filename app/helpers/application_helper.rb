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
    end
    val = block.call(val, record) if block.present?
    content_tag(:dt, record.class.human_attribute_name(attribute)) +
      content_tag(:dd, val&.to_s&.presence || '-')
  end

  def highlight_nobr(s)
    if current_user&.highlight_nobr
      s.to_s.gsub("\u00A0", '␣').html_safe
    else
      s
    end
  end
end
