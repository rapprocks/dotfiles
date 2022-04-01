# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/philip/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"

#Aliases
alias sshdock="ssh -i ~/.ssh/dockertown hieronymus@dock.home.lan"
alias sshnas="ssh -i ~/.ssh/nas hieronymus@nas.home.lan"
#alias sshdock="ssh -i ~/.ssh/dockertown hieronymus@192.168.2.213"
alias sshrah="ssh -i ~/.ssh/hetzner hieronymus@rah.yeet.nu"