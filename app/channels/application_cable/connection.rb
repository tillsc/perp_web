module ApplicationCable
  class Connection < ActionCable::Connection::Base

    rescue_from StandardError, with: :report_error

    private

    def report_error(e)
      Sentry.capture_message(e)
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace.join("\n"))
    end

  end
end
