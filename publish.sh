#!/usr/bin/env bash
# Automatisches Git-Publish-Script (Codespaces/Linux-Äquivalent zu publish.ps1)
# Ausführen über die Befehlspalette: "Tasks: Run Task" -> "Git: Publish"

set -e
cd "$(git rev-parse --show-toplevel)"

current_branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" != "main" ]; then
	echo "Achtung: aktueller Branch ist '$current_branch', nicht 'main'. Abbruch."
	exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
	echo "Änderungen gefunden. Committe und pushe..."
	git add .
	git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
	git push origin main
	echo "Erfolgreich veröffentlicht!"
else
	echo "Keine Änderungen gefunden."
fi
