## llama_leap API tests
## Ensure that ollama is running!

import llama_leap, std/[unittest, json, options, strutils]

const TestModel = "llama2"

suite "llama_leap":
  var ollama: OllamaAPI

  setup:
    ollama = newOllamaAPI()
  teardown:
    ollama.close()

  suite "pull":
    test "pull model":
      ollama.pullModel(TestModel)

  suite "list":
    test "list model tags":
      let resp = ollama.listModels()
      var resultStr = ""
      for model in resp.models:
        resultStr.add(model.name & " ")
      echo "> " & resultStr.strip()

  suite "generate":

    test "load llama2":
      ollama.loadModel(TestModel)

    test "simple /api/generate":
      echo "> " & ollama.generate(TestModel, "How are you today?")

    test "typed /api/generate":
      let req = GenerateReq(
        model: TestModel,
        prompt: "How are you today?",
        options: option(ModelParameters(
          temperature: option(0.0f),
          seed: option(42)
        )),
        system: option("Please talk like a pirate. You are Longbeard the llama.")
      )
      let resp = ollama.generate(req)
      echo "> " & resp.response.strip()

    test "json /api/generate":
      let req = %*{
        "model": TestModel,
        "prompt": "How are you today?",
        "system": "Please talk like a ninja. You are Sneaky the llama.",
        "options": {
          "temperature": 0.0
        }
      }
      let resp = ollama.generate(req)
      echo "> " & resp["response"].getStr.strip()

    test "context":
      let req = GenerateReq(
        model: TestModel,
        prompt: "How are you today?",
        system: option("Please talk like a pirate. You are Longbeard the llama."),
        options: option(ModelParameters(
          temperature: option(0.0f),
          seed: option(42)
        )),
      )
      let resp = ollama.generate(req)
      echo "1> " & resp.response.strip()

      let req2 = GenerateReq(
        model: TestModel,
        prompt: "How are you today?",
        context: option(resp.context),
        options: option(ModelParameters(
          temperature: option(0.0f),
          seed: option(42)
        )),
      )
      let resp2 = ollama.generate(req2)
      echo "2> " & resp2.response.strip()

  suite "chat":
    test "simple /api/chat":
      let messages = @[
        "How are you today?",
        "I'm doing well, how are you?",
        "I'm doing well, thanks for asking.",
      ]
      echo "> " & ollama.chat(TestModel, messages)

    test "typed /api/chat":
      let req = ChatReq(
        model: TestModel,
        messages: @[
          ChatMessage(
            role: "system",
            content: "Please talk like a pirate. You are Longbeard the llama."
        ),
        ChatMessage(
          role: "user",
          content: "How are you today?"
        ),
      ],
        options: option(ModelParameters(
          temperature: option(0.0f),
          seed: option(42)
        ))
      )
      let resp = ollama.chat(req)
      echo "> " & resp.message.content.strip()
  suite "create":
    let testModelName = "test-pirate-llama2"
    test "create specifying modelfile":
      let modelfile = """
FROM llama2
PARAMETER temperature 0
PARAMETER num_ctx 4096

SYSTEM Please talk like a pirate. You are Longbeard the llama.
"""
      ollama.createModel(testModelName, modelfile)
    test "use our created modelfile":
      echo "> " & ollama.generate(testModelName, "How are you today?")

  suite "embeddings":
    test "generate embeddings":
      let resp = ollama.generateEmbeddings(TestModel, "How are you today?")
      echo "Embedding Length: " & $resp.embedding.len
