{{/* Names */}}
{{- define "doexam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "doexam.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* <fullname>-<component> */}}
{{- define "doexam.component" -}}
{{- printf "%s-%s" (include "doexam.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "doexam.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "doexam.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: doexam
{{- end -}}

{{/* selector labels for a component: include "doexam.selector" (dict "root" $ "component" "server") */}}
{{- define "doexam.selector" -}}
app.kubernetes.io/name: {{ include "doexam.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{/* the server component: "aio" or "server" */}}
{{- define "doexam.serverComponent" -}}
{{- if eq .Values.mode "aio" -}}aio{{- else -}}server{{- end -}}
{{- end -}}

{{- define "doexam.serverName" -}}
{{- include "doexam.component" (dict "root" . "component" (include "doexam.serverComponent" .)) -}}
{{- end -}}

{{/* image reference: include "doexam.image" (dict "root" $ "image" .Values.image.aio) */}}
{{- define "doexam.image" -}}
{{- $tag := default .root.Chart.AppVersion .root.Values.image.tag -}}
{{- if .root.Values.image.registry -}}
{{- printf "%s/%s:%s" .root.Values.image.registry .image.repository $tag -}}
{{- else -}}
{{- printf "%s:%s" .image.repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "doexam.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "doexam.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Secret names */}}
{{- define "doexam.secretName" -}}{{ include "doexam.fullname" . }}{{- end -}}

{{- define "doexam.databaseSecretName" -}}
{{- if .Values.database.existingSecret -}}{{ .Values.database.existingSecret }}{{- else -}}{{ include "doexam.secretName" . }}{{- end -}}
{{- end -}}
{{- define "doexam.databaseSecretKey" -}}
{{- if .Values.database.existingSecret -}}{{ .Values.database.existingSecretKey }}{{- else -}}database-url{{- end -}}
{{- end -}}

{{- define "doexam.mediaSecretName" -}}
{{- if .Values.mediaSigningKey.existingSecret -}}{{ .Values.mediaSigningKey.existingSecret }}{{- else -}}{{ include "doexam.secretName" . }}{{- end -}}
{{- end -}}
{{- define "doexam.mediaSecretKey" -}}
{{- if .Values.mediaSigningKey.existingSecret -}}{{ .Values.mediaSigningKey.existingSecretKey }}{{- else -}}media-signing-key{{- end -}}
{{- end -}}

{{/* true when a Redis URL reaches the server (built-in, URL or existing Secret) */}}
{{- define "doexam.hasRedis" -}}
{{- if or .Values.redis.enabled .Values.redis.url .Values.redis.existingSecret -}}true{{- end -}}
{{- end -}}

{{/*
A value generated once and kept across upgrades: the existing Secret's key when there
is one (lookup), else a new random value. lookup returns nothing under `helm template`,
so dry runs show a fresh value.
*/}}
{{- define "doexam.persistedSecret" -}}
{{- $existing := lookup "v1" "Secret" .root.Release.Namespace .secret -}}
{{- if and $existing (hasKey $existing.data .key) -}}
{{- index $existing.data .key | b64dec -}}
{{- else -}}
{{- .generate -}}
{{- end -}}
{{- end -}}

{{/* resources: explicit `resources` win over the preset */}}
{{- define "doexam.serverResources" -}}
{{- if .Values.server.resources -}}
{{- toYaml .Values.server.resources -}}
{{- else if eq .Values.server.resourcesPreset "small" -}}
requests: { cpu: 500m, memory: 256Mi }
limits: { cpu: "1", memory: 512Mi }
{{- else if eq .Values.server.resourcesPreset "medium" -}}
requests: { cpu: "1", memory: 512Mi }
limits: { cpu: "2", memory: 1Gi }
{{- else if eq .Values.server.resourcesPreset "large" -}}
requests: { cpu: "2", memory: 1Gi }
limits: { cpu: "4", memory: 2Gi }
{{- end -}}
{{- end -}}

{{/* the server is scaled out (more than one pod at a time) */}}
{{- define "doexam.serverScaled" -}}
{{- if or (gt (int .Values.server.replicas) 1) .Values.server.autoscaling.enabled -}}true{{- end -}}
{{- end -}}
