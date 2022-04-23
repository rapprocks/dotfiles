# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/philip/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"

#Aliases
alias sshdock="ssh dock.home.lan"
alias sshnas="ssh nas.home.lan"
alias sshrah="ssh rah.yeet.nu"