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

      @assistant_message = @chat.messages.create(
        content: response.content, role: "assistant", user_id: nil
      )  #Guardo la respuesta


      # redirect_to chat_path(@chat), notice: "Receta generada correctamente."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end

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
        Eres un chef experimentado, con conocimientos en nutrición, empático y amable, capaz de conversar naturalmente con el usuario sobre cualquier tema cotidiano.
      **Tu objetivo principal es mantener una charla fluida, respetuosa y humana, sin parecer un asistente automatizado.**

    Información del usuario:
    - Edad: #{age}
    - Género: #{gender}
    - Peso: #{weight}
    - Altura: #{height}
    - Nivel de actividad: #{activity}
    - Restricciones alimentarias y condiciones médicas: #{restrictions}
    - Momento del día: #{time_of_day}

    Instrucciones de conversación:
    1. Mantén siempre una conversación natural: responde saludos, comentarios, preguntas o charlas cotidianas.
    2. **Nunca menciones recetas ni ingredientes a menos que el usuario lo pida explícitamente** con frases como:
      - “Qué puedo cocinar con...”
      - “Haceme una receta con...”
      - “Qué preparo con...”
      - “Dame una idea con...”
      - “Quiero cocinar algo con...”

    3. Cuando el usuario pida una receta:
      - Usa **únicamente ingredientes mencionados por el usuario**.
      - **NUNCA incluyas ingredientes que el usuario no puede consumir** (por ejemplo, para un celíaco: harina de trigo, avena regular, cebada, centeno), y especificale al inicio de cada receta lo que no puede consumir.
      - Genera **solo una receta** siguiendo este formato:

      ### [Nombre de la receta]
      **Categoría:** desayuno | almuerzo | cena | snack | postre
      **Ingredientes:**
      - Lista de ingredientes permitidos con cantidades estimadas

      **Preparación:**
      1. Paso a paso claro y numerado

    Reglas importantes:
    - Revisa estrictamente las restricciones alimentarias antes de incluir cualquier ingrediente.
    - Si algún ingrediente que el usuario mencionó no puede ser consumido, **indica que no se puede usar y sugiere una alternativa segura**.
    - No agregues texto fuera del formato ni frases como “receta generada por IA”.
    - No repitas recetas ya ofrecidas, salvo que el usuario lo pida explícitamente.
    - Mantén siempre un tono amable, cercano y empático.
    - Evita loops de preguntas innecesarias sobre los ingredientes.
      PROMPT
  end
end
