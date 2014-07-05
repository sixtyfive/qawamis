class ArabicRootsController < ApplicationController
  before_action :set_arabic_root, only: [:show, :edit, :update, :destroy]

  # GET /arabic_roots
  # GET /arabic_roots.json
  def index
    @arabic_roots = ArabicRoot.all
  end

  # GET /arabic_roots/1
  # GET /arabic_roots/1.json
  def show
  end

  # GET /arabic_roots/new
  def new
    @arabic_root = ArabicRoot.new
  end

  # GET /arabic_roots/1/edit
  def edit
  end

  # POST /arabic_roots
  # POST /arabic_roots.json
  def create
    @arabic_root = ArabicRoot.new(arabic_root_params)

    respond_to do |format|
      if @arabic_root.save
        format.html { redirect_to @arabic_root, notice: 'Arabic root was successfully created.' }
        format.json { render :show, status: :created, location: @arabic_root }
      else
        format.html { render :new }
        format.json { render json: @arabic_root.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /arabic_roots/1
  # PATCH/PUT /arabic_roots/1.json
  def update
    respond_to do |format|
      if @arabic_root.update(arabic_root_params)
        format.html { redirect_to @arabic_root, notice: 'Arabic root was successfully updated.' }
        format.json { render :show, status: :ok, location: @arabic_root }
      else
        format.html { render :edit }
        format.json { render json: @arabic_root.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /arabic_roots/1
  # DELETE /arabic_roots/1.json
  def destroy
    @arabic_root.destroy
    respond_to do |format|
      format.html { redirect_to arabic_roots_url, notice: 'Arabic root was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_arabic_root
      @arabic_root = ArabicRoot.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def arabic_root_params
      params.require(:arabic_root).permit(:name, :book_id, :start_page)
    end
end
