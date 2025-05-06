class TvSwitcherChannel < ApplicationCable::Channel

  def subscribed
    stream_from "tv_switcher"
  end

end
