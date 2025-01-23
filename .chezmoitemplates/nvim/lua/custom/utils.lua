return {
  vaults = {
      {
        name = 'Codice',
        path = ([[{{ joinPath .DocumentsDir "Codice" }}]]):gsub('\\', '/'),
      },
{{- if eq .chezmoi.hostname .work_host }}
      {
        name = 'Meta Work',
        path = ([[{{ joinPath .DocumentsDir "Meta_Work" }}]]):gsub('\\', '/'),
      },
{{- end }}
      {
        name = 'Splunk Cloud Support',
        path = ([[{{ joinPath .DocumentsDir "Splunk_Cloud_Support" }}]]):gsub('\\', '/'),
      },
    }
}
