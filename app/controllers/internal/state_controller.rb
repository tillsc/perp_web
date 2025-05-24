module Internal
  class StateController < ApplicationController

    is_internal!

    def index
      authorize! :show, :server_status

      @status = {
        ENV: ENV.map { |k, v|  [k, k.to_s =~ /PASSWORD|SECRET/i ? "****" : v] }.to_h
      }
      begin
        @status['MySQL Slave Status'] = ActiveRecord::Base.connection.exec_query('SHOW SLAVE STATUS').to_a[0] || {}
        io_state = @status['MySQL Slave Status']['Slave_IO_Running']
        @status['MySQL Slave Status'][:failure] = io_state.present? && (io_state != 'Yes') && @status['MySQL Slave Status']['Slave_IO_State'] != '-'
        @status['MySQL Master Status'] = ActiveRecord::Base.connection.exec_query('SHOW MASTER STATUS').to_a[0] || {}
      rescue ActiveRecord::StatementInvalid
      end
    end

  end
end