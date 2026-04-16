#!/usr/bin/env bash

PENNYKIT_HOME="${PENNYKIT_HOME:-$HOME/.pennykti}"

mapfile -t configs < <(find "${PENNYKIT_HOME}/nvim-starter" -maxdepth 1 -mindepth 1 -type d )

configs+=("Disable nvim config")

PS3="Enter you choice: "
select i in "${configs[@]}"; do
	if [ -n "$i" ]; then
		# echo "Selected: $i"
		if [[ "$i" =~ ^Disable ]]; then
			if [ -L "$HOME/.config/nvim" ]; then
				if [[ "$(readlink -f "$HOME/.config/nvim")" == *nvim-starter* ]]; then
					unlink "$HOME/.config/nvim"
				fi
			fi
		else
			if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
				break
			elif [ -L "$HOME/.config/nvim" ]; then
				if [[ "$(readlink -f "$HOME/.config/nvim")" == *nvim-starter* ]]; then
					unlink "$HOME/.config/nvim"
					ln -s "$i" "$HOME/.config/nvim"
					rm -rf ~/.local/share/nvim
					rm -rf ~/.local/state/nvim
					rm -rf ~/.cache/nvim
				fi
			else
				ln -s "$i" "$HOME/.config/nvim"
			fi
		fi
		break
	fi
done

