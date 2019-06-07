class StateController < ApplicationController

  def index
    @status = {}
    @status['MySQL Slave Status'] = ActiveRecord::Base.connection.exec_query('SHOW SLAVE STATUS').to_hash[0] || {}
    io_state = @status['MySQL Slave Status']['Slave_IO_Running']
    @status['MySQL Slave Status'][:failure] = io_state.present? && (io_state != 'Yes')
    @status['MySQL Master Status'] = ActiveRecord::Base.connection.exec_query('SHOW MASTER STATUS').to_hash[0] || {}
  end

end