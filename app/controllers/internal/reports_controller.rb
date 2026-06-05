module Internal
  class ReportsController < ApplicationController
    is_internal!

    before_action :load_race_types

    def index
    end

    private

    def load_race_types
      @race_types = Race.for_regatta(@regatta).map(&:type_short).uniq.sort_by(&Parameter.race_sorter)
    end
  end
end
