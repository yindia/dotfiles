all: sync

sync:
	brew bundle
	git clone git@github.com:ahmetb/kubectl-aliases.git ~/.kubectl_aliases
	bash tools.sh
	mkdir -p ~/.config/alacritty
	mkdir -p ~/.tmux/

	[ -f ~/.config/alacritty/alacritty.yml ] || ln -s $(PWD)/alacritty.yml ~/.config/alacritty/alacritty.yml
	[ -f ~/.config/alacritty/color.yml ] || ln -s $(PWD)/color.yml ~/.config/alacritty/color.yml
	[ -f ~/.vimrc ] || ln -s $(PWD)/vimrc ~/.vimrc
	[ -f ~/.tmux.conf ] || ln -s $(PWD)/tmuxconf ~/.tmux.conf
	[ -f ~/.tmux/tmux-dark.conf ] || ln -s $(PWD)/tmux-dark.conf ~/.tmux/tmux-dark.conf
	[ -f ~/.tmux/tmux-light.conf ] || ln -s $(PWD)/tmux-light.conf ~/.tmux/tmux-light.conf
	[ -f ~/.tigrc ] || ln -s $(PWD)/tigrc ~/.tigrc
	[ -f ~/.gitconfig ] || ln -s $(PWD)/gitconfig ~/.gitconfig
	[ -f ~/.agignore ] || ln -s $(PWD)/agignore ~/.agignore
	[ -f ~/workspace/evalsocket ] || ln -s $(PWD)/Tiltfile ~/workspace/evalsocket
	[ -f ~/workspace/flyteorg ] || ln -s $(PWD)/Tiltfile ~/workspace/flyteorg
	[ -f ~/Library/LaunchAgents/io.evalsocket.dark-mode-notify.plist ] || ln -s $(PWD)/io.evalsocket.dark-mode-notify.plist ~/Library/LaunchAgents/io.evalsocket.dark-mode-notify.plist

	# don't show last login message
	touch ~/.hushlogin


clean:
	rm -f ~/.vimrc 
	rm -f ~/.config/alacritty/alacritty.yml
	rm -f ~/.config/alacritty/color.yml
	rm -f ~/.config/fish/config.fish
	rm -f ~/.config/fish/functions/
	rm -f ~/.tmux.conf
	rm -f ~/.tigrc
	rm -f ~/.gitconfig
	rm -f ~/.agignore
	rm -f ~/.agignore
	rm -f ~/Library/LaunchAgents/io.evalsocket.dark-mode-notify.plist

.PHONY: all clean sync 
