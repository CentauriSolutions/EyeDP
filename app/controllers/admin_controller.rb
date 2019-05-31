class AdminController < ApplicationController
  before_action :ensure_user_is_admin!
  before_action :set_model, only: [:show, :edit, :update, :destroy]
  # GET /admin/#{model}
  # GET /admin/#{model}.json
  def index
    @model = model.all
  end

  # GET /admin/#{model}/1
  # GET /admin/#{model}/1.json
  def show
  end

  # GET /admin/#{model}/new
  def new
    @model = model.new
  end

  # GET /admin/#{model}/1/edit
  def edit
  end

  # POST /admin/#{model}
  # POST /admin/#{model}.json
  def create
    @admin_group = model.new(admin_group_params)

    respond_to do |format|
      if @admin_group.save
        format.html { redirect_to @admin_group, notice: 'Group was successfully created.' }
        format.json { render :show, status: :created, location: @admin_group }
      else
        format.html { render :new }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/#{model}/1
  # PATCH/PUT /admin/#{model}/1.json
  def update
    respond_to do |format|
      if @admin_group.update(admin_group_params)
        format.html { redirect_to @admin_group, notice: 'Group was successfully updated.' }
        format.json { render :show, status: :ok, location: @admin_group }
      else
        format.html { render :edit }
        format.json { render json: @admin_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/#{model}/1
  # DELETE /admin/#{model}/1.json
  def destroy
    @admin_group.destroy
    respond_to do |format|
      format.html { redirect_to admin_groups_url, notice: 'Group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  private

    # Use callbacks to share common setup or constraints between actions.
  def set_model
    @model = model.find(params[:id])
  end

  def ensure_user_is_admin!
    render status: 404 and return \
      unless current_user and current_user.admin?
  end
end
