return {
  vaults = {
      {
        name = 'Codice',
        path = {{ joinPath .DocumentsDir "Codice" | squote }},
      },
{{- if eq .chezmoi.hostname .work_host }}
      {
        name = 'Meta Work',
        path = {{ joinPath .DocumentsDir "Meta_Work" | squote }},
      },
{{- end }}
      {
        name = 'Splunk Cloud Support',
        path = {{ joinPath .DocumentsDir "Splunk_Cloud_Support" | squote }},
      },
    }
}
