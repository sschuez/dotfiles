#!/opt/homebrew/bin/bash

# Ensure tmux server stays warm with a minimal background session
# This significantly speeds up new tmux session creation

# Check if tmux server is running and has the background session
if ! /opt/homebrew/bin/tmux has-session -t _bg 2>/dev/null; then
    # Create a detached background session with minimal footprint
    # Using '_bg' prefix to keep it at bottom of session list
    # Run bash in the background session to keep it alive
    /opt/homebrew/bin/tmux new-session -d -s _bg -n keep-alive '/opt/homebrew/bin/bash'
    
    echo "$(date): Started tmux background session '_bg'"
else
    echo "$(date): Background session '_bg' already exists"
fi