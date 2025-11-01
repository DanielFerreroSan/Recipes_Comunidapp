class MessagesController < ApplicationController
  before_action :set_chat

  def create
    @message = @chat.messages.build(message_params) #Acá va el mensaje del User
    @message.user = current_user
    @message.role = "user"

    if @message.save
        ruby_llm_chat = RubyLLM.chat

        messages_history = @chat.messages.map do |m|    #con este método mantengo un historial de conversaciones
        { role: m.role, content: m.content }
        end

        response = ruby_llm_chat.with_instructions(user_prompt(current_user)).ask(messages_history + [{ role: "user", content: "Tengo estos ingredientes: #{@message.content}" }])  #acá agrego el user prompt definido en el método privado



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
      Eres un chef experimentado y amable, capaz de conversar naturalmente con el usuario sobre cualquier tema cotidiano, además de crear recetas saludables cuando sea necesario.

      Información del usuario:
      - Edad: #{age}
      - Género: #{gender}
      - Peso: #{weight}
      - Altura: #{height}
      - Nivel de actividad: #{activity}
      - Restricciones alimentarias: #{restrictions}
      - Momento del día: #{time_of_day}

      Tu tarea:
          - Conversa de forma natural, amable y fluida.
            Puedes responder saludos, comentarios, preguntas o charlas cotidianas.
           *No menciones recetas, cocina ni ingredientes a menos que el usuario lo haga.*

          - Si el usuario **sí menciona ingredientes**, crea automáticamente **solo una** receta adecuada para el momento del día, usando **solo esos ingredientes**
          - *Ten siempre en cuenta sus restricciones alimenticias y por mas que te proporcione ingredientes que no son aptos para él, no se los incluyas*.

        - **Cuando hagas una receta, empieza siempre con un título en formato:**
          `### [Nombre de la receta]`
        - Luego sigue este formato exacto:

          **Categoría:** desayuno | almuerzo | cena | snack | postre
          **Ingredientes:**
          - Lista de ingredientes con cantidades estimadas

          **Preparación:**
          1. Paso a paso claro y numerado


        - Da las instrucciones paso a paso en formato Markdown.
        -
        - No incluyas texto fuera de este formato ni menciones “receta generada” o similares.
              PROMPT
  end
end
