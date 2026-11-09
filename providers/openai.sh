# providers/openai.sh: the part that actually talks to the AI service.
# Works with any service that copies OpenAI's way of talking (Ollama, OpenAI, OpenRouter, llama.cpp...).
#
# Every provider file must have one function, llm. It sends the conversation so far ($HIST)
# and the list of tools ($TOOLS) to the AI, and prints the AI's reply.
# For a service that works differently, copy this file, change llm, and pick it with PROVIDER=name.

llm() {
  # Package the model name, the whole conversation and the tool list into one request.
  jq -sc --arg m "${MODEL:-qwen3.5:9b}" --argjson t "$TOOLS" '{model:$m, messages:., tools:$t}' "$HIST" |
  # Send it to the AI service.
  curl -sS "${BASE_URL:-http://localhost:11434/v1}/chat/completions" \
    -H "Authorization: Bearer ${API_KEY:-}" -H 'Content-Type: application/json' -d @- |
  # Pull out the AI's reply. If there isn't one, the service sent an error: show it and fail.
  jq -ce '.choices[0].message // error("API error: \(tojson)")'
}
