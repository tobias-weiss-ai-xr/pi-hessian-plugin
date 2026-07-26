#!/usr/bin/env bash
set -euo pipefail

# Hessian.AI Plugin Showcase Mode
# Demonstrates pi's capabilities with Hessian.AI models

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ASCII art for showcase
ASCII_ART="
${CYAN}
  _   _   _   _   _   _   _   _
 / \ / \ / \ / \ / \ / \ / \ / \
( H | E | S | S | I | A | N | . | A | I )
 \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/
${NC}

${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}
${MAGENTA}║       Hessian.AI Plugin - Showcase Mode              ║${NC}
${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}

This showcase demonstrates the Hessian.AI plugin capabilities
by generating creative content with pi and Hessian.AI models.

Usage: $0 [OPTIONS] [COMMAND]

Commands:
${CYAN}  ascii${NC}           Generate ASCII art
${CYAN}  story${NC}           Generate a mini text adventure story
${CYAN}  riddle${NC}          Generate a programming riddle
${CYAN}  joke${NC}            Generate a programming joke
${CYAN}  wisdom${NC}          Generate wise advice
${CYAN}  custom PROMPT${NC}   Send a custom prompt to pi

Options:
${CYAN}  -m, --model MODEL${NC}    Use specific Hessian.AI model
${CYAN}  -p, --profile NAME${NC}   Use profile: production, development, budget
${CYAN}  -n, --no-api${NC}        Use only built-in content (no API calls)
${CYAN}  -h, --help${NC}          Show this help message

Examples:
  $0 ascii
  $0 story
  HESSIAN_API_KEY=your_key $0 custom \"Write a poem about coding\"
  $0 -m tud/qwen3.6-35b-a3b story

Note:
  - With HESSIAN_API_KEY set, pi will use real Hessian.AI models
  - Without API key, built-in content is used for some commands
"

# Built-in content for fallback
BUILTIN_ASCII="
${CYAN}
    /\\\
   /   \\\
  /     \\\
 /_______\\\
  |     |
  |_____|
   /   \\
  /     \\\
 /_______\\\
   ||
   ||
  /  \\
 /    \\\
/______\\\
 ~~~~~
${NC}
Hessian.AI
"

BUILTIN_JOKES=(
  "Why do programmers prefer dark mode? Because light attracts bugs!"
  "Why did the developer go broke? Because he used up all his cache."
  "I would tell you a UDP joke, but you might not get it."
  "There are only 10 types of people in the world: those who understand binary and those who don't."
  "A SQL query walks into a bar, walks up to two tables and asks, 'Can I join you?'"
  "Why do Java developers wear glasses? Because they can't C#."
  "Why was the JavaScript developer sad? Because he didn't Node how to Express himself."
  "What's a programmer's favorite hangout place? The Foo Bar."
)

BUILTIN_WISDOM=(
  "Code is read more often than it is written. - Guido van Rossum"
  "First, solve the problem. Then, write the code. - John Johnson"
  "Simplicity is the soul of efficiency. - Austin Freeman"
  "The best code is no code at all. - Jeff Atwood"
  "Debugging is twice as hard as writing the code in the first place. - Brian Kernighan"
  "The only way to go fast is to go well. - Robert C. Martin"
  "Make it work, make it right, make it fast. - Kent Beck"
  "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. - Martin Fowler"
)

BUILTIN_STORIES=(
  "You find yourself in a vast digital landscape. Before you stretch countless paths of logic, each leading to unknown destinations. A faint glow in the distance suggests a solution awaits. What do you do?"
  "The terminal screen flickers as you type the final command. Suddenly, the system responds with an unexpected prompt. This is not in the documentation. Your heart races as you realize you've discovered something new..."
  "Deep in the codebase, you find a comment that says 'DO NOT TOUCH'. Of course, you're curious. As you examine the surrounding code, you notice something strange - it seems to be watching you back."
)

BUILTIN_RIDDLES=(
  "I speak without a mouth and hear without ears. I have no body, but I come alive with thewind. What am I? (Answer: A computer fan)"
  "What has to be broken before you can use it? (Answer: A code build)"
  "I'm always in front of you but can never be seen. What am I? (Answer: The future of technology)"
  "What gets shorter as it grows older? (Answer: A software deadline)"
)

