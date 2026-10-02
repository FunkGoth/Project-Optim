# top_proc.ps1 — Sistem kaynak dağılımı (ana agent / sub agent / diğer)
# Kullanım: powershell -NoProfile -ExecutionPolicy Bypass -File E:/agent/metrics/top_proc.ps1
$top = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 25 `
  Name, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,0)}}
$os = Get-CimInstance Win32_OperatingSystem
$shared = (Get-Counter -Counter '\GPU Process Memory(*)\Shared Usage' -SampleInterval 1 -MaxSamples 1).CounterSamples |
  Where-Object { $_.CookedValue -gt 0 } |
  ForEach-Object { [PSCustomObject]@{ instance=$_.InstanceName; shared_mb=[math]::Round($_.CookedValue/1MB,1) } }
$out = [PSCustomObject]@{
  ram_total_gb   = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
  ram_free_gb    = [math]::Round($os.FreePhysicalMemory/1MB,1)
  commit_gb      = [math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory).CommittedBytes/1GB,1)
  top_ram_procs  = $top
  gpu_shared_by_pid = $shared
}
$out | ConvertTo-Json -Depth 4 -Compress
