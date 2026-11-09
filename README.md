# smolest-agent

The smallest possible AI agent: a few short, commented bash scripts that let a language model
run commands and read and write files. Every part is a separate file you can swap out or extend.

Needs only `bash`, `curl` and `jq`. Works with any OpenAI-compatible chat API: Ollama (the default,
no key needed), OpenAI, OpenRouter, llama.cpp, vLLM and others.

## Quick start

```bash
git clone https://github.com/10-X-eng/smolest-agent && cd smolest-agent
ollama pull qwen3.5:9b               # about 6.5 GB; or any model that supports tool calling

./ask "Say hi"                       # one plain call, no tools
./agent "How many .conf files are in /etc?"   # one task with tools
./agent                              # interactive chat (Ctrl-D quits)
```

The agent shows each step as it happens:

```
▶ tool call: bash
  │ {"command":"find /etc -name '*.conf' | wc -l"}
  run it? [y/N] y
◀ result
  │ 87
◆ answer
  │ There are 87 .conf files in /etc.
```

## Configuration

All settings are environment variables:

| Variable       | Default                      | Meaning                                         |
|----------------|------------------------------|-------------------------------------------------|
| `MODEL`        | `qwen3.5:9b`                 | Model name (small models like 3B ones often guess wrong file names) |
| `BASE_URL`     | `http://localhost:11434/v1`  | API base URL                                    |
| `API_KEY`      | *(empty)*                    | API key, if your provider needs one             |
| `PROVIDER`     | `openai`                     | Which file in `providers/` to use               |
| `SYSTEM`       | tells it the current folder and not to guess file names | System prompt        |
| `YOLO`         | *(unset)*                    | Set to `1` to run tools without asking          |
| `SHOW_LINES`   | `10`                         | Lines of each step shown on screen              |
| `TOOL_TIMEOUT` | `60`                         | Seconds before a `bash` tool command is stopped |

Example with OpenAI:

```bash
BASE_URL=https://api.openai.com/v1 API_KEY=sk-... MODEL=gpt-4o-mini ./agent "..."
```

## How it works

```
agent                 the loop: send history + tools to the model, run any tool calls,
                      add the results to the history, repeat until the model just answers
ask                   the smallest possible call: one prompt in, one answer out
providers/openai.sh   defines llm(): turns the history into an API request, returns the reply
tools/bash            run a shell command
tools/read_file       read a file
tools/write_file      create or overwrite a file
```

The conversation is kept in a temporary file, one JSON message per line, and deleted on exit.

## Adding a tool

Drop an executable into `tools/`. Its filename is the tool's name. It must:

1. print a JSON description of itself when run with `--schema`
2. otherwise read its arguments as JSON on stdin and print its result

```bash
#!/usr/bin/env bash
# tools/now: tell the model the current date and time
[ "$1" = --schema ] && exec echo '{"description":"Current date and time","parameters":{"type":"object","properties":{}}}'
date
```

Tools can be written in any language. The agent finds them automatically on the next start.

## Adding a provider

Copy `providers/openai.sh` to `providers/<name>.sh` and change `llm()`. It reads the history
file `$HIST` and the tool list `$TOOLS`, and prints the model's reply as an OpenAI-style message.
Select it with `PROVIDER=<name>`.

## Safety

The model can run any shell command and overwrite any file your user can. By default the agent
asks before every tool call, and declines if there is no terminal to ask on. `YOLO=1` turns that
off, so only use it in a sandbox or a throwaway folder.