#Main functions
show_help() {
  echo -e "$ASCII_ART"
}

check_pi_available() {
  if command -v pi &> /dev/null; then
    return 0
  fi
  return 1
}

check_api_key() {
  [[ -n "${HESSIAN_API_KEY:-}" ]]
}

use_pi_with_model() {
  local prompt="$1"
  local model="$2"
  
  if [[ -n "$model" ]]; then
    export HESSIAN_MODEL="$model"
  fi
  
  echo "$prompt" | pi 2>&1 || echo ""
}

generate_ascii() {
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Generating ASCII art"
    echo -e "${BLUE}  →${NC} Using pi with Hessian.AI..."
    echo -e "${BLUE}  →${NC} Prompting pi for custom ASCII art..."
    
    local art=$(use_pi_with_model "Create a beautiful ASCII art representation of Hessian.AI or TUD. Make it creative and visually appealing.")
    
    if [[ -n "$art" ]] && ! echo "$art" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${CYAN}────────────────────────────────────────────────────────${NC}"
      echo -e "$art"
      echo -e "${CYAN}────────────────────────────────────────────────────────${NC}\n"
      echo -e "${GREEN}  ✓${NC} ASCII art by pi + Hessian.AI! 🎨"
      return
    fi
    
    echo -e "${YELLOW}  ⚠${NC} pi generation returned empty, using built-in art"
  fi
  
  echo -e "${YELLOW}[Step 1]${NC} Showing built-in ASCII art"
  echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
  echo -e "$BUILTIN_ASCII"
  echo -e "${CYAN}────────────────────────────────────────────────────────${NC}\n"
  echo -e "${GREEN}  ✓${NC} Hessian.AI! 🎨"
}

