{{/*
flink cluster namespace name, if not set, use chart name as the namespace name
*/}}
{{ define "flink.namespace" }}
{{- default .Chart.Name .Values.namespace.name -}}
{{ end }}
{{/*
Expand the name of the chart.
*/}}
{{ define "flink.name" }}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" -}}
{{ end }}
{{/*
flink cluster configmap name
*/}}
{{ define "flink.configmap" }}
{{- print (default ( include "flink.name" . ) .Values.flinkConf.name) "-conf" -}}
{{ end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{ define "flink.chart" }}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{ end }}
{{/*
Selector labels
*/}}
{{ define "flink.selectorLabels" }}
app.kubernetes.io/name: {{ include "flink.name" . }}
app.kubernetes.io/instance: {{ .Release.Name -}}
{{ end }}
{{/*
Common labels
*/}}
{{ define "flink.labels" }}
helm.sh/chart: {{ include "flink.chart" . }}
{{- include "flink.selectorLabels" . -}}
{{ if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote -}}
{{ end }}
app.kubernetes.io/managed-by: {{ .Release.Service -}}
{{ end }}
{{/*
service account name used by jobmanager and taskmanager
*/}}
{{ define "flink.serviceAccount" }}
{{- default (print .Chart.Name "-service-account") .Values.serviceAccount.name -}}
{{ end }}
{{/*
cluster role owned by flink account
*/}}
{{ define "flink.clusterRole" }}
{{- default "admin" .Values.serviceAccount.clusterRole -}}
{{ end }}
{{/*
jobmanager name
*/}}
{{ define "flink.jobmanager" }}
{{- default "flink-jobmanager" .Values.jobmanager.name -}}
{{ end }}
{{/*
jobmanager service name
*/}}
{{ define "flink.jobmanager.service" }}
{{- default (include "flink.jobmanager" .) .Values.jobmanager.serviceName -}}
{{ end }}
{{/*
task manager name
*/}}
{{ define "flink.taskmanager" }}
{{- default "flink-taskmanager" .Values.taskmanager.name -}}
{{ end }}
{{/*
taskmanager service name
*/}}
{{ define "flink.taskmanager.service" }}
{{- default (include "flink.taskmanager" .) .Values.taskmanager.serviceName -}}
{{ end }}
{{/*
kafka secret name
*/}}
{{ define "flink.taskmanager.kafka" }}
{{- include "flink.name" . -}}
{{ end }}
{{/*
cluster id in k8s, preppend namespace prefix avoid same name
*/}}
{{ define "flink.clusterId" }}
{{- print (include "flink.namespace" .) "-" (default .Release.Name .Values.ha.clusterId) -}}
{{ end }}