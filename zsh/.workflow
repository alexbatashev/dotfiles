function awf() {
    cd ~/Projects/athena_workspace
    tmux new-session -d -n 'edit' vim
    tmux split-window -h -p 20
    tmux new-window -n 'test'
    tmux new-window -n 'docker'
    tmux -2 attach-session -d
}