generate_joke() {
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Generating programming joke"
    echo -e "${BLUE}  →${NC} Using pi with Hessian.AI models..."
    
    local joke=$(use_pi_with_model "Tell me a short, funny programming joke. Keep it to one line.")
    
    if [[ -n "$joke" ]] && ! echo "$joke" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${GREEN}  ✓${NC} Joke by pi + Hessian.AI! 😄"
      echo -e "\n${CYAN}$joke${NC}\n"
      return
    fi
    
    echo -e "${YELLOW}  ⚠${NC} pi generation returned empty"
  fi
  
  echo -e "${YELLOW}[Step 1]${NC} Random built-in joke"
  local random_idx=$((RANDOM % ${#BUILTIN_JOKES[@]}))
  echo -e "\n${CYAN}${BUILTIN_JOKES[$random_idx]}${NC}\n"
  echo -e "${GREEN}  ✓${NC} Programming laughter! 😄"
}

generate_wisdom() {
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Generating wise advice"
    echo -e "${BLUE}  →${NC} Using pi with Hessian.AI models..."
    
    local advice=$(use_pi_with_model "Give me a short, wise piece of advice for programmers. One sentence only.")
    
    if [[ -n "$advice" ]] && ! echo "$advice" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${CYAN}\"$advice\"${NC}"
      echo -e "\n${GREEN}  ✓${NC} Wisdom from pi + Hessian.AI! 🧠"
      return
    fi
    
    echo -e "${YELLOW}  ⚠${NC} pi generation returned empty"
  fi
  
  echo -e "${YELLOW}[Step 1]${NC} Random built-in wisdom"
  local random_idx=$((RANDOM % ${#BUILTIN_WISDOM[@]}))
  echo -e "\n${CYAN}\"${BUILTIN_WISDOM[$random_idx]}\"${NC}\n"
  echo -e "${GREEN}  ✓${NC} Programming wisdom! 🧠"
}

generate_story() {
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Generating story"
    echo -e "${BLUE}  →${NC} Using pi with Hessian.AI models..."
    
    local story=$(use_pi_with_model "Write a short, engaging text adventure story intro (3-4 sentences) with a programming theme. End with a question for the reader.")
    
    if [[ -n "$story" ]] && ! echo "$story" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${story}\n"
      echo -e "${GREEN}  ✓${NC} Story by pi + Hessian.AI! 📖"
      return
    fi
    
    echo -e "${YELLOW}  ⚠${NC} pi generation returned empty"
  fi
  
  echo -e "${YELLOW}[Step 1]${NC} Random built-in story"
  local random_idx=$((RANDOM % ${#BUILTIN_STORIES[@]}))
  echo -e "\n${BUILTIN_STORIES[$random_idx]}\n"
  echo -e "${GREEN}  ✓${NC} Programming adventure! 📖"
}

generate_riddle() {
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Generating riddle"
    echo -e "${BLUE}  →${NC} Using pi with Hessian.AI models..."
    
    local riddle=$(use_pi_with_model "Create a short programming-themed riddle. Include the answer after 'Answer:' on the next line.")
    
    if [[ -n "$riddle" ]] && ! echo "$riddle" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${riddle}\n"
      echo -e "${GREEN}  ✓${NC} Riddle by pi + Hessian.AI! 🤔"
      return
    fi
    
    echo -e "${YELLOW}  ⚠${NC} pi generation returned empty"
  fi
  
  echo -e "${YELLOW}[Step 1]${NC} Random built-in riddle"
  local random_idx=$((RANDOM % ${#BUILTIN_RIDDLES[@]}))
  echo -e "\n${BUILTIN_RIDDLES[$random_idx]}\n"
  echo -e "${GREEN}  ✓${NC} Programming puzzle! 🤔"
}

generate_custom() {
  if [[ $# -lt 1 ]]; then
    echo -e "${RED}[ERROR]${NC} Custom prompt requires an argument"
    echo "Usage: $0 custom \"Your prompt here\""
    exit 1
  fi
  
  local prompt="$*"
  
  if check_api_key && check_pi_available && [[ "$NO_API" != "true" ]]; then
    echo -e "${YELLOW}[Step 1]${NC} Sending custom prompt to pi"
    echo -e "${BLUE}  →${NC} Using Hessian.AI models..."
    echo -e "${BLUE}  →${NC} Prompt: $prompt"
    
    local response=$(use_pi_with_model "$prompt")
    
    if [[ -n "$response" ]] && ! echo "$response" | grep -qi "error|sorry|cannot"; then
      echo -e "\n${CYAN}────────────────────────────────────────────────────────${NC}"
      echo -e "$response"
      echo -e "${CYAN}────────────────────────────────────────────────────────${NC}\n"
      echo -e "${GREEN}  ✓${NC} Response by pi + Hessian.AI! ✨"
      return
    fi
    
    echo -e "${RED}  ✗${NC} Failed to generate response: pi returned empty or error"
    exit 1
  fi
  
  echo -e "${RED}[ERROR]${NC} Custom prompt requires HESSIAN_API_KEY and pi"
  echo -e "${RED}[ERROR]${NC} Set HESSIAN_API_KEY environment variable"
  exit 1
}

# Parse arguments
NO_API=false
MODEL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -p|--profile)
            export HESSIAN_PROFILE="$2"
            shift 2
            ;;
        -n|--no-api)
            NO_API=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        ascii|story|riddle|joke|wisdom)
            COMMAND="$1"
            shift
            ;;
        custom)
            COMMAND="custom"
            shift
            ;;
        *)
            if [[ -n "$COMMAND" && "$COMMAND" == "custom" ]]; then
                ARGS+=("$1")
            else
                echo -e "${RED}[ERROR]${NC} Unknown argument: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate command
if [[ -z "$COMMAND" ]]; then
    show_help
    exit 0
fi

# Main header
echo -e "$ASCII_ART"

# Execute command
case "$COMMAND" in
    ascii)
        generate_ascii
        ;;
    story)
        generate_story
        ;;
    riddle)
        generate_riddle
        ;;
    joke)
        generate_joke
        ;;
    wisdom)
        generate_wisdom
        ;;
    custom)
        generate_custom "${ARGS[@]:-}"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

echo -e "\n${MAGENTA}────────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}  ✓${NC} Showcase complete!"
echo -e "${MAGENTA}────────────────────────────────────────────────────────${NC}"
