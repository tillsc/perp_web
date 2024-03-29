module Internal
  class TeamsController < ApplicationController

    is_internal!
    respond_to :json, :html

    def index
      @teams = @regatta.teams
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
      authorize! :new, Team
      prepare_form
    end

    def create
      @team = @regatta.teams.new(team_params)
      @team.set_team_id
      authorize! :create, Team

      if @team.save
        flash[:info] = 'Team angelegt'
        redirect_to back_or_default
      else
        flash[:danger] = "Team konnte nicht angelegt werden:<br>\n#{@team.errors.full_messages.join('<br>')}".html_safe
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
        flash[:info] = 'Team aktualisiert'
        redirect_to back_or_default
      else
        flash[:danger] = "Team konnte nicht gespeichert werden:<br>\n#{@team.errors.full_messages.join('<br>')}".html_safe
        prepare_form
        render :edit
      end
    end

    def destroy
      team = @regatta.teams.find(params.extract_value(:id))
      authorize! :destroy, team

      if team.destroy
        flash[:info] = 'Team gelöscht'
      else
        flash[:danger] = "Team konnte nicht gelöscht:\n#{team.errors.full_messages.join('<br>')}".html_safe
      end
      redirect_to back_or_default
    end

    protected

    def default_url
      anchor = "team#{@team.id}" if @team
      internal_teams_url(@regatta, anchor: anchor)
    end

    def prepare_form
      @representatives = Address.representative.order_existing_first(@regatta)
    end

    def team_params(default = {})
      params.fetch(:team, default).permit(:name, :representative_id, :country, :city, :no_entry_fee, :entry_fee_discount)
    end

  end
end