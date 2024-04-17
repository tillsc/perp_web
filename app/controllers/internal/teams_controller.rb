module Internal
  class TeamsController < ApplicationController

    is_internal!
    respond_to :json, :html

    def index
      @teams = @regatta.teams.preload(:representative)
      @teams = @teams.by_filter(params[:query]) if params[:query].present?
      respond_with @teams
    end

    def show
      @team = @regatta.teams.find(params.extract_value(:id))
      respond_with @team
    end

    def new
      copy_team =  @regatta.teams.find_by(team_id: params[:copy_team]) if params[:copy_team].present?
      @team = @regatta.teams.new(team_params(Team::COPY_FIELDS.inject({}) { |h, f| h.merge(f => copy_team&.send(f)) }))
      @team.name = @team.name.presence || params[:default]&.camelcase
      authorize! :new, Team
      prepare_form
    end

    def create
      @team = @regatta.teams.new(team_params)
      @team.set_team_id
      @team.entry_fee_discount||= 0
      authorize! :create, Team

      if @team.save
        flash[:info] = helpers.success_message_for(:create, @team)
        redirect_to back_or_default_with_uri_params(dialog_finished_with: @team.id)
      else
        flash[:danger] = helpers.error_message_for(:create, @team)
        prepare_form
        render :new
      end
    end

    def edit
      @team = @regatta.teams.find(params.extract_value(:id))
      authorize! :edit, @team
      prepare_form
    end

    def update
      @team = @regatta.teams.find(params.extract_value(:id))
      authorize! :update, @team

      if @team.update(team_params)
        flash[:info] = helpers.success_message_for(:update, @team)
        redirect_to back_or_default
      else
        flash[:danger] = helpers.error_message_for(:update, @team)
        prepare_form
        render :edit
      end
    end

    def destroy
      team = @regatta.teams.find(params.extract_value(:id))
      authorize! :destroy, team

      if team.destroy
        flash[:info] = helpers.success_message_for(:destroy, team)
      else
        flash[:danger] = helpers.error_message_for(:destroy, team)
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      internal_teams_url(@regatta, anchor: @team&.to_anchor)
    end

    def prepare_form
      @representatives = Address.representative.order_existing_first(@regatta)
    end

    def team_params(default = {})
      params.fetch(:team, default).permit(:name, :representative_id, :country, :city, :no_entry_fee, :entry_fee_discount)
    end

  end
end