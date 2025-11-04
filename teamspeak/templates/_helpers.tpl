{{/*
Expand the name of the chart.
*/}}
{{- define "teamspeak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "teamspeak.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "teamspeak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "teamspeak.labels" -}}
helm.sh/chart: {{ include "teamspeak.chart" . }}
{{ include "teamspeak.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.customer }}
app.kubernetes.io/customer: {{ .Values.customer | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "teamspeak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "teamspeak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "teamspeak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "teamspeak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MariaDB fullname
*/}}
{{- define "teamspeak.mariadb.fullname" -}}
{{- printf "%s-mariadb" (include "teamspeak.fullname" .) -}}
{{- end -}}

{{/*
Check if storageClass is defined and exists
*/}}
{{- define "teamspeak.isStorageClass" -}}
{{- $sc := $.storageClass -}}
{{- $classes := lookup "storage.k8s.io/v1" "StorageClass" "" -}}
{{- if $sc -}}
  {{- range $name, $class := $classes.items -}}
    {{- if eq $name $sc }}
true
    {{- end -}}
  {{- end -}}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{/*
TeamSpeak server configuration
*/}}
{{- define "teamspeak.serverConfig" -}}
server:
  license-path: /var/tsserver
  default-voice-port: {{ .Values.voice.port }}
  voice-ip:
    - 0.0.0.0
    - "::"
  machine-id: ""
  threads-voice-udp: 4
  log-path: /var/tsserver/logs
  log-append: 0
  no-default-virtual-server: 0
  filetransfer-port: {{ .Values.filetransfer.port }}
  filetransfer-ip:
    - 0.0.0.0
    - "::"
  clear-database: 0
  no-permission-update: 0
  http-proxy: ""
  accept-license: {{ ternary "accept" "reject" .Values.licenseAccepted }}
  crashdump-path: /var/tsserver/crashdumps

  database:
    plugin: {{ if .Values.mariadb.enabled }}mariadb{{ else }}sqlite3{{ end }}
    sql-path: /var/tsserver/sql/
    sql-create-path: /var/tsserver/sql/create_{{ if .Values.mariadb.enabled }}mariadb{{ else }}sqlite{{ end }}/
    client-keep-days: 30
    config:
      skip-integrity-check: 0
      host: {{ if .Values.mariadb.enabled }}{{ include "teamspeak.mariadb.fullname" . }}{{ else }}127.0.0.1{{ end }}
      port: {{ if .Values.mariadb.enabled }}3306{{ else }}5432{{ end }}
      socket: ""
      timeout: 10
      name: {{ .Values.mariadb.auth.database | default "teamspeak" }}
      username: {{ if .Values.mariadb.enabled }}{{ .Values.mariadb.auth.username }}{{ else }}""{{ end }}
      password: {{ if .Values.mariadb.enabled }}{{ .Values.mariadb.auth.password }}{{ else }}""{{ end }}
      connections: 10
      log-queries: 0

  query:
    pool-size: 2
    log-timing: 3600
    ip-allow-list: query_ip_allowlist.txt
    ip-block-list: query_ip_denylist.txt
    admin-password: ""
    log-commands: 0
    skip-brute-force-check: 0
    buffer-mb: 20
    documentation-path: serverquerydocs
    timeout: 300

    ssh:
      enable: 0
      port: 10022
      ip:
        - 0.0.0.0
        - "::"
      rsa-key: ssh_host_rsa_key

    http:
      enable: 1
      port: {{ .Values.webquery.port }}
      ip:
        - 0.0.0.0
        - "::"

    https:
      enable: 0
      port: 10443
      ip:
        - 0.0.0.0
        - "::"
      certificate: ""
      private-key: ""
{{- end }}