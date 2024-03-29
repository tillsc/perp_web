module ApplicationHelper

  def participant_state_classes(p)
    [].tap do |res|
      res << 'changed' if p.entry_changed?
      res << 'withdrawn' if p.withdrawn?
      res << 'late_entry' if p.late_entry?
    end.compact.join(' ')
  end
  def success_message_for(action, record)
    t(action, scope: 'helpers.success', model: record.class.model_name.human)
  end

  def error_message_for(action, record)
    if action == :destroy
      t(action, scope: 'helpers.failed', model: record.class.model_name.human)
    else
      s = t('errors.template.header', model: record.class.model_name.human, count: record.errors.count)
      s << '<br><br>'
      s << t('errors.template.body')
      s << '<ul>'
      s << record.errors.map { |err| content_tag(:li, err.full_message) }.join("\n")
      s << '</ul>'
      s.html_safe
    end
  end

  def dl_entry(record, attribute, sub_method = nil, &block)
    val = record.send(attribute)
    val = val.send(sub_method) if sub_method.present?
    val = block.call(val) if block.present?
    content_tag(:dt, record.class.human_attribute_name(attribute)) +
      content_tag(:dd, val&.to_s&.presence || '-')
  end
end
