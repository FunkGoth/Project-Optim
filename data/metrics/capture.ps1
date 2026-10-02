# metrics\capture.ps1 — anlık sistem ölçümü (1 satır JSON)
# Kullanım: powershell -NoProfile -ExecutionPolicy Bypass -File E:/agent/metrics/capture.ps1
# Not: Win32_OperatingSystem alanları KB cinsindir → /1MB bölerek GB'e çevir (ders: /1GB ile bölmek 0.01 verir).
$ErrorActionPreference = 'Continue'
$os  = Get-CimInstance Win32_OperatingSystem
$m   = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$pf  = Get-CimInstance Win32_PerfFormattedData_PerfOS_PagingFile -Filter "Name='_Total'"
$out = [ordered]@{
  ts              = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')
  ram_free_gb     = [math]::Round($os.FreePhysicalMemory/1MB, 2)
  ram_total_gb    = [math]::Round($os.TotalVisibleMemorySize/1MB, 1)
  ram_avail_gb    = [math]::Round($m.AvailableMBytes/1024, 2)
  ram_commit_gb   = [math]::Round($m.CommittedBytes/1GB, 2)
  commit_limit_gb = [math]::Round($m.CommitLimit/1GB, 1)
  paging_mb       = [math]::Round($pf.CurrentUsage/1MB, 0)
  paging_peak_mb  = [math]::Round($pf.Peak/1MB, 0)
}
try {
  $line = (nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits) -replace '\s+', ' '
  $p = $line -split ','
  $out.gpu_ded_mb   = [int]$p[0].Trim()
  $out.gpu_total_mb = [int]$p[1].Trim()
  $out.gpu_util_pct = [int]$p[2].Trim()
} catch { $out.gpu = 'nvidia-smi FAIL' }
try {
  $c = (Get-Counter -Counter "\GPU Process Memory(*)\Shared Usage" -SampleInterval 1 -MaxSamples 1).CounterSamples
  $out.gpu_shared_mb = [math]::Round(($c | Measure-Object CookedValue -Sum).Sum/1MB, 1)
} catch { $out.gpu_shared = 'counter FAIL' }
$out | ConvertTo-Json -Compress
