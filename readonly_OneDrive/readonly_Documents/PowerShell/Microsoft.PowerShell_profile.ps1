Invoke-Expression (&starship init powershell)

# Keybindings for completion
Set-PSReadLineKeyHandler -Chord "Alt+l" -Function ForwardWord
Set-PSReadLineKeyHandler -Chord "Alt+h" -Function ForwardChar

# Command completions
. C:\Users\leomc\AppData\Local\starship\starship_completions.ps1