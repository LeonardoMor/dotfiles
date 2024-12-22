Invoke-Expression (&starship init powershell)

# Keybindings for completion
Set-PSReadLineKeyHandler -Chord "Alt+l" -Function ForwardWord
Set-PSReadLineKeyHandler -Chord "Alt+h" -Function ForwardChar

# Command completions
chezmoi completion powershell | Out-String | Invoke-Expression
starship completions powershell | Out-String | Invoke-Expression