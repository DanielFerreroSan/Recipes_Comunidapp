class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params) #Acá va el mensaje del User
    @message.user = current_user
    @message.role = "user"

    if @message.save
        ruby_llm_chat = RubyLLM.chat
        response = ruby_llm_chat.with_instructions(user_prompt(current_user)).ask("Tengo estos ingredientes: #{@message.content}")  #acá agrego el user prompt definido en el método privado

        ia_user = User.find_or_create_by(email: "ia@recipes.com") do |u|  #este método genera un usuario de IA
        u.password = SecureRandom.hex(10)
        end

      @chat.messages.create(content: response.content, role: "assistant", user_id: nil)  #Guardo la respuesta
      redirect_to chat_path(@chat), notice: "Receta generada correctamente."

    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end


def user_prompt(user)
  age = user.age.presence || "no especificada"
  gender = user.gender.presence || "no especificado"
  weight = user.weight.present? ? "#{user.weight} kg" : "no especificado"
  height = user.height.present? ? "#{user.height} cm" : "no especificada"
  activity = user.activity.presence || "no especificado"
  restrictions = user.restrictions.presence || "ninguna restricción"
  time_of_day = case Time.current.hour                                 #con esta función determino si va a realizar un desayuno/almuerzo/merienda/cena
                when 5..10 then "desayuno"
                when 11..16 then "almuerzo"
                when 17..19 then "merienda"
                else "cena"
                end

  <<~PROMPT
    Eres un chef experimentado especializado en improvisar platos saludables con los ingredientes disponibles.

    Información del usuario:
    - Edad: #{age}
    - Género: #{gender}
    - Peso: #{weight}
    - Altura: #{height}
    - Nivel de actividad: #{activity}
    - Restricciones alimentarias: #{restrictions}
    - Momento del día: #{time_of_day}

    Tu tarea:
    - Sugiere una receta apropiada para el momento del día y usando los ingredientes que el usuario te dará, no utilices ingredientes que el usuario no especifique.
    - Considera sus datos y restricciones al elegir los ingredientes y métodos de cocción.
    - Da las instrucciones paso a paso en formato Markdown.
    - Si el plato no es adecuado para las restricciones del usuario, ofrece una alternativa más segura o saludable.
  PROMPT
end
end
