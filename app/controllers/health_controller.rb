class HealthController < ApplicationController

  def show
    if ActiveRecord::Base.connection.active?
      render plain: "OK", status: :ok
    else
      render plain: "Database offline", status: :service_unavailable
    end
  end

end