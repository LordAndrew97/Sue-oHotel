[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$contentPath = Join-Path $projectRoot 'content\productos.json'
$data = Get-Content -Raw -LiteralPath $contentPath -Encoding UTF8 | ConvertFrom-Json
$destinationRoot = Join-Path $projectRoot 'assets\productos'
$client = New-Object System.Net.WebClient
$client.Headers.Add('User-Agent', 'Mozilla/5.0')
$downloaded = 0
$reused = 0

try {
  foreach ($product in $data.products) {
    $productDirectory = Join-Path $destinationRoot $product.slug
    [System.IO.Directory]::CreateDirectory($productDirectory) | Out-Null
    foreach ($imageUrl in $product.images) {
      $fileName = [System.IO.Path]::GetFileName(([Uri]$imageUrl).AbsolutePath)
      $destination = Join-Path $productDirectory $fileName
      if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        $reused++
        continue
      }
      $client.DownloadFile($imageUrl, $destination)
      $downloaded++
    }
  }
}
finally {
  $client.Dispose()
}

Write-Output "PRODUCTS=$($data.products.Count) DOWNLOADED=$downloaded REUSED=$reused TOTAL=$($downloaded + $reused)"
