class RecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe, only: [:show, :destroy]
  def index
    @recipes = Recipe.joins(:chat).where(chats: { user_id: current_user.id })
  end

  def show
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "Receta eliminada correctamente."
  end

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end
end
