return {
  vaults = {
      {
        name = 'Codice',
        path = ([[{{ joinPath .VaultsDir "Codice" }}]]):gsub('\\', '/'),
      },
{{- if eq .chezmoi.hostname .work_host }}
      {
        name = 'Meta Work',
        path = ([[{{ joinPath .VaultsDir "Meta_Work" }}]]):gsub('\\', '/'),
      },
{{- end }}
      {
        name = 'Splunk Cloud Support',
        path = ([[{{ joinPath .VaultsDir "Splunk_Cloud_Support" }}]]):gsub('\\', '/'),
      },
    }
}
