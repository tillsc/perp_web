class StateController < ApplicationController

  def index
    @status = {}
    @status['MySQL Slave Status'] = ActiveRecord::Base.connection.exec_query('SHOW SLAVE STATUS').to_hash[0] || {}
    @status['MySQL Slave Status'][:failure] = @status['MySQL Slave Status']['Slave_IO_Running'] == 'No'
    @status['MySQL Master Status'] = ActiveRecord::Base.connection.exec_query('SHOW MASTER STATUS').to_hash[0] || {}
  end

end