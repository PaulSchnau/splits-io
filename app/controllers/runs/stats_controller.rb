class Runs::StatsController < ApplicationController
  before_action :set_run, only: [:index]

  def index
  end

  private

  def set_run
    @run = Run.find_by(id: params[:run_id].to_i(36)) || Run.find_by!(nick: params[:run_id])
    gon.run = {id: @run.id, splits: @run.reduced_splits}
    gon.scale_to = @run.time
  rescue ActionController::UnknownFormat, ActiveRecord::RecordNotFound
    render :not_found, status: 404
  end
end
