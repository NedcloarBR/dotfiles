#!/usr/bin/env bash

title="Claude Code"
msg="${1:-}"

[ -z "$msg" ] && exit 0

if command -v notify-send >/dev/null 2>&1; then
  notify-send -t 4000 "$title" "$msg" 2>/dev/null
  exit 0
fi

command -v powershell.exe >/dev/null 2>&1 || exit 0

ps_escape() { printf '%s' "$1" | sed "s/'/''/g"; }

# Toasts need a registered AppUserModelID; reuse PowerShell's own
script="
\$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
\$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
\$text = \$xml.GetElementsByTagName('text')
\$null = \$text.Item(0).AppendChild(\$xml.CreateTextNode('$(ps_escape "$title")'))
\$null = \$text.Item(1).AppendChild(\$xml.CreateTextNode('$(ps_escape "$msg")'))
\$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$appId).Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))
"

(powershell.exe -NoProfile -NonInteractive -Command "$script" >/dev/null 2>&1 &)
exit 0
