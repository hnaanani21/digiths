# ============================================================
#  DigitHS — Setup Git + GitHub automatique
#  À exécuter UNE SEULE FOIS dans D:\WebSiteDigitHS
# ============================================================

$ErrorActionPreference = "Stop"
$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $folder

Write-Host "📁 Dossier : $folder" -ForegroundColor Cyan

# 1. Vérifier que git est installé
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git n'est pas installé. Téléchargez-le sur https://git-scm.com" -ForegroundColor Red
    exit 1
}

# 2. Initialiser le repo si besoin
if (-not (Test-Path ".git")) {
    git init
    Write-Host "✅ Git initialisé" -ForegroundColor Green
} else {
    Write-Host "✅ Repo Git déjà présent" -ForegroundColor Green
}

# 3. Configurer l'identité Git (modifiez si besoin)
git config user.name  "Hamza Naanani"
git config user.email "h.naanani@gmail.com"

# 4. Ajouter le remote GitHub (si pas encore fait)
$remote = git remote get-url origin 2>$null
if (-not $remote) {
    git remote add origin https://github.com/hnaanani21/digiths.git
    Write-Host "✅ Remote GitHub configuré" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Remote déjà configuré : $remote" -ForegroundColor Yellow
}

# 5. Créer .gitignore
@"
*.bak
*.tmp
Thumbs.db
.DS_Store
"@ | Set-Content .gitignore -Encoding UTF8

# 6. Premier commit si le repo est vide
$hasCommits = git rev-parse HEAD 2>$null
if (-not $hasCommits) {
    git add -A
    git commit -m "init: premier commit DigitHS"
    Write-Host "✅ Premier commit créé" -ForegroundColor Green
}

# 7. Créer la tâche planifiée Windows (push auto chaque jour à 23h)
$taskName = "DigitHS-AutoPush"
$scriptPath = "$folder\push.ps1"

# Créer le script de push quotidien
@'
# ============================================================
#  DigitHS — Push quotidien automatique vers GitHub Pages
#  Exécuté automatiquement par le Planificateur de tâches
# ============================================================

$folder = "D:\WebSiteDigitHS"
Set-Location $folder

$date = Get-Date -Format "yyyy-MM-dd HH:mm"
$log  = "$folder\push.log"

function Log($msg) {
    "$date  $msg" | Add-Content $log -Encoding UTF8
    Write-Host $msg
}

Log "--- Push automatique démarré ---"

# Vérifier s'il y a des modifications
$status = git status --porcelain
if (-not $status) {
    Log "Aucun changement — push ignoré"
    exit 0
}

# Ajouter tous les fichiers nouveaux/modifiés
git add -A

# Commit avec la date du jour
$commitMsg = "content: mise a jour automatique $date"
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Log "ERREUR : commit échoué (code $LASTEXITCODE)"
    exit 1
}

# Push vers GitHub
git push origin main
if ($LASTEXITCODE -eq 0) {
    Log "✅ Push réussi → https://digiths.ma"
} else {
    Log "❌ Push échoué (code $LASTEXITCODE) — vérifiez votre PAT"
    exit 1
}

Log "--- Fin ---"
'@ | Set-Content $scriptPath -Encoding UTF8

Write-Host "✅ Script push.ps1 créé dans $scriptPath" -ForegroundColor Green

# Supprimer la tâche existante si elle existe
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Créer la nouvelle tâche planifiée
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
           -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
            -RestartCount 2 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $taskName -Action $action `
    -Trigger $trigger -Settings $settings -RunLevel Highest `
    -Description "Push automatique DigitHS → GitHub Pages chaque soir" | Out-Null

Write-Host "✅ Tâche planifiée '$taskName' créée (23h00 chaque soir)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  DERNIÈRE ÉTAPE : configurer votre Token GitHub (PAT)" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Allez sur : https://github.com/settings/tokens/new"
Write-Host "  2. Note      : DigitHS-AutoPush"
Write-Host "  3. Scopes    : cochez [x] repo"
Write-Host "  4. Expiré    : No expiration (ou 1 an)"
Write-Host "  5. Cliquez   : Generate token  → copiez le token (ghp_...)"
Write-Host ""
Write-Host "  Puis exécutez dans PowerShell :"
Write-Host '  git remote set-url origin https://<VOTRE_TOKEN>@github.com/hnaanani21/digiths.git' -ForegroundColor Green
Write-Host ""
Write-Host "  Testez manuellement avec : .\push.ps1"
Write-Host ""
Write-Host "✅ Setup terminé !" -ForegroundColor Green
