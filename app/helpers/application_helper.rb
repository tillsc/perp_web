module ApplicationHelper

  def participant_state_classes(p)
    [].tap do |res|
      res << 'changed' if p.entry_changed?
      res << 'withdrawn' if p.withdrawn?
      res << 'late_entry' if p.late_entry?
    end.compact.join(' ')
  end

end
