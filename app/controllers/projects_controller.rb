# coding: utf-8
# frozen_string_literal: true

class InvalidProject < StandardError; end
class SuccessfulProject < StandardError; end
class ProjectsController < ApplicationController
  after_filter :verify_authorized, except: %i[show index video video_embed embed embed_panel about_mobile]
  after_filter :redirect_user_back_after_login, only: %i[index show]
  before_action :authorize_and_build_resources, only: %i[edit]

  has_scope :pg_search, :by_category_id
  has_scope :recent, :expiring, :successful, :in_funding, :recommended, :not_expired, type: :boolean

  helper_method :project_comments_canonical_url, :resource, :collection

  respond_to :html
  respond_to :json, only: %i[index show update]

  before_action :referral_it!

  def index
    respond_to do |format|
      format.html do
        return render_index_for_xhr_request if request.xhr?
      end
      format.atom do
        return render layout: false, locals: { projects: projects }
      end
      format.rss { redirect_to projects_path(format: :atom), status: :moved_permanently }
    end
  end

  def new
    @project = Project.new user: current_user
    authorize @project
    @project.rewards.build
  end

  def create
    @project = Project.new
    @project.attributes = permitted_params.merge(
      user: current_user,
      origin: Origin.process_hash(referral),
      ip_address: current_user.try(:current_sign_in_ip)
    )
    authorize @project
    if @project.save
      redirect_to insights_project_path(@project, locale: '')
    else
      render :new
    end
  end

  def destroy
    authorize resource
    destroy!
  end

  def publish
    authorize resource
  end

  def validate_publish
    authorize resource
    Project.transaction do
      raise InvalidProject unless resource.fake_push_to_online
      raise SuccessfulProject
    end
  rescue InvalidProject
    render status: 400, json: { errors_json: resource.errors.to_json }
  rescue SuccessfulProject
    render status: 200, json: { success: 'OK' }
  end

  def push_to_online
    authorize resource
    resource_action :push_to_online, nil, true
  end

  def surveys
    authorize resource, :update?
  end

  def insights
    authorize resource, :update?
  end

  def posts
    authorize resource, :update?
  end

  def download_reports
    authorize resource, :update?
  end

  def contributions_report
    authorize resource, :update?
  end

  def upload_image
    authorize resource, :update?
    params[:project] = {
      uploaded_image: params[:uploaded_image]
    }

    if resource.update permitted_params
      resource.reload
      render status: 200, json: {
        uploaded_image: resource.uploaded_image.url(:project_thumb)
      }
    else
      render status: 400, json: { errors: resource.errors.full_messages, errors_json: resource.errors.to_json }
    end
  end

  def update
    authorize resource

    # need to check this before setting new attributes
    should_validate = should_use_validate

    resource.localized.attributes = permitted_params
    # can't use localized for fee
    if permitted_params[:service_fee]
      resource.service_fee = permitted_params[:service_fee]
    end

    should_show_modal = resource.online? && resource.mode == 'flex' && resource.online_days_changed?

    if resource.save(validate: should_validate)
      flash[:notice] = t('project.update.success')
      if request.format.json?
        return respond_to do |format|
          format.json { render json: { success: 'OK' } }
        end
      end
    else
      flash[:notice] = t('project.update.failed')
      build_dependencies

      return respond_to do |format|
        format.json { render status: 400, json: { errors: resource.errors.messages.map { |e| e[1][0] }.uniq, errors_json: resource.errors.to_json } }
        format.html { render :edit }
      end
    end

    if params[:cancel_project] == 'true'
      if resource.can_cancel?
        unless resource.project_cancelation.present?
          resource.create_project_cancelation!
          resource.update_columns(
            expires_at: DateTime.now
          )
        end
      else
        flash[:notice] = t('project.update.failed')
      end

      redirect_to insights_project_path(@project)
    elsif should_show_modal
      redirect_to insights_project_path(@project, show_modal: true)
    else
      redirect_to edit_project_path(@project, anchor: params[:anchor] || 'home')
    end
  end

  def show
    resource
    @post ||= resource.posts.where(id: params[:project_post_id].to_i).first if params[:project_post_id].present?
  end

  def video
    project = Project.new(video_url: params[:url])
    render json: project.video.to_json
  rescue VideoInfo::UrlError
    render json: nil
  end

  def embed
    resource
    ref_domain = request.env['HTTP_REFERER'] && URI(request.env['HTTP_REFERER']).host
    render partial: 'card', layout: 'embed', locals: { embed_link: true, ref: (params[:ref] || 'ctrse_embed'), utm_campaign: 'embed_permalink', utm_medium: 'embed', utm_source: ref_domain || 'embed_no_referer' }
  end

  def embed_panel
    resource
    render partial: 'project_embed'
  end

  protected

  def authorize_and_build_resources
    authorize resource
    build_dependencies
  end

  def build_dependencies
    @posts_count = resource.posts.count(:all)
    @user = resource.user
    @user.links.build
    @post =  (params[:project_post_id].present? ? resource.posts.where(id: params[:project_post_id]).first : resource.posts.build)
    @rewards = @project.rewards.rank(:row_order)
    @rewards = @project.rewards.build unless @rewards.present?
  end

  def resource_action(action_name, success_redirect = nil, show_modal = nil)
    if resource.send(action_name)
      if resource.origin.nil? && referral.present?
        resource.update_attribute(
          :origin_id, Origin.process_hash(referral).try(:id)
        )
      end

      flash[:notice] = t("projects.#{action_name}")
      if success_redirect
        redirect_to edit_project_path(@project, anchor: success_redirect, locale: '')
      else
        if show_modal
          redirect_to insights_project_path(@project, online_succcess: true, locale: '')
        else
          redirect_to insights_project_path(@project, locale: '')
        end
      end
    else
      flash.now[:notice] = t("projects.#{action_name}_error")
      build_dependencies
      render :edit
    end
  end

  def render_index_for_xhr_request
    render partial: 'projects/card',
           collection: projects,
           layout: false,
           locals: { ref: 'explore', wrapper_class: 'w-col w-col-4 u-marginbottom-20' }
  end

  def projects
    page = params[:page] || 1
    @projects ||= apply_scopes(Project.visible.order_status)
                  .most_recent_first
                  .includes(:project_total, :user, :category)
                  .page(page).per(18)
  end

  def should_use_validate
    true # resource.valid?
  end

  def permitted_params
    require_model = params.key?(:flexible_project) ? :flexible_project : :project
    params.require(require_model).permit(policy(resource).permitted_attributes)
  end

  def resource
    @project ||= (params[:permalink].present? ? Project.by_permalink(params[:permalink]).first! : Project.find(params[:id]))
  end

  def project_comments_canonical_url
    url = project_by_slug_url(resource.permalink, protocol: 'http', subdomain: 'www').split('/')
    url.delete_at(3) # remove language from url
    url.join('/')
  end
end
