{{/*
Expand the name of the chart.
*/}}
{{- define "opc-router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opc-router.fullname" -}}
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

{{- define "opc-router.redundancy.fullname" -}}
{{- include "opc-router.fullname" . | cat "redundant" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opc-router.inray.fullname" -}}
{{- include "opc-router.fullname" . | cat "inray" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opc-router.log.fullname" -}}
{{- include "opc-router.fullname" . | cat "log" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opc-router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opc-router.labels" -}}
helm.sh/chart: {{ include "opc-router.chart" . }}
app.kubernetes.io/name: {{ include "opc-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels of the router workload and its Service. Kubernetes does not allow the selector of
an existing Deployment to change, and chart versions up to 1.0.4 put the chart version into it. A
release that already has its Deployment therefore keeps the selector it was created with; new
releases get labels that stay stable across chart versions. lookup is empty under helm template.
*/}}
{{- define "opc-router.workloadSelectorLabels" -}}
{{- $existing := lookup "apps/v1" "Deployment" .Release.Namespace (include "opc-router.fullname" .) -}}
{{- $matchLabels := dig "spec" "selector" "matchLabels" dict $existing -}}
{{- if $matchLabels -}}
{{- toYaml $matchLabels -}}
{{- else -}}
app.kubernetes.io/name: {{ include "opc-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: router
{{- end -}}
{{- end }}

{{/*
Labels of the router pod: the selector labels, completed by the common labels. Where both name the
same key, the selector's value wins, so a kept selector still matches its pods.
*/}}
{{- define "opc-router.podLabels" -}}
{{- $selector := include "opc-router.workloadSelectorLabels" . | fromYaml -}}
{{- $common := include "opc-router.labels" . | fromYaml -}}
{{- toYaml (merge $selector $common (dict "app.kubernetes.io/component" "router")) -}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opc-router.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
statefulset.kubernetes.io/pod-name: {{ include "opc-router.fullname" . }}
{{- end }}

{{/*
Original selector labels
*/}}
{{- define "opc-router.originalSelectorLabels" -}}
originForRedundency: {{ include "opc-router.redundancy.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "opc-router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opc-router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the connection string for the mongodb(s)
*/}}
{{- define "getMongoDB" }}
{{- $addresses := int .Values.mongodb.replicaCount | until }}
{{- range $addresses -}}
{{- if (ne . 0) -}}
,
{{- end -}}
"mongodb://{{ $.Release.Name }}-mongodb-{{ . }}.{{ $.Release.Name }}-mongodb-headless"
{{- end }}
{{- end }}