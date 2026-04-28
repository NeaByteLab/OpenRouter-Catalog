#!/bin/bash

set -euo pipefail

updateTime="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
readmeFile="${repoRoot}/README.md"

python3 - <<'PY' "${readmeFile}" "${updateTime}"
import json
import sys
import urllib.request

readmeFile = sys.argv[1]
updateTime = sys.argv[2]
apiUrl = 'https://openrouter.ai/api/frontend/models'

with urllib.request.urlopen(apiUrl, timeout=30) as httpResponse:
  apiData = json.loads(httpResponse.read().decode())

modelList = apiData.get('data', [])
tableRows = []
for modelData in modelList:
  modelSlug = modelData.get('slug', '')
  modelName = modelData.get('name', modelSlug)
  contextLength = modelData.get('context_length', 0)
  modifiedAt = modelData.get('updated_at', '')
  capList = []
  inputMods = modelData.get('input_modalities', [])
  if 'text' in inputMods:
    capList.append('text')
  if 'image' in inputMods:
    capList.append('vision')
  if 'audio' in inputMods:
    capList.append('audio')
  if 'video' in inputMods:
    capList.append('video')
  outputMods = modelData.get('output_modalities', [])
  if 'image' in outputMods:
    capList.append('image-gen')
  if 'video' in outputMods:
    capList.append('video-gen')
  if modelData.get('supports_reasoning', False):
    capList.append('reasoning')
  if modelData.get('supports_tool_parameters', False):
    capList.append('tools')
  if contextLength:
    sizeText = f'{contextLength:,} tokens'
  else:
    sizeText = '-'
  if capList:
    capText = ', '.join(capList)
  else:
    capText = '(none)'
  modelLink = f'https://openrouter.ai/models/{modelSlug}'
  tableRows.append((modelSlug, sizeText, modifiedAt, capText, modelLink))
tableRows.sort(key=lambda rowItem: (rowItem[2] or '', rowItem[0].lower()), reverse=True)
readmeLines = [
  '# OpenRouter Catalog',
  '',
  'Fetch cloud models, inspect capabilities, publish clickable table automatically.',
  '',
  f'## Available Cloud Models ({len(modelList)})',
  '',
  '| model name | context | modified at | capability tags | official link |',
  '| --- | --- | --- | --- | --- |'
]
for modelSlug, sizeText, modifiedAt, capText, modelLink in tableRows:
  readmeLines.append(
    f'| `{modelSlug}` | `{sizeText}` | `{modifiedAt}` | `{capText}` | [Open]({modelLink}) |'
  )
readmeLines.extend([
  '',
  '## License',
  '',
  'This project is licensed under the MIT license. See the [LICENSE](LICENSE) file for more info.',
  ''
])

with open(readmeFile, 'w', encoding='utf-8') as fileHandle:
  fileHandle.write('\n'.join(readmeLines))
PY

git add "${readmeFile}"
git config --local user.name "NeaByteLab"
git config --local user.email "209737579+NeaByteLab@users.noreply.github.com"
if git diff --cached --quiet; then
  echo "No README changes to commit"
else
  git commit -m "chore(bot): update cloud model catalog at ${updateTime} 🤖"
fi
