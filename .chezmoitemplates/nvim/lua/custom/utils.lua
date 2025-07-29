return {
  vaults = {
{{- if ne .chezmoi.hostname .work_host }}
      {
        name = 'Codice',
        path = ([[{{ joinPath .VaultsDir "Codice" }}]]):gsub('\\', '/'),
      },
{{- end }}
      {
        name = 'Meta Work',
        path = ([[{{ joinPath .VaultsDir "Meta_Work" }}]]):gsub('\\', '/'),
      },
      {
        name = 'Splunk Cloud Support',
        path = ([[{{ joinPath .VaultsDir "Splunk_Cloud_Support" }}]]):gsub('\\', '/'),
      },
    }
}
{{/*
vim: filetype=lua.gotmpl
*/}}
