#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
