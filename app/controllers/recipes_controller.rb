class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :destroy, :update_rating]

  def index
    @categories = current_user.recipes.distinct.pluck(:category)
    @recipes = current_user.recipes

    # Filtrar por categoría (si hay parámetro)
    if params[:category].present?
      @recipes = @recipes.where(category: params[:category])
    end

    # Filtrar por fecha (si hay parámetro)
    if params[:rating].present?
      @recipes = @recipes.where("rating >= ?", params[:rating].to_i)
    end
  end

   def update_rating
      if @recipe.update(recipe_params)
        redirect_to @recipe, notice: "Calificación actualizada correctamente."
      else
        redirect_to @recipe, alert: "No se pudo actualizar la calificación."
      end
    end

    def show
    end

    def create
      @recipe = current_user.recipes.build(recipe_params)

      if @recipe.save
        redirect_to recipes_path, notice: "Receta guardada correctamente."
      else
        redirect_back fallback_location: chat_path(@recipe.chat_id), alert: "No se pudo guardar la receta."
      end
    end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "Receta eliminada correctamente.", status: :see_other
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :content, :ingredients, :category, :chat_id, :rating)
  end
  
end
