return {
  vaults = {
{{- if ne .chezmoi.hostname .workHost }}
      {
        name = 'Codice',
        path = ([[{{ joinPath .vaultsDir "Codice" }}]]):gsub('\\', '/'),
      },
{{- end }}
      {
        name = 'Meta Work',
        path = ([[{{ joinPath .vaultsDir "Meta_Work" }}]]):gsub('\\', '/'),
      },
      {
        name = 'Splunk Cloud Support',
        path = ([[{{ joinPath .vaultsDir "Splunk_Cloud_Support" }}]]):gsub('\\', '/'),
      },
    }
}
{{/*
vim: filetype=lua.gotmpl
*/}}
