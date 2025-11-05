class RatingsController < ApplicationController
  before_action :authenticate_user!

  def create
    @recipe = Recipe.find(params[:recipe_id])  # ← 🔹 esta línea busca la receta
    @rating = @recipe.ratings.find_or_initialize_by(user: current_user)
    @rating.score = rating_params[:score]

    if @rating.save
      redirect_to @recipe, notice: 'Gracias por calificar esta receta.'
    else
      redirect_to @recipe, alert: 'Hubo un error al guardar tu calificación.'
    end
  end

  private

  def rating_params
    params.require(:rating).permit(:score)
  end
end