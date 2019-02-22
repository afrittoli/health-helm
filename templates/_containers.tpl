{{- define "health.frontend-container" -}}
image: {{ template "health.frontend.image" . }}
imagePullPolicy: {{ .Values.image.pullPolicy }}
env:
  - name: API_URL
    value: {{ template "health.api.fullurl" . }}
ports:
  - name: http{{ if .Values.knative.enabled }}1{{ end }}
    containerPort: 80
    protocol: TCP
livenessProbe:
  httpGet:
    path: /
{{- if not .Values.knative.enabled }}
    port: http
{{- end }}
readinessProbe:
  httpGet:
    path: /
{{- if not .Values.knative.enabled }}
    port: http
{{- end }}
{{- end -}}

{{- define "health.api-container" -}}
image: {{ template "health.api.image" . }}
imagePullPolicy: {{ .Values.image.pullPolicy }}
env:
  - name: DB_PROTOCOL
    value: {{ if .Values.databaseOverride }}{{ default "postgresql+psycopg2" .Values.databaseOverride.protocol }}{{ else }}"postgresql+psycopg2"{{ end }}
  - name: DB_HOST
    value: {{ template "health.dbname" . }}
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "health.dbsecrets" . }}
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "health.dbsecrets" . }}
        key: password
  - name: DB_NAME
    value: subunit2sql
ports:
  - name: http{{ if .Values.knative.enabled }}1{{ end }}
    containerPort: 80
    protocol: TCP
readinessProbe:
  httpGet:
    path: /status
{{- if not .Values.knative.enabled }}
    port: http
{{- end }}
livenessProbe:
  httpGet:
    path: /status
{{- if not .Values.knative.enabled }}
    port: http
{{- end }}
{{- end -}}
